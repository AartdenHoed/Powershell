cls
$a = Get-WmiObject win32_service | select PSComputerName, SystemName, Name, Caption, Displayname,
                                     PathName, ServiceType, StartMode, 
                                     Started, State, Status, ExitCode, Description
$AantalServices = $a.Count

$b = $a | Sort-Object PathName 

$AantalPaths = $b.count

Write-Host "AantalServices Services met $AantalPaths Paths"

$mylist = @()

foreach ($service in $b) {
    $thispath = $service.PathName
    $ProgramName = ''
    if ($thispath -match '"(.*?)"') {
        $ProgramName = $matches[1]
    }
    else {
        if ($thispath -match '(.*?)\s'){
        $ProgramName = $matches[1]
        }
        else {
            $ProgramName = $thispath    
        }
    }
    if (-not $ProgramName) {
        $ProgramName = "Unknown"
        $service
    }
    $service | Add-Member NoteProperty ProgramName($ProgramName)
    $mylist += $service
}

Write-Host "================="

$mylist