$Version = " -- Version: 1.0.2"

# COMMON coding
CLS

# init flags
$global:scripterror = $false
$global:scriptaction = $false
$global:scriptchange = $false

$global:recordslogged = $false

$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"

# ------------------ FUNCTIONS
function Report ([string]$level, [string]$line) {
    switch ($level) {
        ("N") {$rptline = $line}
        ("I") {
            $rptline = "Info    *".Padright(10," ") + $line
        }
        ("H") {
            $rptline = "-------->".Padright(10," ") + $line
        }
        ("A") {
            $rptline = "Caution *".Padright(10," ") + $line
        }
        ("B") {
            $rptline = "        *".Padright(10," ") + $line
        }
        ("C") {
            $rptline = "Change  *".Padright(10," ") + $line
            $global:scriptchange = $true
        }
        ("W") {
            $rptline = "Warning *".Padright(10," ") + $line
            $global:scriptaction = $true
        }
        ("E") {
            $rptline = "Error   *".Padright(10," ") + $line
            $global:scripterror = $true
            
        }
        default {
            $rptline = "Error   *".Padright(10," ") + "Messagelevel $level is not valid"
            $global:scripterror = $true
        }
    }
    Add-Content $tempfile $rptline

}

# ------------------------ END OF FUNCTIONS

# ------------------------ START OF MAIN CODE


$Node = " -- Node: " + $env:COMPUTERNAME

$myname = $MyInvocation.MyCommand.Name
$enqprocess = $myname.ToUpper().Replace(".PS1","")
$FullScriptName = $MyInvocation.MyCommand.Definition
$mypath = $FullScriptName.Replace($MyName, "")

$LocalInitVar = $mypath + "InitVar.PS1"
& "$LocalInitVar"

if (!$ADHC_InitSuccessfull) {
    # Write-Warning "YES"
    throw $ADHC_InitError
}

  
   
# END OF COMMON CODING

$gp = Get-Process -id $pid 
$ProcessID = $gp.Id
$ProcessName = $gp.Name
$separator = "-".PadRight(120,"-") 
      

# Init reporting file
$dir = $ADHC_TempDirectory + $ADHC_BootTimeLog.Directory
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$tempfile = $dir + $ADHC_BootTimeLog.Name


# Init jobstatus file
$dir = $ADHC_OutputDirectory + $ADHC_Jobstatus
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$p = $myname.Split(".")
$process = $p[0]
$jobstatus = $ADHC_OutputDirectory + $ADHC_Jobstatus + $ADHC_Computer + "_" + $Process + ".jst" 

$errorcount = 0
$loop = 0
$myname = $MyInvocation.MyCommand.Name
    
$FullScriptName = $MyInvocation.MyCommand.Definition
$mypath = $FullScriptName.Replace($MyName, "")


Report "I" "Started... up time monitoring"

do {
    $d = Get-Date
    $Datum = " -- Date: " + $d.ToString("dd-MM-yyyy")
    $Tijd = " -- Time: " + $d.ToString("HH:mm:ss")
    $loop = $loop + 1
    Set-Content $Tempfile $Separator -force
    $Scriptmsg = "*** STARTED *** " + $mypath + " -- PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node
    Report "N" $Scriptmsg
    Write-Information $Scriptmsg 
    


    Report "I" "Process name = $ProcessName, proces ID = $ProcessID"

    Report "I"  "Iteration number $loop"
        
    try {
        # get boottime of machine
        Report "I"  "Get boottime from machine $ADHC_Computer"

                            
        $bt = Get-CimInstance -Class Win32_OperatingSystem | Select-Object LastBootUpTime
        $boottime = $bt.LastBootUpTime

        # Init boottime file if not existent
        $str = $ADHC_BootTime.Split("\")
        $dir = $ADHC_OutputDirectory + $str[0]
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        $bootfile = $ADHC_OutputDirectory + $ADHC_BootTime
        $lt = Test-Path $bootfile
        if (!$lt) {
            Set-Content $bootfile "$ADHC_Computer|01-01-2000 00:00:00|01-01-2000 00:00:00|0" -force
        }
        # Read bootfile
        $bootrec = Get-Content $bootfile
        if (!$bootrec) {
            $bootrec =  "$ADHC_Computer|01-01-2000 00:00:00|01-01-2000 00:00:00|0" 
        }
        
        $stoptime = Get-Date                # it's a minimal guess 

        $diff = NEW-TIMESPAN –Start $boottime –End $stoptime
        # Only check job status if computer has been up for >1,5 hour
        $uptime = [Math]::Round($diff.TotalMinutes, 1) 
        $ft = $boottime.ToString("dddd dd MMMM yyyy HH:mm:ss")
        Report "I" "Boot date & time = $ft, Uptime = $uptime minutes"

        $bootrec = "$ADHC_Computer" + "|" + $boottime.ToString("dd-MM-yyyy HH:mm:ss") + "|" + $stoptime.ToString("dd-MM-yyyy HH:mm:ss" + "|" + $uptime)
        Set-Content $bootfile "$bootrec"
                
        
        
    }
           
       
    catch {
        Report "E" "Error !!!"
        $errorcount += 1
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        $Dump = $_.Exception.ToSTring()
        Report "E" "Message = $ErrorMessage"
        Report "E" "Failed Item = $Faileditem"
        Report "E" "Dump = $Dump"
    } 
    finally {
       
        if  ($global:scripterror) {
             $dt = Get-Date
            $jobline = $ADHC_Computer + "|" + $process + "|" + "9" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
            Set-Content $jobstatus $jobline
       
            Add-Content $jobstatus "Failed item = $FailedItem"
            Add-Content $jobstatus "Errormessage = $ErrorMessage"
            Add-Content $jobstatus "Dump info = $dump"

            Report "E" "Failed item = $FailedItem"
            Report "E" "Errormessage = $ErrorMessage"
            Report "E" "Dump info = $dump"
            }
        else {
            Report "I" "Script (iteration) ended normally $Datum $Tijd"
            Report "N" " "
   
            $dt = Get-Date
            $jobline = $ADHC_Computer + "|" + $process + "|" + "0" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
            Set-Content $jobstatus $jobline

        }
        Report "I" "Wait 300 seconds..."
        Report "N" " "
        try { #  copy temp file
        
            $deffile = $ADHC_OutputDirectory + $ADHC_BootTimeLog.Directory + $ADHC_BootTimeLog.Name 
            if ($loop -eq 1) {
                & $ADHC_CopyMoveScript $TempFile $deffile "MOVE" "REPLACE" $TempFile  
            }
            else {
                & $ADHC_CopyMoveScript $TempFile $deffile "MOVE" "APPEND" $TempFile  
            }
        }
        Catch {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            $Dump = $_.Exception.ToSTring()
            $dt = Get-Date
            $jobline = $ADHC_Computer + "|" + $process + "|" + "9" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
            Set-Content $jobstatus $jobline
            Add-Content $jobstatus "Failed item = $FailedItem"
            Add-Content $jobstatus "Errormessage = $ErrorMessage"
            Add-Content $jobstatus "Dump info = $Dump"
            $errorcount += 1    

        }    
        
        
        Start-Sleep -s 300
    }

} Until ($errorcount -gt 10)

Report "I" "Ended with error count = $errorcount"