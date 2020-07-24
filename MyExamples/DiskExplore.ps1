Set-Location 'c:\$RECYCLE.BIN'
$a = Get-ChildItem -Directory -File -Hidden -Force -System
$a | Out-GridView