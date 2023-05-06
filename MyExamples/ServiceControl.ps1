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
    }
    $software = " "
    $spl = $ProgramName.Split("\")
    if ($spl.count -eq 3) {
        $software = $spl[1]
    }
    else {
        $software = $spl[2]
    }
    if (-not $Software) {
        $Software = "Unknown"
    }
    if ( ($Software -eq "Unknown") -or ($ProgramName -eq "Unknown")) {
        $service
    }
    $service | Add-Member NoteProperty ProgramName($ProgramName)
    $service | Add-Member NoteProperty Software($software)
    $mylist += $service
}

Write-Host "================="

$mylist