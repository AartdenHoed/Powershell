param (
    
    [string]$myHost  = "????" 
)

$myHost = "adhc"
 

function Running-Elevated
{
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object System.Security.Principal.WindowsPrincipal($id)

    if ($p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) { 
        $adm = $true 
    }      
    else { 
        $adm = $false 
    }
    $MyAuth = [PSCustomObject] [ordered] @{ID = $id;
                                           Principal = $p; 
                                           Administrator = $adm}
    return $MyAuth 
 } 

$myhost = $myhost.ToUpper()

$ScriptVersion = " -- Version: 1.6"

# COMMON coding
CLS
$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"

$Node = " -- Node: " + $env:COMPUTERNAME
$d = Get-Date
$Datum = " -- Date: " + $d.ToShortDateString()
$Tijd = " -- Time: " + $d.ToShortTimeString()

$myname = $MyInvocation.MyCommand.Name
$p = $myname.Split(".")
$process = $p[0]
$FullScriptName = $MyInvocation.MyCommand.Definition
$mypath = $FullScriptName.Replace($MyName, "")

$LocalInitVar = $mypath + "InitVar.PS1" 
& "$LocalInitVar" "SILENT"

if (!$ADHC_InitSuccessfull) {
    Write-Warning "INIT failed"
    throw $ADHC_InitError
}

$scripterror = $false

$el = Running-Elevated

$u = $el.id.Name
$ia = $el.Principal.Identity.IsAuthenticated

if (-not($el.Administrator)) {
    $msg =  "==> Script NOT running as administrator"
}
else {
    $msg = "==> Script running as administrator"
}
write-host $msg

$invokable = $true

if (!$scripterror) {
    try {
        
        try {
            write-host "Invoke now"                                    
            $myjob = Invoke-Command -ComputerName $myhost `
                -ScriptBlock { dir c:\ }  -Credential $ADHC_Credentials `
                -JobName TempJob  -AsJob -ErrorVariable e
            write-host "Wait"
            $myjob | Wait-Job -Timeout 60 
            if ($myjob) { 
                $mystate = $myjob.state
            } 
            else {
                $mystate = "Unknown" 
            }
            #get-job                                    
            Write-host $mystate
            $begin = $myjob.PSBeginTime
            $end = $myjob.PSEndTime
            $duration = ($end - $begin).seconds
            Write-host "Start = $begin, End = $end, duration = $duration seconds"
            if ($mystate -eq "Completed") {
                $reason = $myjob.JobStateInfo.Reason
                write-host "Completed (reason = $reason)"
                write-host "OUTPUT  ==="
                $RMObject = (Receive-Job -Name TempJob)
                foreach ($entry in $RMobject) {
                    Write-Host $entry
                }
                write-host "=========="
                                   
            }
            else {
              
                $reason = $myjob.JobStateInfo.Reason
                write-host "NOT completed (reason = $reason)"
        
                
            }
            write-host "Stop"
            $myjob | Stop-Job | Out-Null
            write-host "Remove"
            $myjob | Remove-Job | Out-null
        }
        catch {
            write-host "Catch"
            $invokable = $false
        }
        finally {
                
            Write-Host "Job ended with status $mystate. Invokable = $invokable"
        }

    }
    catch {
        
        $scripterror = $true
        $errortext = $error[0]
        $scripterrormsg = "==> Remote script failed for $myHost - $errortext"
    }
}




