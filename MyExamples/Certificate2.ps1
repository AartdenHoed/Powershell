$a = Get-ChildItem -Path cert: -Recurse ! SELECT Subject, Thumbprint, FriendlyName
$a
foreach ($cert in $a) {
    if ($cert.Thumbprint -ne $null) {
        
        $x = $cert.Thumbprint.ToString()
        #if ($x -match "^E\d+") {
        #    Write-Host "B I N G O"
        #    Write-Host $x
        #}
        $y = $cert.FriendlyName
        if ($y -match ".*hot.*") {
            Write-Host "B I N G O"
            Write-Host $y
            Write-Host $cert
        }
        
    }
    # if ($cert.Thumbprint -eq )E5D49FE02E1F2BC92AF524AC75EAC3F89734D1C3
}