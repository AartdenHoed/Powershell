$encoder = new-object System.Text.UTF8Encoding
$bytes = $encoder.Getbytes('nZr4u7w!z%C*F-JaNdRgUkXp2s5v8y/A')


$PlainPassword = 'POEP'

$SecurePassword =  ConvertTo-SecureString -String $Plainpassword -AsPlainText -Force


$SecureStringAsPlainText =  ConvertFrom-SecureString $SecurePassword -Key $bytes

EXIT

Set-COntent "D:\AartenHetty\OneDrive\ADHC Output\PRTG\SaveString.txt" $Securestringasplaintext -force

$x = Get-Content "D:\AartenHetty\OneDrive\ADHC Output\PRTG\SaveString.txt"

$SecureString = ConvertTo-SecureString $x -Key $bytes

$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList "ADHCode", $Securestring




Invoke-Command -ComputerName Holiday -ScriptBlock { Get-CimInstance -Class Win32_OperatingSystem | Select-Object LastBootUpTime } -Credential $Credentials

