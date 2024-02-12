$a = Get-WmiObject -Class Win32_Product

$b1 = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall"

$b2 = Get-ChildItem "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall"

$c = Get-WinEvent -ProviderName msiinstaller | where id -eq 1033 | select timecreated,message | FL *



$a | Out-GridView

$b1 | Out-GridView

$b2 | Out-GridView

$c | Out-

cls
$n = 0
foreach ($obj in $b1) {
    Write-host "***"
    $obj.Name
    
    $n += 1
    If ($n -gt 3 ) {break}
    Write-host "Properties:" 
    foreach ($p in $obj.Property) {
        $p
        $x = (Get-ItemPropertyValue -LiteralPath "$obj" -Name $p)."$p"

    }
}
