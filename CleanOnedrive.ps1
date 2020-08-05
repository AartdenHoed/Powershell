
$InformationPreference = "Continue"
$WarningPreference = "Continue"

$Version = " -- Version: 1.11"
$Node = " -- Node: " + $env:COMPUTERNAME
$d = Get-Date
$Datum = " -- Date: " + $d.ToShortDateString()
$Tijd = " -- Time: " + $d.ToShortTimeString()
$Scriptmsg = "PowerShell script " + $MyInvocation.MyCommand.Name + $Version + $Datum + $Tijd +$Node
Write-Information $Scriptmsg 


$OneDrive = $ADHC_OneDrive
$FileList = Get-ChildItem $OneDrive -recurse  -name -force
# $FileList | Out-Gridview

# Init reporting file
$str = $ADHC_ConflictRpt.Split("/")
$dir = $ADHC_OutputDirectory + $str[0]
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$TxtFile = $ADHC_OutputDirectory + $str[0] + '/NEW_'+ $str[1]

Set-Content $TxtFile $Scriptmsg
Add-Content $TxtFile "Overview of OneDrive conficts"
Add-Content $TxtFile " "

foreach ($HostName in $ADHC_Hostlist) {
    $SearchFor1 = "-" + $HostName.ToUpper() + "\."
    $SearchFor1
    $SearchFor2 = "-" + $HostName.ToUpper() + "\Z"
    $SearchFor2
    $SearchFor3 = "-" + $HostName.ToUpper() + "-\d"
    $SearchFor3
    Add-Content $TxtFile "Computer $Hostname :"
    $ConflictsFound = $false
    foreach ($FileName in $FileList) {        
        $a = select-string -InputObject $FileName.ToUpper() -pattern $SearchFor1 
        $a
        $b = select-string -InputObject $FileName.ToUpper() -pattern $SearchFor2 
        $b
        $c = select-string -InputObject $FileName.ToUpper() -pattern $SearchFor3 
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

# Delete old output files
$ConflictFilelist = Get-ChildItem $ADHC_ConflictsDir -include conflict*.* -recurse -file | Select FullName
foreach ($rpt in $ConflictFilelist) {
    Remove-Item $rpt.Fullname
}
Rename-Item -Path "$TxtFile" -NewName "Conflicts.txt"