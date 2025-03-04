﻿$Version = " -- Version: 4.5.3"

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

# ------------------ FUNCTIONS

# Generic delete function

function DeleteNow([string]$action, [string]$tobedeleted, [string]$delname, [System.Collections.ArrayList]$filter, [object]$Obj0, [string]$file0, [string]$log0) {

    $included = $false
    $excluded = $false
    $inclall = $false
    $exclall = $false
    foreach ($entry in $filter) {        
        # Inlcuded by name prevails, so stop searching directly
        if ($entry.includes.ToUpper() -contains $delname.ToUpper()) {
            $included = $true
            $process = $entry.process.ToUpper()
            $thisdelay = $entry.delay            
            break
        }
        # Excluded by name: skip this filter
        if ($entry.excludes.ToUpper() -contains $delname.ToUpper()) {
            $excluded = $true
            $included = $false
            continue
        }
        # if not excluded by name, include *ALL* takes preference
        if ($entry.includes.ToUpper() -contains "*ALL*") {
            $inclall = $true
            $process = $entry.process.ToUpper()
            $thisdelay = $entry.delay            
            continue
            
        }
        # at last we look at excluded *ALL*. It just means that the module had a "hit"
        if ($entry.excludes.ToUpper() -contains "*ALL*") {
            $exclall = $true
         
        }
                            
    }

    if (($delname -match "\w+\.?\w*" ) -or ($delname -match "#\w+\.?\w*")) {
        if (!($included -or $inclall -or $excluded -or $exclall) ) {
            Report "W" "Module $delname ($tobedeleted) has no corresponding INCLUDE statement for $action - processing wil be SKIPPED" $Obj0 $file0
            return
        }
        else {
            if (!($included -or $inclall)) {
                Write-Host "Module $delname ($tobedeleted) EXCLUDED for $action - processing wil be SKIPPED"
                return
            }
        }
    } 
    else {
        $w = "Delname validation failed '" +  $delname + "'"
        write-error $w
        
    }
    
    Write-Host "$action $tobedeleted with process $process and delay $thisdelay"

    if ($process.ToUpper() -eq "WINDOWSSCHEDULER") {
        $xmlext = [System.IO.Path]::GetExtension("$tobedeleted")
        if ($xmlext.ToUpper() -eq ".XML") {
            $xmlvalid = $true
            $xml = [xml](Get-Content "$tobedeleted") 
        }
        else {
            $xmlvalid = $false
            $xmlname = $tobedeleted
        }
    }

    if (($action.ToUpper() -eq "VALIDATE") -and ($process.ToUpper() -eq "NONE")) {
        $action = "DELETE"
        Report "C" "Deletion of file $tobedeleted will be initiated because process = $process" $Obj0 $file0
    } 
    if (($action.ToUpper() -eq "VALIDATE") -and ($process.ToUpper() -eq "IGNORE")) {
        
        return
    } 

    if ($action.ToUpper() -eq "DELETE") {
        If ($process.ToUpper() -eq "IGNORE") {
            Report "I" "FIle $tobedeleted has process $process and will NOT be deleted" $Obj0 $file0
            return
        }
        if ($thisdelay -gt 0) {
            $action = "DELETEX"
        }
        # $tobedeleted
        if ($delname.ToUpper().Contains("#ADHC_DELETED_")) {
            $action = "DELETED"
        }
    }
    # $action
           
    switch ($action.ToUpper()) {
        "VALIDATE" {return} 
        "DELETE" { 
            Report "C" "Module $tobedeleted will be deleted directly from computer $ADHC_Computer" $Obj0 $file0
            Remove-Item "$tobedeleted" -force
            WriteLog "Directly DELETED" $tobedeleted $log0 $obj0
        }
        "DELETED" {            
            $delyear = $delname.Substring(14,4)
            $delmonth = $delname.Substring(18,2)
            $delday = $delname.Substring(20,2)
            # $delyear
            # $delmonth
            # $delday
            $deldate = Get-Date -Year $delyear -Month $delmonth -Day $delday
            $curdate = Get-Date
            $diff = NEW-TIMESPAN –Start $deldate –End $curDate
            if ($diff.Days -GE $thisdelay) {
                # dataset kan be deleted now
                Report "C" "Renamed module $tobedeleted will be deleted directly from computer $ADHC_Computer (Delay $thisdelay has elapsed)" $Obj0 $file0
                Remove-Item "$tobedeleted" -force
               
                WriteLog "Deferred DELETED" $tobedeleted $log0 $obj0 
            }
            else {
                $wt = $thisdelay - $diff.Days
                Report "I" "Renamed module $tobedeleted will be deleted from computer $ADHC_Computer in $wt days" $Obj0 $file0
                   
            }
        }
        "DELETEX" {
            # Only rename ONCE!!!
            $dt = Get-Date
            $yyyy = $dt.Year
            $mm = “{0:d2}” -f $dt.Month
            $dd = “{0:d2}” -f $dt.Day
            $splitname = $tobedeleted.Split("\")
            $nrofquals = $splitname.Count
            #nrofquals
            $lastqual = $splitname[$nrofquals-1]
            #astqual
            $deleteq= "#ADHC_deleted_" + "$yyyy" + "$mm" + "$dd" + "_" + "$lastqual"
            #deleteq
            $deletename = $tobedeleted.Replace("$Lastqual","$deleteq")
            #deletename
                        
            Report "C" "Module $tobedeleted will be renamed to $deletename and removed later from computer $ADHC_Computer" $Obj0 $file0
            Rename-Item "$tobedeleted" "$deletename" -force
            
            WriteLOg "Staged for DELETION" $tobedeleted $log0 $obj0
          
                        
        }
        Default {
            Report "E" "*** Wrong action $action encountered" $Obj0 $file0
                                
        }
    }

    # Post processing
    switch ($process.ToUpper()) {
        "COPY"   { } 
        "NONE"   { }
        "IGNORE" { } 
        "WINDOWSSCHEDULER" {
            if ($xmlvalid) {
                $TaskName = $xml.Task.RegistrationInfo.URI
                $i = $TaskName.LastIndexOf("\")
                $len = $TaskName.Length
                $TaskID = $TaskName.Substring($i+1,$len-$i-1)
                # write $TaskID
                $TaskPath = $TaskName.Substring(0,$i+1)
                # write $TaskPath
                # write $xml.Task.Principals.Principal; 
                # write $taskName; 
                # write $sourceMod.Name; 
                # write $xml.OuterXml; 
                Unregister-ScheduledTask -TaskName $TaskID -TaskPath $TaskPath -Confirm:$false
                   
                $msg = 'Scheduled task "' + $TaskName + '" unregistered now.'
                Write-Warning $msg
                Report "C" $msg $Obj0 $file0

                WriteLog "UNREGISTERED" $TaskName $log0 $obj0
            }
            else {
                Report "I" "$xmlname is not an valid XML file, $process processing skipped" $Obj0 $file0
                    
            }
              
        }
        default    {
            Report "E" "*** Wrong deploy process $process encountered" $Obj0 $file0
                
        }
    }
}

# Generic COPY function

function DeployNow([string]$action, [string]$shortname, [string]$from, [string]$to, [System.Collections.ArrayList]$filter, [object]$Obj0, [string]$file0, [string]$log0) {

    $included = $false
    $excluded = $false
    $inclall = $false
    $exclall = $false
    foreach ($entry in $filter) {        
        # Inlcuded by name prevails, so stop searching directly
        if ($entry.includes.ToUpper() -contains $shortname.ToUpper()) {
            $included = $true
            $process = $entry.process.ToUpper()
            $delay = $entry.delay            
            break
        }
        # Excluded by name: skip this filter
        if ($entry.excludes.ToUpper() -contains $shortname.ToUpper()) {
            $excluded = $true
            $included = $false
            continue
        }
        # if not excluded by name, include *ALL* takes preference
        if ($entry.includes.ToUpper() -contains "*ALL*") {
            $inclall = $true
            $process = $entry.process.ToUpper()
            $delay = $entry.delay            
            continue
            
        }
        # at last we look at excluded *ALL*. It just means that the module had a "hit"
        if ($entry.excludes.ToUpper() -contains "*ALL*") {
            $exclall = $true
         
        }
                            
    }
    
    if (($shortname -match "\w+\.?\w*" ) -or ($shortname -match "#\w+\.?\w*")) {
        if (!($included -or $inclall -or $excluded -or $exclall))  {
            Report "W" "Module $shortname ($to)has no corresponding INCLUDE statement for $action - processing wil be SKIPPED" $Obj0 $file0
            return
        }
        else {
            if (!($included -or $inclall)) {
                Write-Host "Module $shortname ($to) EXCLUDED for $action - processing wil be SKIPPED"
                return
            }
        }
    }         
    else {
        $w = "Shortname validation failed '" +  $shortname + "'"
        write-error $w
        
    }    

    if ($from.ToUpper().Contains("#ADHC_DELETED_")) {
        Report "I" "No $action action taken for deleted file $from" $Obj0 $file0
        return
    }
    
    Write-Host "$action $from TO $to using process $process with delay of $delay days"
    $currentdate = Get-Date
    $fromprop = Get-ItemProperty $from
    $timeDifference = New-TimeSpan –Start $fromprop.LastWriteTime –End $currentDate
    If ($timeDifference.Days -ge $delay) {
        $copyme = $true
    }
    else {
        $waitTime = $delay - $timeDifference.Days
        $copyme = $false
    }
    
    switch ($action.ToUpper()) {
        "ADD" {
            if ($process.ToUpper() -eq "NONE")  {
                return                               #no action!
            }
            if ($process.ToUpper() -eq "IGNORE")  {
                Report "W" "Module $from should not exist because process is $process. ADD function aborted" $Obj0 $file0
                return                               #no action!
            }
            if ($copyme) {            
                $dirbase = Split-Path -Path $to 
                $td = Test-Path $dirbase
                if (!$td) {
                    Report "C" "Directory $dirbase does not exist and will be created on computer $ADHC_COmputer prior to COPY/ADD" $Obj0 $file0
                
                    New-Item -ItemType Directory -Force -Path "$dirbase"
                    Writelog "CREATED" $dirbase $log0 $obj0
                }

                Report "C" "Module $to does not exist and will be added to computer $ADHC_Computer" $Obj0 $file0

                Copy-Item "$from" "$to" -force 
                
                Writelog "ADDED" $to $log0 $obj0
            }
            else {
                Report "I" "Module $from will be copied to $to in $waitTime days" $Obj0 $file0
                   
            }
            
        }
        "REPLACE" {
            if ($process.ToUpper() -eq "NONE") {
                Report "C" "Module $to should not be there, because process = $process. Deletion will be initiated" $Obj0 $file0
                return
            }   
            if ($process.ToUpper() -eq "IGNORE") {
                Report "W" "Module $from should not be there, because process = $process" $Obj0 $file0
                return
            }                
            if ($copyme) {
                Report "C" "Module $to has been updated and will be replaced on computer $ADHC_Computer" $Obj0 $file0
                Copy-Item "$from" "$to" -force 
                
                WriteLog "REPLACED" $to $log0 $obj0
            }
            else {
                Report "I" "Module $from will replace $to in $waitTime days" $Obj0 $file0
                    
            } 
            
        }
        Default {
            Report "E" "*** Wrong action $action encountered" $Obj0 $file0
                
        }
    }

    # Post processing
    switch ($process.ToUpper()) {
        "COPY"   { } 
        "WINDOWSSCHEDULER" {
            $xmlext = [System.IO.Path]::GetExtension("$from")
            if ($xmlext.ToUpper() -eq ".XML") {
                $xmlvalid = $true
                $xml = [xml](Get-Content "$from"); 
            }
            else {
                $xmlvalid = $false
            }
            if ($xmlvalid) {       
                $Author = $xml.task.RegistrationInfo.Author; 
                if (($Author) -and ($Author.Length -ge 7)) { 
                    # write $Author.substring(0,6); 
                    if  ($Author.substring(0,6) -eq '$ADHC_'){ 
                        $xml.task.RegistrationInfo.Author = Invoke-Expression($Author); 
                    }; 
                    # write $xml.task.RegistrationInfo.Author 
                }

                $Createdate = $xml.task.RegistrationInfo.Date; 
                if ($Createdate) { 
                    # write $Author.substring(0,6); 
                    if  ($Createdate.substring(0,6) -eq '$ADHC_'){ 
                        $xml.task.RegistrationInfo.Date = Invoke-Expression($Createdate); 
                    }; 
                    # write $xml.task.RegistrationInfo.Author 
                }


                $Userid = $xml.task.Triggers.LogonTrigger.UserId ; 
                if (($Userid) -and ($userid.Length -ge 7)) { 
                    # write $Userid.substring(0,6); 
                    if  ($Userid.substring(0,6) -eq '$ADHC_'){ 
                        $xml.task.Triggers.LogonTrigger.UserId = Invoke-Expression($Userid); 
                    }; 
                    # write $xml.task.RegistrationInfo.Userid 
                }

                $Userid = $xml.task.Principals.Principal.Userid ; 
                if (($Userid) -and ($userid.Length -ge 7)) { 
                    # write $Userid.substring(0,6); 
                    if  ($Userid.substring(0,6) -eq '$ADHC_'){ 
                        $xml.task.Principals.Principal.Userid = Invoke-Expression($Userid); 
                    }; 
                    # write $xml.task.Principals.Principal.Userid 
                }

                $StartTime = $xml.task.Triggers.CalendarTrigger.StartBoundary ; 
                if ($StartTime) { 
                    # write $StartTime.substring(0,6); 
                    if  ($StartTime.substring(0,6) -eq '$ADHC_'){ 
                        $xml.task.Triggers.CalendarTrigger.StartBoundary = Invoke-Expression($StartTime); 
                    }; 
                    # write $xml.task.Triggers.CalendarTrigger.StartBoundary 
                }

                $PythonExec = $xml.task.Actions.Exec.Command ; 
                if (($PythonExec) -and ($PythonExec.Length -ge 7)) { 
                    # write $PythonExec.substring(0,6); 
                    if  ($PythonExec.substring(0,6) -eq '$ADHC_'){ 
                        $xml.task.Actions.Exec.Command = Invoke-Expression($PythonExec); 
                    }; 
                    # write $xml.task.Actions.Exec.Command 
                }

                $PythonArguments = $xml.task.Actions.Exec.Arguments ; 
                if (($PythonArguments) -and ($PythonArguments.Length -ge 7)) { 
                    # write $PythonExec.substring(0,6); 
                    if  ($PythonArguments.substring(0,6) -eq '$ADHC_'){ 
                        $xml.task.Actions.Exec.Arguments = Invoke-Expression($PythonArguments); 
                    }; 
                    # write $xml.task.Actions.Exec.Command 
                }

                $TaskName = $xml.Task.RegistrationInfo.URI; 
                # write $xml.Task.Principals.Principal; 
                # write $taskName; 
                # write $sourceMod.Name; 
                # write $xml.OuterXml; 
                Register-ScheduledTask -Xml $xml.OuterXml -TaskName $TaskName -Force; 
                    
                $msg = "Scheduled task '" + $taskName + "' registered now."
                Report "C" $msg $Obj0 $file0
                
                WriteLog "REGISTERED" $taskname $log0 $obj0
            }
            else {
                Report "I" "$from is not an valid XML file, $process processing skipped" $Obj0 $file0
                    
            }

        }
        default    {
            Report "E" "*** Wrong deploy process $process encountered" $Obj0 $file0
                
        }
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

function WriteLog ([string]$Action, [string]$line, [string]$logfile, [object]$obj) {
    $oldrecords = Get-Content $logfile

    $logdate = Get-Date
    $logrec = $logdate.ToSTring("yyyy-MMM-dd HH:mm:ss").PadRight(24," ") + $ADHC_Computer.PadRight(24," ") +
                    (" *** " + $Action + " *** ").Padright(40," ") + $line.PadRight(160," ") + $logdate.ToString("dd-MM-yyyy HH:mm:ss")
    Set-Content $logfile $logrec
    $obj.recordslogged = $true

    $now = Get-Date

    $nrofnotkeep = 0

    foreach ($record in $oldrecords) {
        $keeprecord = $false
        if ($record.Length -ge 248) {
            $dtstring = $record.Substring(248)
            #$dtstring
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

# ------------------------ END OF FUNCTIONS

# ------------------------ START OF MAIN CODE

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
    $m = & $ADHC_LockScript "Lock" "Deploy" "$enqprocess" 10 "OBJECT"  
   
# END OF COMMON CODING   

    # Init reporting file
    $dir = $ADHC_TempDirectory + $ADHC_DeployExec.Directory
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $tempfile = $dir + $ADHC_DeployExec.Name

    Set-Content $Tempfile $Scriptmsg -force

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
        throw "Could not lock resource 'Deploy'"
    }

    # Init log
    $ldir = $ADHC_TempDirectory + $ADHC_DeployLog.Directory
    New-Item -ItemType Directory -Force -Path $ldir | Out-Null
    $templog = $ldir + $ADHC_DeployLog.Name

    $deflog = $ADHC_OutputDirectory + $ADHC_DeployLog.Directory + $ADHC_DeployLog.Name 
    $defdir = $ADHC_OutputDirectory + $ADHC_Deploylog.Directory 

    $lt = Test-Path $deflog
    if (!$lt) {
        New-Item -ItemType Directory -Force -Path $defdir | Out-Null
        Set-Content $deflog " " -force
    } 

    # Copy current log to templog
    $CopMov = & $ADHC_CopyMoveScript $deflog $templog "COPY" "REPLACE" $TempFile 


    # Locate staging library and get all staging folders in $stagingdirlist

    Set-Location "$ADHC_StagingDir"
    $stagingdirlist = Get-ChildItem -Directory  | Select-Object Name, FullName 
    # write $stagingdirlist

    # Loop through subdirs of staging lib
    foreach ($stagingdir in $stagingdirlist) {

            
        # Get all modules in this staging directory
        $staginglocation = $stagingdir.FullName + "\"        
       
        Report "N" " " $StatusObj $Tempfile
	    $msg = "Staging directory: " +  $staginglocation.PadRight(100,"-")
	    Report "H" $msg $StatusObj $Tempfile
       

        $configfile = $staginglocation + $ADHC_ConfigFile
        if (!(Test-Path $configfile)) {
            Report "W" "Configfile $configfile not found, directory skipped" $StatusObj $Tempfile
	        Continue
        } 

        [xml]$ConfigXML = Get-Content $configfile

        $configversion = $ConfigXML.ADHCinfo.Version
        Report "B" "Configuration file version = $configversion" $StatusObj $Tempfile

        # Skip this directory if not meant for this computer node
        $targetnodelist = $ConfigXML.ADHCinfo.Nodes.ToUpper().Split(",")

        if (!($targetnodelist -contains $ADHC_Computer.ToUpper())) {
            Report "I" "==> Node $ADHC_Computer dus not match nodelist {$targetnodelist}, directory skipped" $StatusObj $Tempfile	          
            Continue
        }

            # Get Staging info and process staging directory
        
        $sModules = $ConfigXml.ADHCinfo.StageLib.Childnodes
        $stagingfilter = @()
        foreach ($moduleentry in $sModules) {
            $process = $moduleentry.Process
            $delay = $moduleentry.Delay
            $includes = $moduleentry.Include.SPlit(",")
            $excludes = $moduleentry.Exclude.Split(",")
            $filter = [PSCustomObject] [ordered] @{process = $process;
                                            delay = $delay;    
                                            includes = $includes; 
                                            excludes = $excludes}
            $stagingfilter += $filter 
            
        }
        $StageContent = Get-ChildItem $staginglocation -recurse -file  | Select Name,FullName
        foreach ($stagedfile in $stageContent) {
            $mod = $stagedfile.FullName
            $sname = $stagedfile.Name
            DeleteNow "VALIDATE"  "$mod" "$sname" $stagingfilter $StatusObj $Tempfile $Templog          # Check if module should be here at all 
        }

        $x = 0
        
        $targetlist = $ConfigXml.ADHCinfo.SelectNodes("//Target")

        # Create production directory if it does not exists yet
        foreach ($targetentry in $targetlist) {
            $x = $x + 1
            $targetdir = $targetentry.Root + $targetentry.SubRoot 
            $tst = Test-Path $targetdir
            if (!$tst) {
                Report "C" "Directory $targetdir does not exist and will be created on computer $ADHC_COmputer" $StatusObj $Tempfile
                
                New-Item -ItemType Directory -Force -Path "$targetdir"
               
            }
            if ($x -le 1) { 
                Report "N" " " $StatusObj $Tempfile
                Report "H" "Processing production directory $targetdir ($x)" $StatusObj $Tempfile
            }
            else {
                Report "B" "Processing production directory $targetdir ($x)" $StatusObj $Tempfile
            }
                
        }
        
        $StageContent = Get-ChildItem $staginglocation -recurse -file  | Select Name,FullName, Length, LastWriteTime
       
        foreach ($stagedfile in $StageContent) {
            $stagedprops = Get-ItemProperty $stagedfile.FullName
            $stagedname = $stagedfile.FullName  
            $sname = $Stagedfile.Name         

            # Proces TARGET directory (multiple possible) #########################################
          
            foreach ($targetentry in $targetlist) {
              
                $titletarget = $false
                $targetdir = $targetentry.Root + $targetentry.SubRoot
            
                $tModules = $targetentry.Childnodes
                $targetfilter = @()
                foreach ($moduleentry in $tModules) {
                    $process = $moduleentry.Process
                    $delay = $moduleentry.Delay
                    $includes = $moduleentry.Include.SPlit(",")
                    $excludes = $moduleentry.Exclude.Split(",")
                    $filter = [PSCustomObject] [ordered] @{process = $process;
                                                    delay = $delay;    
                                                    includes = $includes; 
                                                    excludes = $excludes}
                    $targetfilter += $filter 
            
                }
                

                # Check if production differs from staged file
                $prodname = $stagedfile.FullName.ToUpper().Replace($staginglocation.ToUpper(),$targetdir)
                $repl1 = "\" + $sname.ToUpper()
                $repl2 = "\" + $sname
                $prodname = $prodname.Replace($repl1, $repl2)                         # restore Mixed case
                
                
                # $prodname
                if (Test-Path $prodname) {
                    $prodprops = Get-ItemProperty $prodname 
                    if (($prodprops.Length -ne $stagedprops.Length) -or ($prodprops.LastWriteTime.ToString().Trim() -ne $stagedprops.LastWriteTime.ToString().Trim())) {
                        #Report "A" "Difference found"
                    
                        DeployNow "Replace" "$sname" "$stagedname"  "$prodname" $targetfilter $StatusObj $Tempfile $Templog
                    }
                    else {
                        #Report "A" "No Difference found"
                    }
                }
                else {
                    #Report "A" "File not found"
                    DeployNow "Add" "$sname" "$stagedname" "$prodname" $targetfilter $StatusObj $Tempfile $Templog
                }



            }
            # END Target directories  ###################################

            
        }

         # Determine deletions in target directory (multiple possible)
        $x = 0
       
        foreach ($targetentry in $targetlist) {
            $x = $x + 1
            $targetdir = $targetentry.Root + $targetentry.SubRoot

            $tModules = $targetentry.Childnodes
            $targetfilter = @()
            foreach ($moduleentry in $tModules) {
                $process = $moduleentry.Process
                $delay = $moduleentry.Delay
                $includes = $moduleentry.Include.SPlit(",")
                $excludes = $moduleentry.Exclude.Split(",")
                $filter = [PSCustomObject] [ordered] @{process = $process;
                                                delay = $delay;    
                                                includes = $includes; 
                                                excludes = $excludes}
                $targetfilter += $filter 
            
            }

            Set-Location "$targetDir"
            $TargetModList = Get-ChildItem -file -recurse | Where-Object {($_.FullName -notlike "*\.git*") -and ($_.FullName -notlike "*MyExample*") } | select-object FullName,Name 
        
            foreach ($targetMod in $TargetModList) {
                $mod = $Targetmod.FullName
                $sname = $Targetmod.Name
                $stagename = $TargetMod.Fullname.ToUpper().Replace($targetDir.ToUpper(), $staginglocation)
                # $stagename
                if (Test-Path $stagename) {
                    DeleteNow "VALIDATE"  "$mod" "$sname" $targetfilter $StatusObj $Tempfile $Templog          # Check if module should be here at all 
                }
                else {
                    
                    DeleteNow "Delete"  "$mod" "$sname" $targetfilter  $StatusObj $Tempfile $Templog              
                } 
 
            }

        }


        # Get DSL info en process DSL directory (just ONE!)
        $dsldir = $ConfigXML.ADHCinfo.DSL.Root + $ConfigXML.ADHCinfo.DSL.SubRoot

        $dModules = $ConfigXml.ADHCinfo.DSL.Childnodes
        $dslfilter = @()
        foreach ($moduleentry in $dModules) {
            $process = $moduleentry.Process
            $delay = $moduleentry.Delay
            $includes = $moduleentry.Include.SPlit(",")
            $excludes = $moduleentry.Exclude.Split(",")
            $filter = [PSCustomObject] [ordered] @{process = $process;
                                            delay = $delay;    
                                            includes = $includes; 
                                            excludes = $excludes}
            $dslfilter += $filter 
            
        }
       
        $tst = Test-Path $dsldir
        if (!$tst) {
            Report "C" "Directory $dsldir does not exist and will be created on computer $ADHC_COmputer" $StatusObj $Tempfile
                
            New-Item -ItemType Directory -Force -Path "$dsldir"
               
        }
        Report "N" " " $StatusObj $Tempfile
        Report "H" "Processing DSL directory $dsldir" $StatusObj $Tempfile       

        foreach ($stagedfile in $StageContent) {
            $stagedprops = Get-ItemProperty $stagedfile.FullName
            $stagedname = $stagedfile.FullName  
            $sname = $stagedfile.Name         
                       
            # Check if DSL differs from staged file ################################################
            $DSLname = $stagedfile.FullName.ToUpper().Replace($staginglocation.ToUpper(),$dsldir)
            $repl1 = "\" + $sname.ToUpper()
            $repl2 = "\" + $sname
            $DSLname = $DSLname.Replace($repl1, $repl2)                         # restore Mixed case
               
            if (Test-Path $DSLname) {
                $DSLprops = Get-ItemProperty $DSLname 
                if (($DSLprops.Length -ne $stagedprops.Length) -or ($DSLprops.LastWriteTime.ToString().Trim() -ne $stagedprops.LastWriteTime.ToString().Trim())) {
                    #Write-Warning "Difference found"
                    DeployNow "Replace" "$sname" "$stagedname" "$dslname" $dslfilter $StatusObj $Tempfile $Templog
                }
                else {
                    #Write-Host "No Difference found"
                }
            }
            else {
                # Write-Warning "File not found"
                DeployNow "Add" "$sname" "$stagedname" "$dslname" $dslfilter $StatusObj $Tempfile $Templog
            }
            # END DSL #############################################################################
        }

       

        # Determine deletions in DSL directory
        Set-Location "$DSLDir"
      
        $DSLList = Get-ChildItem -file -recurse| select-object FullName, Name 
        $title = $false
        foreach ($DSLMod in $DSLList) {
            
            $mod = $DSLMod.FullName
            $sname = $DSLmod.Name
            $stagename = $DSLMod.Fullname.ToUpper().Replace($DSLDir.ToUpper(), $staginglocation)
            # $stagename
            if (Test-Path $stagename) {
                DeleteNow "VALIDATE"  "$mod" "$sname" $dslfilter $StatusObj $Tempfile $Templog         # Check if module should be here at all 
            }
            else {
                # Module has been deleted from staging, delete it from DSL as well, DELETEX will do a rename! 
                              
               DeleteNow "Delete"  "$mod" "$sname" $dslfilter $StatusObj $Tempfile $Templog
         

            } 
 
        }

    }
}
catch {
    write-warning "Catch"
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
        if ($templog) {
            Report "I" "No records logged, delete $templog without copy-back" $StatusObj $Tempfile
            Remove-Item $templog
        }
    }

    $m = & $ADHC_LockScript "Free" "Deploy" "$enqprocess" 10 "OBJECT"
    foreach ($msgentry in $m.MessageList) {
        $msglvl = $msgentry.level
        $msgtext = $msgentry.Message
        Report $msglvl $msgtext $StatusObj $Tempfile
    }
    # Init jobstatus file
    $dir = $ADHC_OutputDirectory + $ADHC_Jobstatus
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
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
        Report "E" ">>> Script ended abnormally" $StatusObj $Tempfile
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
        Report "W" ">>> Script ended normally with action required" $StatusObj $Tempfile
        Report "N" " " $StatusObj $Tempfile
        
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "6" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode = 8
    }

    if (($StatusObj.scriptchange) -and ($returncode -eq 99)) {
        Report "C" ">>> Script ended normally with reported changes, but no action required" $StatusObj $Tempfile
        Report "N" " " $StatusObj $Tempfile
        
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "3" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode = 4
    }

    if ($returncode -eq 99) {
        Report "I" ">>> Script ended normally without reported changes, and no action required" $StatusObj $Tempfile
        Report "N" " " $StatusObj $Tempfile
   
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "0" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode = 0
    }
    
    try { # copy temp file to definitve file
        
        $deffile = $ADHC_OutputDirectory + $ADHC_DeployExec.Directory + $ADHC_DeployExec.Name 
        $CopMov = & $ADHC_CopyMoveScript $TempFile $deffile "MOVE" "REPLACE" $TempFile "DEPLOY,$enqprocess"  
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