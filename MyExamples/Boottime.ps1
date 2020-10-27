$i = Invoke-Expression('systeminfo | find /i "Boot Time"')
$i
$j = $i.Replace(" ", "").SPlit(" :,-")
$day = $j[1]
$month = $j[2]
$year = $j[3]
$hour = $j[4]
$minute = $j[5]
$second = $j[6]

$day 
$month 
$year 
$hour 
$minute 
$second 
$boottime = Get-Date -Year $year -Month $month -Day $day -Hour $hour -Minute $minute -Second $second
$boottime.ToString()
$x = Get-CimInstance -Class Win32_OperatingSystem | Select-Object LastBootUpTime