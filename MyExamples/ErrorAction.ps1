$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"


try {
    write-host "try"
    $ping = Test-Connection -COmputerName 192.168.178.5 -Count 1

}
catch {
    write-host "catch: ping = $ping"
}
Finally {
    write-host "finally: ping = $ping"
    
}
