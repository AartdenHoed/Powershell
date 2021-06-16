CLS
$errorcount = 0
$loop = 0
$myname = $MyInvocation.MyCommand.Name
    
$FullScriptName = $MyInvocation.MyCommand.Definition
$mypath = $FullScriptName.Replace($MyName, "")

$sensorscript = $mypath + "CpuTemperature.ps1"
    & "$LocalInitVar"

do {
    $loop = $loop + 1
    Start-Sleep -s 10
    write-host "Loop $loop"
    try {

        & "$Sensorscript"

    }
    catch {

        $errorcount += 1
    
    } 


} Until ($errorcount -gt 10)