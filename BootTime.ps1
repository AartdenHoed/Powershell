$Version = " -- Version: 1.1.3"

# COMMON coding
CLS

# init flags
$StatusObj = [PSCustomObject] [ordered] @{Scripterror = $false;                                       
                                          Recordslogged = $false;
                                          }

$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"

# ------------------ FUNCTIONS
function Report ([string]$level, [string]$line, [object]$Obj, [string]$file ) {
    switch ($level) {
        ("N") {$rptline = $line}
        ("I") {
            $rptline = "Info    *".Padright(10," ") + $line
        }
        ("A") {
            $rptline = "Caution *".Padright(10," ") + $line
        }
        ("B") {
            $rptline = "        *".Padright(10," ") + $line
        }
        ("C") {
            $rptline = "Change  *".Padright(10," ") + $line
            
        }
        ("W") {
            $rptline = "Warning *".Padright(10," ") + $line
            
        }
        ("E") {
            $rptline = "Error   *".Padright(10," ") + $line
            $obj.scripterror = $true
        }
        ("G") {
            $rptline = "GIT:    *".Padright(10," ") + $line
        }
        default {
            $rptline = "Error   *".Padright(10," ") + "Messagelevel $level is not valid"
            $Obj.Scripterror = $true
        }
    }
    Add-Content $file $rptline

}


# ------------------------ END OF FUNCTIONS

# ------------------------ START OF MAIN CODE


$Node = " -- Node: " + $env:COMPUTERNAME

$myname = $MyInvocation.MyCommand.Name
$enqprocess = $myname.ToUpper().Replace(".PS1","")
$FullScriptName = $MyInvocation.MyCommand.Definition
$mypath = $FullScriptName.Replace($MyName, "")

$LocalInitVar = $mypath + "InitVar.PS1"
$InitObj = & "$LocalInitVar" "OBJECT"

if ($Initobj.Abend) {
    # Write-Warning "YES"
    throw "INIT script $LocalInitVar Failed"

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

Set-Content $tempfile "Started... up time monitoring" -Force
$tempset = $true

foreach ($entry in $InitObj.MessageList){
        Report $entry.Level $entry.Message $StatusObj $tempfile
}

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

foreach ($entry in $InitObj.MessageList) {
    Report $entry.Level $entry.Message $StatusObj $Tempfile
}


do {
    $d = Get-Date
    $Datum = " -- Date: " + $d.ToString("dd-MM-yyyy")
    $Tijd = " -- Time: " + $d.ToString("HH:mm:ss")
    $loop = $loop + 1

    if ($tempset) {
        Add-Content $tempfile "..." 
    }
    else {
        Set-Content $tempfile "..." -Force
    }
    $tempset = $false

    Report "N" $Separator $StatusObj $Tempfile
    $Scriptmsg = "*** STARTED *** " + $mypath + " -- PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node
    Report "N" $Scriptmsg $StatusObj $Tempfile
    Write-Information $Scriptmsg 
    


    Report "I" "Process name = $ProcessName, proces ID = $ProcessID" $StatusObj $Tempfile

    Report "I"  "Iteration number $loop" $StatusObj $Tempfile
        
    try {
        # get boottime of machine
        Report "I"  "Get boottime from machine $ADHC_Computer" $StatusObj $Tempfile

                            
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
        Report "I" "Boot date & time = $ft, Uptime = $uptime minutes" $StatusObj $Tempfile

        $bootrec = "$ADHC_Computer" + "|" + $boottime.ToString("dd-MM-yyyy HH:mm:ss") + "|" + $stoptime.ToString("dd-MM-yyyy HH:mm:ss" + "|" + $uptime)
        Set-Content $bootfile "$bootrec"
                
        
        
    }
           
       
    catch {
        Report "E" "Error !!!" $StatusObj $Tempfile
        $errorcount += 1
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        $Dump = $_.Exception.ToSTring()
        Report "E" "Message = $ErrorMessage" $StatusObj $Tempfile
        Report "E" "Failed Item = $Faileditem" $StatusObj $Tempfile
        Report "E" "Dump = $Dump" $StatusObj $Tempfile
    } 
    finally {
       
        if  ($StatusObj.Scripterror) {
             $dt = Get-Date
            $jobline = $ADHC_Computer + "|" + $process + "|" + "9" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
            Set-Content $jobstatus $jobline
       
            Add-Content $jobstatus "Failed item = $FailedItem"
            Add-Content $jobstatus "Errormessage = $ErrorMessage"
            Add-Content $jobstatus "Dump info = $dump"

            Report "E" "Failed item = $FailedItem" $StatusObj $Tempfile
            Report "E" "Errormessage = $ErrorMessage" $StatusObj $Tempfile
            Report "E" "Dump info = $dump" $StatusObj $Tempfile
            }
        else {
            Report "I" "Script (iteration) ended normally $Datum $Tijd" $StatusObj $Tempfile
            Report "N" " " $StatusObj $Tempfile
   
            $dt = Get-Date
            $jobline = $ADHC_Computer + "|" + $process + "|" + "0" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
            Set-Content $jobstatus $jobline

        }
        Report "I" "Wait 300 seconds..." $StatusObj $Tempfile
        Report "N" " " $StatusObj $Tempfile
        try { #  copy temp file
        
            $deffile = $ADHC_OutputDirectory + $ADHC_BootTimeLog.Directory + $ADHC_BootTimeLog.Name 
            if ($loop -eq 1) {
                $Copmov = & $ADHC_CopyMoveScript $TempFile $deffile "MOVE" "REPLACE" $TempFile  
            }
            else {
                $Copmov = & $ADHC_CopyMoveScript $TempFile $deffile "MOVE" "APPEND" $TempFile  
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

Report "E" "Ended with error count = $errorcount" $StatusObj $Tempfile