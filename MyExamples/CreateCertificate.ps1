$DNSName="ADHC.Fritz.Box"
$Subject="Self SIgned certificaat voor ADHC"
$Thumbprint=""
$Certificates=Get-ChildItem -Path Cert:\localMachine\My

ForEach ($Certificate in $Certificates) {
    If (Test-Certificate -cert $Certificate -Policy SSL -DNSName "${DNSName}" -ErrorAction SilentlyContinue) {
        write-host "Certificate already exists"
        $thumbprint=$certificate.Thumbprint
        $cert=$Certificate
    }
}
If ($thumbprint -EQ "") {
  write-host 'No certificate found. Will create a new one.'
  $thumbprint = (New-SelfSignedCertificate -DnsName $env:computername,"localhost","$env:computername.$env:userdnsdomain","${DNSName}" -NotAfter $([datetime]::now.AddYears(1000)) -certstorelocation "cert:\localMachine\my" -subject "${Subject}" -KeyExportPolicy Exportable).thumbprint
  $cert = (Get-ChildItem -Path cert:\localmachine\My\$thumbprint)
  $pwd = ConvertTo-SecureString -String "1234" -Force -AsPlainText
  Export-PFXCertificate -Cert $Cert -filepath $env:temp\$thumbprint.pfx -Password $pwd
  Import-PfxCertificate -filepath $env:temp\$thumbprint.pfx -Password $pwd -CertStoreLocation "cert:\LocalMachine\Root"
  remove-item -path $env:temp\$thumbprint.pfx
}
$rsaCert = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
$fileName = $rsaCert.key.UniqueName
$path = "$env:ALLUSERSPROFILE\Microsoft\Crypto\Keys\$fileName"
$permissions = Get-Acl -Path $path
$access_rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Network Service", 'Read', 'None', 'None', 'Allow')
$permissions.AddAccessRule($access_rule);Set-Acl -Path $path -AclObject $permissions
write-host "Thumbprint:$Thumbprint";


# ========================================
$thumbprint = "89B12021D84DFE6BF471D1D5F24D5DFE60848BD7"
$cert = (Get-ChildItem -Path cert:\localmachine\My\$thumbprint)
$pwd = ConvertTo-SecureString -String "1234" -Force -AsPlainText
Export-PFXCertificate -Cert $Cert -filepath "D:\Data\Sync Gedeeld\Computer\Software\PRTG\cert.pfx" -Password $pwd


Install-Module -Name PSPKI -force
Convert-PfxToPem -InputFile "D:\Data\Sync Gedeeld\Computer\Software\PRTG\cert.pfx" -Outputfile "D:\Data\Sync Gedeeld\Computer\Software\PRTG\cert.pem" `
                -Password $pwd 

$x = ConvertFrom-SecureString -SecureString $pwd 