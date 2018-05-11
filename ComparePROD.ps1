
$InformationPreference = "Continue"
$WarningPreference = "Continue"

$Version = " -- Version: 1.9"
$Node = " -- Node: " + $env:COMPUTERNAME
$d = Get-Date
$Datum = " -- Date: " + $d.ToShortDateString()
$Tijd = " -- Time: " + $d.ToShortTimeString()
$Scriptmsg = "PowerShell script " + $MyInvocation.MyCommand.Name + $Version + $Datum + $Tijd +$Node
Write-Information $Scriptmsg 

$ProdList = Get-ChildItem $ADHC_ProdDir -recurse -file | Select FullName,LastWriteTime,Length | Sort-Object Fullname
$StageLIst = Get-ChildItem $ADHC_StagingDir -recurse -file | Select FullName,LastWriteTime,Length | Sort-Object Fullname
$DevLIst = Get-ChildItem $ADHC_DevelopDir -recurse -file  | Select FullName,LastWriteTime,Length | `
Where-Object {($_.FullName -notlike "*.git*") -and `
              ($_.FullName -notlike "*gsdata*") -and `
              ($_.FullName -notlike "*\Sympa\Configman\*")  `
              } | Sort-Object Fullname


New-Item -ItemType Directory -Force -Path $ADHC_ProdCompareDir

$ProdFile = $ADHC_ProdCompareDir + $ADHC_Computer + ".txt"
$StageFile = $ADHC_ProdCompareDir + "NewStage_" + $ADHC_Computer + ".txt"
$DevFile = $ADHC_ProdCompareDir + "NewDev_" + $ADHC_Computer + ".txt"


Set-Content $ProdFile $Scriptmsg -force
foreach ($FileEntry in $ProdList) {
    $array = $FileEntry.FullName -split "\\"
    $comparename = $array[2..($array.Length – 1)] -join "\"
    $FileRecord = $ADHC_Computer + ";" +  $comparename + ";" + $FileEntry.LastWriteTime + ";" + $FileEntry.Length
    Add-Content $ProdFile $FileRecord
}
Set-Content $StageFile $Scriptmsg -force
foreach ($FileEntry in $StageList) {
    $array = $FileEntry.FullName -split "\\"
    $comparename = $array[4..($array.Length – 1)] -join "\"
    $FileRecord = "Staging" + ";" +  $comparename + ";" + $FileEntry.LastWriteTime + ";" + $FileEntry.Length
    Add-Content $StageFile $FileRecord
}
Set-Content $DevFile $Scriptmsg -force
foreach ($FileEntry in $DevList) {
    $array = $FileEntry.FullName -split "\\"
    $comparename = $array[4..($array.Length – 1)] -join "\"
    $FileRecord = "Development" + ";" +  $comparename + ";" + $FileEntry.LastWriteTime + ";" + $FileEntry.Length
    Add-Content $DevFile $FileRecord
}


# Delete old output files
$ReportFilelist = Get-ChildItem $ADHC_ProdCompareDir -include report*.* -recurse -file | Select FullName
foreach ($rpt in $ReportFilelist) {
    Remove-Item $rpt.Fullname
}

$StageFilelist = Get-ChildItem $ADHC_ProdCompareDir -include Staging*.* -recurse -file | Select FullName
foreach ($rpt in $StageFilelist) {
    Remove-Item $rpt.Fullname
}
Rename-Item -Path "$StageFile" -NewName "Staging.txt"

$DevFilelist = Get-ChildItem $ADHC_ProdCompareDir -include Dev*.* -recurse -file | Select FullName
foreach ($rpt in $DevFilelist) {
    Remove-Item $rpt.Fullname
}
Rename-Item -Path "$DevFile" -NewName "Development.txt"



$CompareList = Get-ChildItem $ADHC_ProdCompareDir -file | Select FullName 
# $CompareList | Out-Gridview


$ProdFileList = New-Object System.Collections.ArrayList


foreach ($FileEntry in $CompareList) {
    $content = Get-Content $FileEntry.Fullname
    # $content
    # $a[1]
    $i = 0;
    foreach ($rec in $content) {
        if ($i -ne 0) {
        
            $arr = $rec -split ';'
            # $arr
            $hashit = @{}
            
            $hashit.Computer=$arr[0]
            $hashit.Filename=$arr[1]
            $hashit.Lastupdate=[datetime]$arr[2]
            $hashit.FileSize=[int]$arr[3]
            [void]$ProdFileList.Add($hashit)
        }
       
        $i = $i + 1
    }

}

# $ProdFileList | Out-GridView

$Sortedlist = $ProdFileList | Sort-Object @{Expression={$_.Filename};Descending=$false},`
                                            @{Expression= {$_.Lastupdate};Descending=$true} 
# $Sortedlist | Out-GridView

$CurFilename = " "

$Report = $ADHC_ProdCompareDir + "Report.txt"
Set-Content $Report $Scriptmsg -force
$Anyfound = $false
$hostlist = New-Object System.Collections.ArrayList



foreach ($hashit in $Sortedlist) {
    if ($CurFilename -ne $hashit.Filename) {
        
        if ($CurFilename -ne " ") {
            # $hostlist
            if (($hostlist.Count -gt 0) -and (!$found)) {
              Add-Content $Report " "
            }
            foreach ($h in $hostlist) {
                $msg = "File " + $CurFilename + " ** not found ** on " + $h
                Write-Warning $msg 
                Add-Content $Report $msg
                $Anyfound = $true
            }
        }
        

        $found = $false
        $CurLength = $hashit.FileSize
        $CurDatetime = $hashit.Lastupdate
        $Curfilename = $hashit.Filename
        $hostlist.Clear();
        foreach ($c in $ADHC_Hostlist){
            
            [void]$hostlist.Add($c.ToUpper())
        }
        [void]$hostlist.Add("Staging")
        [void]$hostlist.Add("Development")
        # $hostlist
    }
    # Write-Information "remove"
    # $hostlist
    # $hashit.Computer + " -Computer"
    $hostlist.Remove($hashit.Computer)
    # $hostlist
    # Write-Information "end remove"

    if (($CurLength -ne $hashit.FileSize) -or ($CurDatetime -ne $hashit.Lastupdate)) {
        $Anyfound = $true
        if (! $found) {
            Add-Content $Report " "
            $msg = "File "+ $CurFilename + " has timestamp " + $CurDatetime + " and filesize " + $CurLength + " on last update."
            Write-Information $msg
            Add-Content $Report $msg
            $found = $true
        }
        $msg = "File "+ $hashit.Filename + " has timestamp " + $hashit.Lastupdate + " and filesize " + $hashit.FileSize + " on "+ $hashit.Computer
        Write-Warning $msg
        Add-Content $Report $msg
    }    
}

if (! $Anyfound ) {
    $msg = "** No differences found ** "
    Write-Information $msg
    Add-Content $Report $msg
}



   




