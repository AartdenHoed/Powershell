# Mass update of GIT config files

$Version = " -- Version: 1.0"

# COMMON coding
CLS

$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"


$Node = " -- Node: " + $env:COMPUTERNAME
$d = Get-Date
$Datum = " -- Date: " + $d.ToShortDateString()
$Tijd = " -- Time: " + $d.ToShortTimeString()

$myname = $MyInvocation.MyCommand.Name
$FullScriptName = $MyInvocation.MyCommand.Definition
$mypath = $FullScriptName.Replace($MyName, "")

$Scriptmsg = "Directory " + $mypath + " -- PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node
Write-Information $Scriptmsg 

$LocalInitVar = $mypath + "InitVar.PS1"
& "$LocalInitVar"

# END OF COMMON CODING


$GitList = Get-ChildItem $ADHC_DevelopDir -Directory -Recurse -Filter ".git" -force | Select Name,FullName

foreach ($GitDir in $GitLIst) {
    $configfile = $GitDir.FullName + "\config"
    $c = Get-Content $configfile
    $d = $c.Replace("C:/Users/AartenHetty/OX Drive/My files/ADHC/RemoteRepository","D:/AartenHetty/OneDrive/ADHC RemoteRepository")
    Write-Host "============================================="
    $d
    Set-Content $configfile $d
}