cls

$InformationPreference = "Continue"
$WarningPreference = "Continue"

$Version = " -- Version: 1.0"
$Node = " -- Node: " + $env:COMPUTERNAME
$d = Get-Date
$Datum = " -- Date: " + $d.ToShortDateString()
$Tijd = " -- Time: " + $d.ToShortTimeString()
$Scriptmsg = "PowerShell script " + $MyInvocation.MyCommand.Name + $Version + $Datum + $Tijd +$Node
Write-Information $Scriptmsg 

$DiskList = Get-ChildItem "D:\" -recurse -force -file | Select FullName,Name 
$Total = $DiskList.Count

Write-Host "Totaal aantal bestanden = " $Total

$count = 0
foreach ($FileEntry in $DiskList) {
    
    if ($FileEntry.Name -eq ".picasa.ini") {
        Write-Host $FileEntry.Fullname
        Remove-item $FileEntry.Fullname -Force
        $count = $count + 1
    }
    
  
}
Write-warning "Delete count = $count"
