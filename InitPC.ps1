# Dit script zowel in 32 als in 64 bit mode draaien, in ADMIN mode!

# Set securuty string
$Version = " -- Version: 1.1"

New-Item –Path "HKLM:\SOFTWARE\" –Name ADHC
New-ItemProperty -Path "HKLM:\SOFTWARE\ADHC" -Name "SecurityString" -Value 'nZr4u7w!z%C*F-JaNdRgUkXp2s5v8y/A'  -PropertyType "String"

$a = Get-ItemProperty -path HKLM:\SOFTWARE\ADHC | Select-Object -ExpandProperty "SecurityString"
Write-Host "String = $a"

# Now run INITVAR

$Node = " -- Node: " + $env:COMPUTERNAME
$d = Get-Date
$Datum = " -- Date: " + $d.ToString("dd-MM-yyyy")
$Tijd = " -- Time: " + $d.ToString("HH:mm:ss")

$myname = $MyInvocation.MyCommand.Name
$FullScriptName = $MyInvocation.MyCommand.Definition
$mypath = $FullScriptName.Replace($MyName, "")

$Scriptmsg = "*** STARTED *** " + $mypath + " -- PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node
Write-Information $Scriptmsg 

$LocalInitVar = $mypath + "InitVar.PS1"
$InitObj = & "$LocalInitVar" "MSG"

if ($Initobj.Abend) {
    # Write-Warning "YES"
    throw "INIT script $LocalInitVar Failed"

}

# Enable remote powershell

Enable-PSRemoting -Force -SkipNetworkProfileCheck

# Set trusted hosts

Write-Host "===================================================================================="
Write-Host "Before:"
Get-Item wsman:\localhost\client\trustedhosts 
Write-Host "===================================================================================="
Write-Host "Set TRUSTEDHOSTS:"
Set-Item wsman:\localhost\client\trustedhosts -Value ($ADHC_Hoststring)
Write-Host "===================================================================================="
Write-Host "After:"
Get-Item wsman:\localhost\client\trustedhosts 
Write-Host "===================================================================================="
Write-Host "Restart:"
Restart-Service WinRM
Write-Host "===================================================================================="
Write-Host "Test connection Holiday:"
Test-WsMan Holiday -port 5985
Write-Host "===================================================================================="
Write-Host "Test connection HoeSto:"
Test-Wsman HoeSto -port 5985
Write-Host "===================================================================================="
Write-Host "Test connection ADHC-2:"
Test-Wsman ADHC-2 -port 5985
Write-Host "===================================================================================="
Write-Host "Test port 5985 Holiday:"
Test-NetConnection Holiday -Port 5985
Write-Host "===================================================================================="
Write-Host "Test port 5985 HoeSto:"
Test-NetConnection HoeSto -Port 5985
Write-Host "===================================================================================="
Write-Host "Test port 5985 ADHC-2:"
Test-NetConnection ADHC-2 -Port 5985
Write-Host "===================================================================================="
Write-Host "Allow Unencrypted (client + Service):"
winrm set winrm/config/client '@{AllowUnencrypted="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
Write-Host "===================================================================================="
Write-Host "WinRM COnfig:"
winrm get winrm/config