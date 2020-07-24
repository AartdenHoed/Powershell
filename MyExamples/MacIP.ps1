CLS
$lines = Get-Content -Path "D:\AartenHetty\OneDrive\ADHC Dev\Powershell/MacIP.txt"
$i = 0
$device = ""
$IPaddress = ""
$MACaddress = ""
$overview = @()
foreach ($line in $lines) {
    
    if ($line.trim() -eq "") {continue}
    $i = $i + 1
    switch ($i) {
        1 {$device = $line.trim() }
        2 {$IPaddress = $line.trim() }
        3 {
            $MACaddress = $line.trim()
            $obj = [PSCustomObject] [ordered]  @{Device = $device; IPaddress = $IPaddress; MACaddress = $MACaddress;}
        
            $overview += $obj
            $i = 0
            $device = ""
            $IPaddress = ""
            $MACaddress = ""

         }
        default { Write-error "i = $i"}
    }
}
$query = "TRUNCATE TABLE dbo.IPadressen" 
invoke-sqlcmd -ServerInstance ".\SQLEXPRESS" -Database "PRTG" `
                -Query "$query" `
                -ErrorAction Inquire
Write-Warning "Dbo.IPadressen truncated"

$n = 0
foreach ($entry in $overview) {
    $n = $n + 1
    $query = "INSERT INTO [dbo].[IPadressen] ([Naam],[IPaddress],[MACaddress]) VALUES('" + 
            $entry.Device + "','"+
            $entry.IPaddress + "','"+
            $entry.MACaddress + "')"
    invoke-sqlcmd -ServerInstance ".\SQLEXPRESS" -Database "PRTG" `
                -Query "$query" `
                -ErrorAction Inquire
} 

Write-Warning "$n entries inserted into dbo.IPadressen"

$overview | Out-GridView