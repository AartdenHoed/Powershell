$a = Get-ChildItem -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles\"
$n = 0
foreach ($entry in $a) {
    $n +=1
    $p = $entry.GetValue("ProfileName")
    $d = $entry.GetValue("Description")
    
    Write-host "==> Nummer $n"
    Write-host $p, $d
    $x = "Registry::" + $entry.name
    $x

    if ($d -eq "ExpressVPN") {
        Remove-Item -literalpath "$x"    
    
    }
    
}
$b = Get-ChildItem -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Signatures\Unmanaged"
$n = 0
foreach ($entry in $b) {
    $n +=1
    $p = $entry.GetValue("FirstNetwork")
    $d = $entry.GetValue("Description")
    
    Write-host "==> Nummer $n"
    Write-host $p, $d
    $x = "Registry::" + $entry.name
    $x

    if ($d -like "*ExpressVPN*") {
        Remove-Item -literalpath "$x"    
        Write-Host "YES"
    }
    
}
