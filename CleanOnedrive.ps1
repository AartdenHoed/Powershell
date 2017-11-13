
$InformationPreference = "Continue"
$WarningPreference = "Continue"

$Version = " -- Version: 1.8"
$Node = " -- Node: " + $env:COMPUTERNAME
$d = Get-Date
$Datum = " -- Date: " + $d.ToShortDateString()
$Tijd = " -- Time: " + $d.ToShortTimeString()
$Scriptmsg = "PowerShell script " + $MyInvocation.MyCommand.Name + $Version + $Datum + $Tijd +$Node
Write-Information $Scriptmsg 


$OneDrive = $ADHC_OneDrive
$FileList = Get-ChildItem $OneDrive -recurse  -name -force
# $FileList | Out-Gridview

$TxtFile = $ADHC_ConflictsDir  + "Conflicts.txt"

Set-Content $TxtFile $Scriptmsg
Add-Content $TxtFile "Overview of OneDrive conficts"
Add-Content $TxtFile " "

foreach ($HostName in $ADHC_Hostlist) {
    $SearchFor1 = "-" + $HostName + "\."
    $SearchFor1
    $SearchFor2 = "-" + $HostName + "\Z"
    $SearchFor2
    $SearchFor3 = "-" + $HostName + "-\d"
    $SearchFor3
    Add-Content $TxtFile "Computer $Hostname :"
    $ConflictsFound = $false
    foreach ($FileName in $FileList) {        
        $a = select-string -InputObject $FileName -pattern $SearchFor1 
        $a
        $b = select-string -InputObject $FileName -pattern $SearchFor2 
        $b
        $c = select-string -InputObject $FileName -pattern $SearchFor3 
        $c
        if ($a -or $b -or $c) {
            $ConflictsFound = $true
            Add-Content $TxtFile "  ==> $FileName"
            }
        
        }
    if (!$ConflictsFound) {
        Add-Content $TxtFile "  No Conflicts Found"
        }
    
    }
