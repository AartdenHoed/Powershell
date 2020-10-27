CLS
$ErrorActionPreference = "Continue"
Enable-PSRemoting -Force -SkipNetworkProfileCheck
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
Write-Host "Test connection Laptop-AHMRDH:"
Test-Wsman Laptop-AHMRDH -port 5985
Write-Host "===================================================================================="
Write-Host "Test connection ADHC:"
Test-Wsman ADHC -port 5985
Write-Host "===================================================================================="
Write-Host "Test port 5985 Holiday:"
Test-NetConnection Holiday -Port 5985
Write-Host "===================================================================================="
Write-Host "Test port 5985 Laptop-AHMRDH:"
Test-NetConnection Laptop-AHMRDH -Port 5985
Write-Host "===================================================================================="
Write-Host "Test port 5985 ADHC:"
Test-NetConnection ADHC -Port 5985
Write-Host "===================================================================================="
Write-Host "Allow Unencrypted (client + Service):"
winrm set winrm/config/client '@{AllowUnencrypted="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
Write-Host "===================================================================================="
Write-Host "WinRM COnfig:"
winrm get winrm/config

