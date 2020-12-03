$Version = " -- Version: 5.0"

# COMMON coding
CLS
# init flags
$global:scripterror = $false
$global:scriptaction = $false
$global:scriptchange = $false

$global:recordslogged = $false

function WriteLog ([string]$Action, [string]$line) {
    $oldrecords = Get-Content $templog 

    $logdate = Get-Date
    $logrec = $logdate.ToSTring("yyyy-MMM-dd HH:mm:ss").PadRight(24," ") + $ADHC_COmputer.PadRight(24," ") +
                (" *** " + $Action + " *** ").Padright(40," ") + $line.PadRight(160," ") + $logdate.ToString("dd-MM-yyyy HH:mm:ss")
    Set-Content $templog $logrec
    $global:recordslogged = $true

    $now = Get-Date

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
        }
        if ($keeprecord) {
            Add-Content $templog $record
        }
    }

}

function Report ([string]$level, [string]$line) {
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
        ("G") {
            $rptline = "GIT:    *".Padright(10," ") + $line
        }
        default {
            $rptline = "Error   *".Padright(10," ") + "Messagelevel $level is not valid"
            $global:scripterror = $true
        }
    }
    Add-Content $tempfile $rptline

}

$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"             

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
    & "$LocalInitVar" 
    
    if (!$ADHC_InitSuccessfull) {
        # Write-Warning "YES"
        throw $ADHC_InitError
    } 
    $m = & $ADHC_LockScript "Lock" "Git" "$enqprocess"     

# END OF COMMON CODING

    # Init reporting file
    $odir = $ADHC_TempDirectory + $ADHC_GitPushAll.Directory
    New-Item -ItemType Directory -Force -Path $odir | Out-Null
    $tempfile = $odir + $ADHC_GitPushAll.Name

    Set-Content $tempfile $Scriptmsg -force
    foreach ($msgentry in $m) {
        $msglvl = $msgentry.level
        $msgtext = $msgentry.Message
        Report $msglvl $msgtext
    }
    $ENQfailed = $false 
    if ($msglvl -eq "E") {
        # ENQ failed
        $ENQfailed = $true
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
    & $ADHC_CopyMoveScript $deflog $templog "COPY" "REPLACE" $TempFile 

    Set-Location -Path $ADHC_DevelopDir
    $gitdirs = Get-ChildItem "*.git"  -Force -Directory
        
    $line = "=".PadRight(120,"=")
    
    foreach ($gitentry in $gitdirs) {
        $gdir = $gitentry.FullName
                
        Report "N" ""
        $msg = "----------Directory $gdir".PadRight(120,"-") 
        Report "N" $msg

        Set-Location $gdir
        Write-Host ">>> $gdir"  
        
        $ErrorActionPreference = "Continue"      
             
        & {git push ADHCentral master} 6>&1 5>&1 4>&1 3>&1 2>&1 | Tee-Object -Variable a 
       
        $ErrorActionPreference = "Stop" 
                     
        Report "N" " "
        Report "N" $line
        Report "I" "==> Start of GIT output"
                
        foreach ($l in $a) {
            Report "G" $l
        }
                
        Report "I" "==> End of GIT output"
        Report "N" $line 

        if (($a -like "*error:*") -or ($a -like "*fatal:*")) {
            Report "W" "==> Push failed"
            WriteLog "Push FAILED" $gdir
        }
        else {
        
            if ($a -like "*Everything up-to-date*") {
                Report "I" "==> Nothing to push"
            } 
            else {
                Report "C" "==> Push executed"
                WriteLog "Pushed" $gdir
            }
        }
        
        Report "N" " "          
    }

    Set-Location -Path $ADHC_RemoteDir
    $remdirs = Get-ChildItem "*.git" -Force -Directory

    foreach ($rementry in $remdirs) {
        $rdir = $rementry.FullName
        
        Report "N" ""
        $msg = "----------Remote Repository $rdir".PadRight(120,"-") 
        Report "N" $msg

        Set-Location $rdir
        Write-Host ">>> $rdir"

        $ErrorActionPreference = "Continue" 

        & {git push GITHUB master} 6>&1 5>&1 4>&1 3>&1 2>&1 | Tee-Object -Variable a 

        $ErrorActionPreference = "Stop" 

        Report "N" " "
        Report "N" $line
        Report "I" "==> Start of GIT output"       
        
        foreach ($l in $a) {
            Report "G" $l
        }
        Report "I" "==> End of GIT output"
        Report "N" $line 

        if (($a -like "*error:*") -or ($a -like "*fatal:*")) {
            Report "W" "==> Push failed"
            WriteLog "Push FAILED" $rdir
        }
        else {
            if ($a -like "*Everything up-to-date*") {
                Report "I" "==> Nothing to push"
            } 
            else {
                Report "C" "==> Push executed"
                WriteLog "Pushed" $rdir
            } 
        }       
        Report "N" " "
    }  
            
}
catch {
    $global:scripterror = $true
    
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    $Dump = $_.Exception.ToString()
}
finally {
    # Copy temp log to definitive BEFORE DEQ
    if ($global:recordslogged) {
        & $ADHC_CopyMoveScript  $Templog $deflog "MOVE" "REPLACE" $TempFile 
    }
    else {
        Report "I" "No records logged, delete $templog without copy-back"
        Remove-Item $templog
    }

    $m = & $ADHC_LockScript "Free" "Git" "$enqprocess"
    foreach ($msgentry in $m) {
        $msglvl = $msgentry.level
        $msgtext = $msgentry.Message
        Report $msglvl $msgtext
    }
    # Init jobstatus file
    $jdir = $ADHC_OutputDirectory + $ADHC_Jobstatus
    New-Item -ItemType Directory -Force -Path $jdir | Out-Null
    $p = $myname.Split(".")
    $process = $p[0]
    $jobstatus = $ADHC_OutputDirectory + $ADHC_Jobstatus + $ADHC_Computer + "_" + $Process + ".jst" 
    
    Report "N" " "

    $returncode = 99

    if ($ENQfailed) {
        $msg = ">>> Script could not run"
        Report "E" $msg
        Report "N" " "
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "7" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        Add-Content $jobstatus "Failed item = $FailedItem"
        Add-Content $jobstatus "Errormessage = $ErrorMessage"
        Add-Content $jobstatus "Dump info = $dump"

        Report "E" "Failed item = $FailedItem"
        Report "E" "Errormessage = $ErrorMessage"
        Report "E" "Dump info = $dump"
        $returncode = 12        

    }

        
    if (($global:scripterror) -and ($returncode -eq 99)) {
        $msg = ">>> Script ended abnormally"
        Report "E" $msg
        Report "N" " "
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "9" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        Add-Content $jobstatus "Failed item = $FailedItem"
        Add-Content $jobstatus "Errormessage = $ErrorMessage"
        Add-Content $jobstatus "Dump info = $dump"

        Report "E" "Failed item = $FailedItem"
        Report "E" "Errormessage = $ErrorMessage"
        Report "E" "Dump info = $dump"
        $returncode = 16       
    }   
    
   
    if (($global:scriptaction) -and ($returncode -eq 99)) {
        $msg = ">>> Script ended normally with action required"
        Report "W" $msg
        Report "N" " "
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "6" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode = 8
    }

    if (($global:scriptchange) -and ($returncode -eq 99)) {
        $msg = ">>> Script ended normally with reported changes, but no action required"
        Report "C" $msg
        Report "N" " "
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "3" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode = 4
    }
    if ($returncode -eq 99) {
        $msg = ">>> Script ended normally without reported changes, and no action required"
        Report "I" $msg
        Report "N" " "
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "0" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode = 0
    }

    $d = Get-Date
    $Datum = " -- Date: " + $d.ToString("dd-MM-yyyy")
    $Tijd = " -- Time: " + $d.ToString("HH:mm:ss") 
    $Scriptmsg = "*** ENDED ***** " + $mypath + " -- PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node
    Report "N" $scriptmsg
    Report "N" " "

    try { # Free resource and copy temp file
        
        $m = & $ADHC_LockScript "Free" "Git" "$enqprocess" "10" "SILENT" 
        foreach ($msgentry in $m) {
            $msglvl = $msgentry.level
            $msgtext = $msgentry.Message
            Report $msglvl $msgtext
        }

        $deffile = $ADHC_OutputDirectory + $ADHC_GitPushAll.Directory + $ADHC_GitPushAll.Name 
        & $ADHC_CopyMoveScript $TempFile $deffile "MOVE" "REPLACE" $TempFile "GIT,$enqprocess"  
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
        Write-Information $Scriptmsg 
        Exit $Returncode
        
    }  

   

}
