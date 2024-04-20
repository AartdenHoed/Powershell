$Version = " -- Version: 6.3.1"

# COMMON coding
CLS
# init flags
$StatusOBJ = [PSCustomObject] [ordered] @{Scripterror = $false;
                                          ScriptChange = $false;
                                          ScriptAction = $false;
                                          RecordsLogged = $false
                                          }

$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"

function WriteLog ([string]$Action, [string]$line, [object]$obj, [string]$logfile) {
    $oldrecords = Get-Content $logfile 

    $logdate = Get-Date
    $logrec = $logdate.ToSTring("yyyy-MMM-dd HH:mm:ss").PadRight(24," ") + $ADHC_COmputer.PadRight(24," ") +
                (" *** " + $Action + " *** ").Padright(40," ") + $line.PadRight(160," ") + $logdate.ToString("dd-MM-yyyy HH:mm:ss")
    Set-Content $logfile $logrec
    $obj.recordslogged = $true

    $now = Get-Date
    $nrofnotkeep = 0

    foreach ($record in $oldrecords) {
        $keeprecord = $false
        if ($record.Length -ge 248) {
            $dtstring = $record.Substring(248)
            # $dtstring
            $timest = [datetime]::ParseExact($dtstring,"dd-MM-yyyy HH:mm:ss",$null)
            # $timest.ToString("yyyy-MMM-dd HH:mm:ss")
            $recordage = NEW-TIMESPAN –Start $timest –End $now
            if ($recordage.Days -le 50) {
                $keeprecord = $true    
            }
            else {
                $nrofnotkeep += 1
            }
        }
        if ($keeprecord) {
            Add-Content $logfile $record
        }
    }
    if ($nrofnotkeep -gt 0 ) {
        $logdate = Get-Date
        $line = "Housekeeping: $nrofnotkeep Old log records deleted"
        $logrec = $logdate.ToSTring("yyyy-MMM-dd HH:mm:ss").PadRight(24," ") + $ADHC_Computer.PadRight(24," ") +
                    (" *** Log Record Purge *** ").Padright(40," ") + $line.PadRight(160," ") + $logdate.ToString("dd-MM-yyyy HH:mm:ss")
        
        Add-Content $logfile $logrec 
    } 

}

function Report ([string]$level, [string]$line, [object]$Obj, [string]$file ) {
    switch ($level) {
        ("N") {$rptline = $line}
        ("H") {
            $rptline = "-------->".Padright(10," ") + $line
        }
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
            $obj.scriptchange = $true
        }
        ("W") {
            $rptline = "Warning *".Padright(10," ") + $line
            $obj.scriptaction = $true
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

try {                                             
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

    if ($Initobj.AbEnd) {
        # Write-Warning "YES"
        throw "INIT script $LocalInitVar Failed"

    }
    $m = & $ADHC_LockScript "Lock" "Git" "$enqprocess" 10 "OBJECT"    

# END OF COMMON CODING

    # Init reporting file
    $odir = $ADHC_TempDirectory + $ADHC_GitPushAll.Directory
    New-Item -ItemType Directory -Force -Path $odir | Out-Null
    $tempfile = $odir + $ADHC_GitPushAll.Name

    Set-Content $tempfile $Scriptmsg -force

    foreach ($entry in $InitObj.MessageList){
        Report $entry.Level $entry.Message $StatusObj $Tempfile
    }

    $ENQfailed = $false 
    foreach ($msgentry in $m.MessageList) {
        $msglvl = $msgentry.level
        if ($msglvl -eq "E") {
            # ENQ failed
            $ENQfailed = $true
        }
        $msgtext = $msgentry.Message
        Report $msglvl $msgtext $StatusObj $Tempfile
    }
    
    if ($ENQfailed) {
        throw "Could not lock resource 'Git'"
    }
    
    # Init log
    $dir = $ADHC_TempDirectory + $ADHC_GitPushLog.Directory
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $templog = $dir + $ADHC_GitPushLog.Name

    $deflog = $ADHC_OutputDirectory + $ADHC_GitPushLog.Directory + $ADHC_GitPushLog.Name 
    $defdir = $ADHC_OutputDirectory + $ADHC_GitPushLog.Directory 

    $lt = Test-Path $deflog
    if (!$lt) {
        New-Item -ItemType Directory -Force -Path $defdir | Out-Null
        Set-Content $deflog " " -force
    } 

    # Copy current log to templog
    $CopMov = & $ADHC_CopyMoveScript $deflog $templog "COPY" "REPLACE" $TempFile 

    Set-Location -Path $ADHC_DevelopDir
    $gitdirs = Get-ChildItem "*.git"  -Force -Directory
        
    $line = "=".PadRight(120,"=")

    Report "N" "" $StatusObj $Tempfile
    $a = & git --version
    $msg = "GIT version: $a" 
    Report "I" $msg $StatusObj $Tempfile
    Report "N" "" $StatusObj $Tempfile
    
    foreach ($gitentry in $gitdirs) {
        $gdir = $gitentry.FullName
                
        Report "N" "" $StatusObj $Tempfile
        $msg = "----------Directory $gdir".PadRight(120,"-") 
        Report "N" $msg $StatusObj $Tempfile

        Set-Location $gdir
        Write-Host ">>> $gdir"  
        
        $ErrorActionPreference = "Continue"      
             
        $g = & {git push ADHCentral master} 6>&1 5>&1 4>&1 3>&1 2>&1 | Tee-Object -Variable a 
       
        $ErrorActionPreference = "Stop" 
                     
        Report "N" " " $StatusObj $Tempfile
        Report "B" "git push ADHCentral master" $StatusObj $Tempfile
        Report "N" $line $StatusObj $Tempfile
        Report "B" "==> Start of GIT output" $StatusObj $Tempfile
                
        foreach ($l in $a) {
            Report "G" $l $StatusObj $Tempfile
        }
                
        Report "B" "==> End of GIT output" $StatusObj $Tempfile
        Report "N" $line  $StatusObj $Tempfile

        if (($a -like "*error:*") -or ($a -like "*fatal:*")) {
            Report "W" "==> Push failed" $StatusObj $Tempfile
            WriteLog "Push ADHCentral FAILED" $gdir $StatusObj $Templog
        }
        else {
        
            if ($a -like "*Everything up-to-date*") {
                Report "I" "==> Nothing to push" $StatusObj $Tempfile
            } 
            else {
                Report "C" "==> Push executed" $StatusObj $Tempfile
                WriteLog "ADHCentral Pushed" $gdir $StatusObj $Templog
            }
        }
        
        Report "N" " "   $StatusObj $Tempfile
        
        $ErrorActionPreference = "Continue" 

        $g = & {git push GITHUB master} 6>&1 5>&1 4>&1 3>&1 2>&1 | Tee-Object -Variable a 

        $ErrorActionPreference = "Stop" 

        Report "N" " " $StatusObj $Tempfile
        Report "B" "git push GITHUB master" $StatusObj $Tempfile
        Report "N" $line $StatusObj $Tempfile
        Report "B" "==> Start of GIT output" $StatusObj $Tempfile
        
        foreach ($l in $a) {
            Report "G" $l $StatusObj $Tempfile
        }
        Report "B" "==> End of GIT output" $StatusObj $Tempfile
        Report "N" $line  $StatusObj $Tempfile

        if (($a -like "*error:*") -or ($a -like "*fatal:*")) {
            Report "W" "==> Push failed" $StatusObj $Tempfile
            WriteLog "Push GITHUB FAILED" $gdir $StatusObj $Templog
        }
        else {
            if ($a -like "*Everything up-to-date*") {
                Report "I" "==> Nothing to push" $StatusObj $Tempfile
            } 
            else {
                Report "C" "==> Push executed" $StatusObj $Tempfile
                WriteLog "GITHUB Pushed" $gdir $StatusObj $Templog
            } 
        }       
        Report "N" " " $StatusObj $Tempfile
                
    }

    #Set-Location -Path $ADHC_RemoteDir
    #$remdirs = Get-ChildItem "*.git" -Force -Directory

    #foreach ($rementry in $remdirs) {
    #    $rdir = $rementry.FullName
    #    
    #    Report "N" "" $StatusObj $Tempfile
    #    $msg = "----------Remote Repository $rdir".PadRight(120,"-") 
    #    Report "N" $msg $StatusObj $Tempfile
    #
    #    Set-Location $rdir
    #    Write-Host ">>> $rdir"
    #
    #    
    #}  
            
}
catch {
    $StatusObj.scripterror = $true
    
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    $Dump = $_.Exception.ToString()
}
finally {
    # Copy temp log to definitive BEFORE DEQ
    if ($StatusObj.recordslogged) {
        $CopMov = & $ADHC_CopyMoveScript  $Templog $deflog "MOVE" "REPLACE" $TempFile 
    }
    else {
        Report "I" "No records logged, delete $templog without copy-back" $StatusObj $Tempfile
        Remove-Item $templog
    }

    $m = & $ADHC_LockScript "Free" "Git" "$enqprocess" 10 "OBJECT"
    foreach ($msgentry in $m.MessageList) {
        $msglvl = $msgentry.level
        $msgtext = $msgentry.Message
        Report $msglvl $msgtext $StatusObj $Tempfile
    }
    # Init jobstatus file
    $jdir = $ADHC_OutputDirectory + $ADHC_Jobstatus
    New-Item -ItemType Directory -Force -Path $jdir | Out-Null
    $p = $myname.Split(".")
    $process = $p[0]
    $jobstatus = $ADHC_OutputDirectory + $ADHC_Jobstatus + $ADHC_Computer + "_" + $Process + ".jst" 
    
    Report "N" " " $StatusObj $Tempfile

    $returncode = 99

    if ($ENQfailed) {
        $msg = ">>> Script could not run"
        Report "E" $msg $StatusObj $Tempfile
        Report "N" " " $StatusObj $Tempfile
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "7" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        Add-Content $jobstatus "Failed item = $FailedItem"
        Add-Content $jobstatus "Errormessage = $ErrorMessage"
        Add-Content $jobstatus "Dump info = $dump"

        Report "E" "Failed item = $FailedItem" $StatusObj $Tempfile
        Report "E" "Errormessage = $ErrorMessage" $StatusObj $Tempfile
        Report "E" "Dump info = $dump" $StatusObj $Tempfile
        $returncode = 12        

    }

        
    if (($StatusObj.scripterror) -and ($returncode -eq 99)) {
        $msg = ">>> Script ended abnormally"
        Report "E" $msg $StatusObj $Tempfile
        Report "N" " " $StatusObj $Tempfile
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "9" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        Add-Content $jobstatus "Failed item = $FailedItem"
        Add-Content $jobstatus "Errormessage = $ErrorMessage"
        Add-Content $jobstatus "Dump info = $dump"

        Report "E" "Failed item = $FailedItem" $StatusObj $Tempfile
        Report "E" "Errormessage = $ErrorMessage" $StatusObj $Tempfile
        Report "E" "Dump info = $dump" $StatusObj $Tempfile
        $returncode = 16       
    }   
    
   
    if (($StatusObj.scriptaction) -and ($returncode -eq 99)) {
        $msg = ">>> Script ended normally with action required"
        Report "W" $msg $StatusObj $Tempfile
        Report "N" " " $StatusObj $Tempfile
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "6" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode = 8
    }

    if (($StatusObj.scriptchange) -and ($returncode -eq 99)) {
        $msg = ">>> Script ended normally with reported changes, but no action required"
        Report "C" $msg $StatusObj $Tempfile
        Report "N" " " $StatusObj $Tempfile
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "3" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode = 4
    }
    if ($returncode -eq 99) {
        $msg = ">>> Script ended normally without reported changes, and no action required"
        Report "I" $msg $StatusObj $Tempfile
        Report "N" " " $StatusObj $Tempfile
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "0" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode = 0
    }
    
    try { # Free resource and copy temp file
        
        $deffile = $ADHC_OutputDirectory + $ADHC_GitPushAll.Directory + $ADHC_GitPushAll.Name 
        $CopMov = & $ADHC_CopyMoveScript $TempFile $deffile "MOVE" "REPLACE" $TempFile "GIT,$enqprocess"  
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
