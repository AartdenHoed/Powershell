$InformationPreference = "Continue"
$WarningPreference = "Continue"

$Version = " -- Version: 1.1"
$Node = " -- Node: " + $env:COMPUTERNAME
$d = Get-Date
$Datum = " -- Date: " + $d.ToShortDateString()
$Tijd = " -- Time: " + $d.ToShortTimeString()
$Scriptmsg = "PowerShell script " + $MyInvocation.MyCommand.Name + $Version + $Datum + $Tijd +$Node
Write-Information $Scriptmsg 

& C:\AdHC\PowerShell\Common_Profile.PS1