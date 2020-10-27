


$PlainPassword = 'POEP'
$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force

$SecureStringAsPlainText = $SecurePassword | ConvertFrom-SecureString

EXIT

Set-COntent "D:\AartenHetty\OneDrive\ADHC Output\PRTG\SaveString.txt" $Securestringasplaintext -force

$x = Get-Content "D:\AartenHetty\OneDrive\ADHC Output\PRTG\SaveString.txt"

$SecureString = $x  | ConvertTo-SecureString

$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList "ADHCode", $Securestring




Invoke-Command -ComputerName Holiday -ScriptBlock { Get-CimInstance -Class Win32_OperatingSystem | Select-Object LastBootUpTime } -Credential $Credentials

