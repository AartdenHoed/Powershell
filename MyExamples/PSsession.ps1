$s = New-PSSession -Credential $ADHC_Credentials

Set-PSSessionConfiguration -Name Microsoft.powershell.workflow -showSecurityDescriptorUI

Get-PSSessionConfiguration

enable-psremoting -SkipNetworkProfileCheck -force

Enable-WSManCredSSP

winrm get winrm/config/winrs

Get-PSSessionConfiguration -Name Microsoft.powershell  | Format-List -Property *

dir wsman:\localhost\plugin

Test-WSMan

winrm get winrm/config

winrm get winrm/config/service/auth

Get-Item WSMan:\localhost\Client\TrustedHosts

winrm set winrm/config/service/auth '@{Kerberos="false"}'

winrm set -?


Restart-Service -ServiceName WinRM