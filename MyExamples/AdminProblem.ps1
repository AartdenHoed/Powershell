#Invoke-Command -ScriptBlock {[IntPtr]::Size}

#Invoke-Command -ScriptBlock {[IntPtr]::Size} -ComputerName $env:COMPUTERNAME -Credential $Credential

#Invoke-Command -ScriptBlock {[IntPtr]::Size} -ComputerName $env:COMPUTERNAME -Credential $Credential -ConfigurationName Microsoft.PowerShell32



Function Set-SessionConfig

{

 Param( [string]$user )

 $account = New-Object Security.Principal.NTAccount $user

 $sid = $account.Translate([Security.Principal.SecurityIdentifier]).Value

 

 $config = Get-PSSessionConfiguration -Name “Microsoft.PowerShell”

 $existingSDDL = $Config.SecurityDescriptorSDDL

 

 $isContainer = $false

 $isDS = $false

 $SecurityDescriptor = New-Object -TypeName System.Security.AccessControl.CommonSecurityDescriptor -ArgumentList $isContainer,$isDS, $existingSDDL

   # Security.AccessControl.CommonSecurityDescriptor

 $accessType = “Allow” 

 $accessMask = 268435456 

 $inheritanceFlags = “none” 

 $propagationFlags = “none” 

 $SecurityDescriptor.DiscretionaryAcl.AddAccess($accessType,$sid,$accessMask,$inheritanceFlags,$propagationFlags) 

 $SecurityDescriptor.GetSddlForm(“All”)

} #end Set-SessionConfig

 

# *** Entry Point to script ***

Get-PSSessionConfiguration 

$user = “ADHC\AartenHetty”

$newSDDL = Set-SessionConfig -user $user

Get-PSSessionConfiguration |

ForEach-Object {

 Set-PSSessionConfiguration -name $_.name -SecurityDescriptorSddl  $newSDDL -force }

 Get-PSSessionConfiguration