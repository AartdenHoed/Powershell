Clear-Host


$InformationPreference = "Continue"
$WarningPreference = "Continue"

$Version = " -- Version: 1.5"
$Node = " -- Node: " + $env:COMPUTERNAME
$d = Get-Date
$Datum = " -- Date: " + $d.ToShortDateString()
$Tijd = " -- Time: " + $d.ToShortTimeString()
$Scriptmsg = "PowerShell script " + $MyInvocation.MyCommand.Name + $Version + $Datum + $Tijd +$Node
Write-Information $Scriptmsg 

Write-Information "Please wait while running profile scripts"
Write-Information "..."

$FullScriptName = $MyInvocation.MyCommand.Definition
$ScriptName = $MyInvocation.MyCommand.Name
$ADHC_PsPath = $FullScriptName.Replace($ScriptName, "")
$ADHC_InitVar = $ADHC_PsPath + "InitVar.PS1"
& "$ADHC_InitVar"


$msg = "Hello " + $ADHC_User + " on computer " + $ADHC_Computer
Write-Information $msg
Set-Location c:\