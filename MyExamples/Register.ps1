# Dit script zowel in 32 als in 64 bit mode draaien, in ADMIN mode!


New-Item –Path "HKLM:\SOFTWARE\" –Name ADHC
New-ItemProperty -Path "HKLM:\SOFTWARE\ADHC" -Name "SecurityString" -Value 'nZr4u7w!z%C*F-JaNdRgUkXp2s5v8y/A'  -PropertyType "String"



$a = Get-ItemProperty -path HKLM:\SOFTWARE\ADHC | Select-Object -ExpandProperty "SecurityString"
Write-Host "String = $a"