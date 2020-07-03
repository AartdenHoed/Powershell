CLS
$InformationPreference = "Continue"
$WarningPreference = "Continue"

$Version = " -- Version: 1.0"
$Node = " -- Node: " + $env:COMPUTERNAME
$d = Get-Date
$Datum = " -- Date: " + $d.ToShortDateString()
$Tijd = " -- Time: " + $d.ToShortTimeString()
$Scriptmsg = "PowerShell script " + $MyInvocation.MyCommand.Name + $Version + $Datum + $Tijd +$Node
Write-Information $Scriptmsg 

$FullScriptName = $MyInvocation.MyCommand.Definition
$ScriptName = $MyInvocation.MyCommand.Name
$ADHC_PsPath = $FullScriptName.Replace($ScriptName, "")
$ADHC_InitVar = $ADHC_PsPath + "InitVar.PS1"
& "$ADHC_InitVar"


Set-Location -Path $devdir
$gitdirs = Get-ChildItem "*.git" -Recurse
foreach ($gitentry in $gitdirs) {
    $dir = $gitentry.FullName
   
    $dir = $dir.replace(".git","")
    Write-Information "Directory $dir"

    Set-Location $dir
    &git branch -v
}