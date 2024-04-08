Clear-Host


$InformationPreference = "Continue"
$WarningPreference = "Continue"

$Version = " -- Version: 1.6"
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
$My_PsPath = $FullScriptName.Replace($ScriptName, "")
$My_InitVar = $My_PsPath + "InitVar.PS1"

$InitObj = & "$My_InitVar" "MSG"

if ($Initobj.Abend) {
    # Write-Warning "YES"
    throw "INIT script $LocalInitVar Failed"

}


$msg = "Hello " + $ADHC_User + " on computer " + $ADHC_Computer
Write-Information $msg
Set-Location c:\