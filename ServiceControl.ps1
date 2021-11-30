$a = Get-WmiObject win32_service | select PSComputerName, SystemName, Name, Caption, Displayname,
                                     PathNAme, ServiceType, StartMode, 
                                     Started, State, Status, ExitCode, Description
$a.count
$a[8]