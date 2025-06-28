$Version = " -- Version: 2.0.1"

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
$d = Get-Date
$Datum = " -- Date: " + $d.ToString("dd-MM-yyyy")
$Tijd = " -- Time: " + $d.ToString("HH:mm:ss")

$myname = $MyInvocation.MyCommand.Name
$enqprocess = $myname.ToUpper().Replace(".PS1","")
$FullScriptName = $MyInvocation.MyCommand.Definition
$mypath = $FullScriptName.Replace($MyName, "")

$Scriptmsg = "*** STARTED *** " + $mypath + " -- PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node
Write-Information $Scriptmsg 

$LocalInitVar = $mypath + "InitVar.PS1"
$InitObj = & "$LocalInitVar" "OBJECT"

if ($Initobj.Abend) {
    # Write-Warning "YES"
    throw "INIT script $LocalInitVar Failed"

}
  
# END OF COMMON CODING

 
# Init reporting file
$dir = $ADHC_TempDirectory + $ADHC_BootTimeLog.Directory
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$tempfile = $dir + $ADHC_BootTimeLog.Name

Set-Content $TempFile $Scriptmsg -force

foreach ($entry in $InitObj.MessageList){
    Report $entry.Level $entry.Message $StatusObj $tempfile
}

# Init jobstatus file
$dir = $ADHC_OutputDirectory + $ADHC_Jobstatus
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$p = $myname.Split(".")
$process = $p[0]
$jobstatus = $ADHC_OutputDirectory + $ADHC_Jobstatus + $ADHC_Computer + "_" + $Process + ".jst" 

try {

    Report "N" $Separator $StatusObj $Tempfile     
        
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
    $Returncode = 16
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
        Report "I" "Boot data update successful $Datum $Tijd" $StatusObj $Tempfile
        Report "N" " " $StatusObj $Tempfile
   
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "0" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline

    }
   
    try { #  copy temp file
        
        $deffile = $ADHC_OutputDirectory + $ADHC_BootTimeLog.Directory + $ADHC_BootTimeLog.Name 
            
        $Copmov = & $ADHC_CopyMoveScript $TempFile $deffile "COPY" "REPLACE" $TempFile  
            
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
        $Returncode = 16
           

    }  
    Finally {
        $d = Get-Date
        $Datum = " -- Date: " + $d.ToString("dd-MM-yyyy")
        $Tijd = " -- Time: " + $d.ToString("HH:mm:ss") 
        $Scriptmsg = "*** ENDED ***** " + $mypath + " -- PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node
        Report "N" $scriptmsg $StatusObj $deffile
        Report "N" " " $StatusObj $deffile
        Write-Host $scriptmsg
        Exit $Returncode
    }  
        
}