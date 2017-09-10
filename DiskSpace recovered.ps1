
$InformationPreference = "Continue"
$WarningPreference = "Continue"

$Version = " -- Version: 1.0"
$Node = " -- Node: " + $env:COMPUTERNAME
$d = Get-Date
$Datum = " -- Date: " + $d.ToShortDateString()
$Tijd = " -- Time: " + $d.ToShortTimeString()
$Scriptmsg = "PowerShell script " + $MyInvocation.MyCommand.Name + $Version + $Datum + $Tijd +$Node
Write-Information $Scriptmsg 

$DiskList = Get-ChildItem "C:\" -recurse -file | Select FullName,LastWriteTime,Length | Sort-Object FullName
$DiskList | Out-Gridview

$qLevelsize = @(0,0,0,0,0)
$curqual = @("~", "~","~","~","~")

$qlist1 = [System.Collections.ArrayList]@()
$i = 0

foreach ($FileEntry in $DiskList) {
    # $i = $i + 1
    # $i
    # $FileEntry.FullName
    $qualifier = $FileEntry.FullName.Split("\")
    if ($qualifier[1] -ne $curqual) {
        $Entry = New-Object –TypeName PSObject -Property @{Name = $qualifier[1]; Length = $FileEntry.Length}
        $curqual = $qualifier[1]
        # $Entry
        [void]$qlist1.Add($Entry)
        # $qlist1        
    }
    else {        
        $len = $qlist1.Count -1
        $qlist1[$len].Length = $qlist1[$len].Length + $FileEntry.Length
        # $qlist1
    }
    # if ($i -eq 100) { break } 
  
}
$qlist1