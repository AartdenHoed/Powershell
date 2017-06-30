
$InformationPreference = "Continue"
$WarningPreference = "Continue"

$Version = " -- Version: 1.6"
$Node = " -- Node: " + $env:COMPUTERNAME
$d = Get-Date
$Datum = " -- Date: " + $d.ToShortDateString()
$Tijd = " -- Time: " + $d.ToShortTimeString()
$Scriptmsg = "PowerShell script " + $MyInvocation.MyCommand.Name + $Version + $Datum + $Tijd +$Node
Write-Information $Scriptmsg 

$ProdList = Get-ChildItem $ADHC_ProdDir -recurse -file | Select FullName,LastWriteTime,Length | Sort-Object Fullname
# $ProdList | Out-Gridview

$TxtFile = $ADHC_ProdCompareDir + $ADHC_Computer + ".txt"
$Report = $ADHC_ProdCompareDir + "Report.txt"

New-Item -ItemType Directory -Force -Path $ADHC_ProdCompareDir

Set-Content $TxtFile $Scriptmsg -force



foreach ($FileEntry in $ProdList) {

    $FileRecord = $ADHC_Computer + ";" +  $FileEntry.Fullname + ";" + $FileEntry.LastWriteTime + ";" + $FileEntry.Length

    Add-Content $TxtFile $FileRecord
    
}


Remove-Item $Report

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
                $msg = "File " + $CurFilename + " ** not found ** on computer " + $h
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
        $msg = "File "+ $hashit.Filename + " has timestamp " + $hashit.Lastupdate + " and filesize " + $hashit.FileSize + " on computer "+ $hashit.Computer
        Write-Warning $msg
        Add-Content $Report $msg
    }    
}

if (! $Anyfound ) {
    $msg = "** No differences found ** "
    Write-Information $msg
    Add-Content $Report $msg
}



   




