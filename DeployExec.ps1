$Version = " -- Version: 1.0.4"

# COMMON coding
CLS

# init flags
$global:scripterror = $false
$global:scriptaction = $false
$global:scriptchange = $false

$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"

# ------------------ FUNCTIONS

# Generic delete function

function DeleteNow([string]$action, [string]$tobedeleted, [string]$delname, [System.Collections.ArrayList]$filter) {
    $included = $false
    $modulefound = $false
    foreach ($entry in $filter) {
        if ($entry.includes.ToUpper() -contains "*ALL*") {
            $included = $true
        }
        if ($entry.includes.ToUpper() -contains $delname.ToUpper()) {
            $included = $true
        }
        if ($entry.excludes.ToUpper() -contains $delname.ToUpper()) {
            $included = $false
        }
        if ($included) {
            $process = $entry.process.ToUpper()
            $thisdelay = $entry.delay
            $modulefound = $true
            break
        }
            
    }
    if (!$modulefound) {
        Report "W" "Module $delname has no corresponding INCLUDE statement - processing wil be SKIPPED"
        return
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

    if (($action.ToUpper() -eq "CHECKNONE") -and ($process.ToUpper() -eq "NONE")) {
        $action = "DELETE"
        Report "C" "Deletion of file $tobedeleted will be initiated because process = $process"
    } 

    if ($action.ToUpper() -eq "DELETE") {
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
        "CHECKNONE" {return} 
        "DELETE" { 
            Report "C" "Module $tobedeleted will be deleted directly from computer $ADHC_Computer"
            Remove-Item "$tobedeleted" -force
            $logdate = Get-Date
            $logrec = $logdate.ToSTring().PadRight(24," ") + " *** Directly DELETED *** ".Padright(40," ")+ $tobedeleted
            Add-Content $log $logrec
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
                Report "C" "Renamed module $tobedeleted will be deleted directly from computer $ADHC_Computer (Delay $thisdelay has elapsed)"
                Remove-Item "$tobedeleted" -force
                    
                $logdate = Get-Date
                $logrec = $logdate.ToString().PadRight(24," ") + " *** Deferred DELETED *** ".Padright(40," ")+ $tobedeleted
                Add-Content $log $logrec
            }
            else {
                $wt = $thisdelay - $diff.Days
                Report "I" "Renamed module $tobedeleted will be deleted from computer $ADHC_Computer in $wt days"
                   
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
                        
            Report "C" "Module $tobedeleted will be renamed to $deletename and removed later from computer $ADHC_Computer"
            Rename-Item "$tobedeleted" "$deletename" -force
               
            $logdate = Get-Date
            $logrec = $logdate.ToString().PadRight(24," ") + " *** Staged for DELETION *** ".Padright(40," ")+ $tobedeleted
            Add-Content $log $logrec
          
                        
        }
        Default {
            Report "E" "*** Wrong action $action encountered"
                                
        }
    }

    # Post processing
    switch ($process.ToUpper()) {
        "COPY"   { } 
        "NONE"   { }
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
                Report "C" $msg

                $logdate = Get-Date
                $logrec = $logdate.ToString().PadRight(24," ") + " *** UNREGISTERED *** ".Padright(40," ")+ $TaskName
                Add-Content $log $logrec
            }
            else {
                Report "I" "$xmlname is not an valid XML file, $process processing skipped"
                    
            }
              
        }
        default    {
            Report "E" "*** Wrong deploy process $process encountered"
                
        }
    }
}

# Generic COPY function

function DeployNow([string]$action, [string]$shortname, [string]$from, [string]$to, [System.Collections.ArrayList]$filter) {
    $modulefound = $false
    foreach ($entry in $filter) {
        if ($entry.includes.ToUpper() -contains "*ALL*") {
            $included = $true
        }
        if ($entry.includes.ToUpper() -contains $shortname.ToUpper()) {
            $included = $true
        }
        if ($entry.excludes.ToUpper() -contains $shortname.ToUpper()) {
            $included = $false
        }
        if ($included) {
            $process = $entry.process.ToUpper()
            $delay = $entry.delay
            $modulefound = $true
            break
        }
            
    }
    if (!$modulefound) {
        Report "W" "Module $shortname has no corresponding INCLUDE statement - processing wil be SKIPPED"
        return
    } 

    if ($from.ToUpper().Contains("#ADHC_DELETED_")) {
        Report "I" "No $action action taken for deleted file $from"
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
            if ($process.ToUpper() -eq "NONE") {
                return                               #no action!
            }
            if ($copyme) {            
                Report "C" "Module $to does not exist and will be added to computer $ADHC_Computer"
                Copy-Item "$from" "$to" -force
                    
                $logdate = Get-Date
                $logrec = $logdate.ToString().PadRight(24," ") + " *** ADDED *** ".Padright(40," ")+ $to
                Add-Content $log $logrec
            }
            else {
                Report "I" "Module $from will be copied to $to in $waitTime days"
                   
            }
            
        }
        "REPLACE" {
            if ($process.ToUpper() -eq "NONE") {
                Report "C" "Module $to should not be there, because process = $process. Deletion will be initiated"
                return
            }               
            if ($copyme) {
                Report "C" "Module $to has been updated and will be replaced on computer $ADHC_Computer"
                Copy-Item "$from" "$to" -force
                   
                $logdate = Get-Date
                $logrec = $logdate.ToString().PadRight(24," ") + " *** REPLACED *** ".Padright(40," ")+ $to
                Add-Content $log $logrec
            }
            else {
                Report "I" "Module $from will replace $to in $waitTime days"
                    
            } 
            
        }
        Default {
            Report "E" "*** Wrong action $action encountered"
                
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
                if ($Author) { 
                    # write $Author.substring(0,6); 
                    if  ($Author.substring(0,6) -eq '$ADHC_'){ 
                        $xml.task.RegistrationInfo.Author = Invoke-Expression($Author); 
                    }; 
                    # write $xml.task.RegistrationInfo.Author 
                }


                $Userid = $xml.task.Triggers.LogonTrigger.UserId ; 
                if ($Userid) { 
                    # write $Userid.substring(0,6); 
                    if  ($Userid.substring(0,6) -eq '$ADHC_'){ 
                        $xml.task.Triggers.LogonTrigger.UserId = Invoke-Expression($Userid); 
                    }; 
                    # write $xml.task.RegistrationInfo.Userid 
                }

                $Userid = $xml.task.Principals.Principal.Userid ; 
                if ($Userid) { 
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
                if ($PythonExec) { 
                    # write $PythonExec.substring(0,6); 
                    if  ($PythonExec.substring(0,6) -eq '$ADHC_'){ 
                        $xml.task.Actions.Exec.Command = Invoke-Expression($PythonExec); 
                    }; 
                    # write $xml.task.Actions.Exec.Command 
                }

                $PythonArguments = $xml.task.Actions.Exec.Arguments ; 
                if ($PythonArguments) { 
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
                Report "C" $msg
                    
                $logdate = Get-Date
                $logrec = $logdate.ToString().PadRight(24," ") + " *** REGISTERED *** ".Padright(40," ") + $taskname
                Add-Content $log $logrec
            }
            else {
                Report "I" "$from is not an valid XML file, $process processing skipped"
                    
            }

        }
        default    {
            Report "E" "*** Wrong deploy process $process encountered"
                
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
        default {
            $rptline = "Error   *".Padright(10," ") + "Messagelevel $level is not valid"
            $global:scripterror = $true
        }
    }
    Add-Content $Report $rptline

}

# ------------------------ END OF FUNCTIONS

# ------------------------ START OF MAIN CODE

try {
    $Node = " -- Node: " + $env:COMPUTERNAME
    $d = Get-Date
    $Datum = " -- Date: " + $d.ToShortDateString()
    $Tijd = " -- Time: " + $d.ToShortTimeString()

    $myname = $MyInvocation.MyCommand.Name
    $FullScriptName = $MyInvocation.MyCommand.Definition
    $mypath = $FullScriptName.Replace($MyName, "")

    $Scriptmsg = "Directory " + $mypath + " -- PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node
    Write-Information $Scriptmsg 

    $LocalInitVar = $mypath + "InitVar.PS1"
    & "$LocalInitVar"
   
# END OF COMMON CODING   

    # Init reporting file
    $str = $ADHC_DeployReport.Split("\")
    $dir = $ADHC_OutputDirectory + $str[0]
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $Report = $ADHC_OutputDirectory + $ADHC_DeployReport
    Set-Content $Report $Scriptmsg -force

    # Init log
    $str = $ADHC_DeployLog.Split("\")
    $dir = $ADHC_OutputDirectory + $str[0]
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $log = $ADHC_OutputDirectory + $ADHC_Deploylog

    # Locate staging library and get all staging folders in $stagingdirlist

    Set-Location "$ADHC_StagingDir"
    $stagingdirlist = Get-ChildItem -Directory  | Select-Object Name, FullName 
    # write $stagingdirlist

    # Loop through subdirs of staging lib
    foreach ($stagingdir in $stagingdirlist) {

            
        # Get all modules in this staging directory
        $staginglocation = $stagingdir.FullName + "\"        
       
        Report "N" " "
	    $msg = "---------- Staging directory: " +  $staginglocation.PadRight(100,"-")
	    Report "N" $msg
       

        $configfile = $staginglocation + $ADHC_ConfigFile
        if (!(Test-Path $configfile)) {
            Report "W" "Configfile $configfile not found, directory skipped"
	        Continue
        } 
        else {
            [xml]$ConfigXML = Get-Content $configfile

            $configversion = $ConfigXML.ADHCinfo.Version
            Report "B" "Configuration file version = $configversion"

            # Skip this directory if not meant for this computer node
            $targetnodelist = $ConfigXML.ADHCinfo.Nodes.ToUpper().Split(",")

            if (!($targetnodelist -contains $ADHC_Computer.ToUpper())) {
                Report "I" "==> Node $ADHC_Computer dus not match nodelist {$targetnodelist}, directory skipped"
	            
                Continue
            }

             # Get Staging info
        
            $sModules = $ConfigXml.ADHCinfo.StageLib.Childnodes
            $stagingfilter = @()
            foreach ($moduleentry in $sModules) {
                $process = $moduleentry.Process
                $delay = $moduleentry.Delay
                $includes = $moduleentry.Include.SPlit(",")
                $excludes = $moduleentry.Exclude.Split(",")
                $filter = [PSCustomObject] [ordered] @{process = $process;
                                                delay = $delay;    
                                                includes = $includes 
                                                excludes = $excludes}
                $stagingfilter += $filter 
            
            }
       
            # Get TARGET info
            $targetdir = $ConfigXML.ADHCinfo.Target.Root + $ConfigXML.ADHCinfo.Target.SubRoot
            
            $tModules = $ConfigXml.ADHCinfo.Target.Childnodes
            $targetfilter = @()
            foreach ($moduleentry in $tModules) {
                $process = $moduleentry.Process
                $delay = $moduleentry.Delay
                $includes = $moduleentry.Include.SPlit(",")
                $excludes = $moduleentry.Exclude.Split(",")
                $filter = [PSCustomObject] [ordered] @{process = $process;
                                                delay = $delay;    
                                                includes = $includes 
                                                excludes = $excludes}
                $targetfilter += $filter 
            
            }
            
            # Get DSL info
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
                                                includes = $includes 
                                                excludes = $excludes}
                $dslfilter += $filter 
            
            }

            
            
            # Create production directory if it does not exits yet
            $x = Test-Path $targetdir
            if (!$x) {
                Report "C" "Directory $targetdir does not exist and will be created on computer $ADHC_COmputer"
                
                New-Item -ItemType Directory -Force -Path "$targetdir"
               
            }
            else {
                Report "B" "Processing production directory $targetdir"
                
            }
        
            # Create DSL directory if it does not exits yet
            $x = Test-Path $dsldir
            if (!$x) {
                Report "C" "Directory $dsldir does not exist and will be created on computer $ADHC_Computer"
               
                New-Item -ItemType Directory -Force -Path "$dsldir"
                
            }
             else {
                Report "B" "Processing DSL directory $dsldir"
                
            }
        }

        $StageContent = Get-ChildItem $staginglocation -recurse -file  | Select Name,FullName
        foreach ($stagedfile in $stageContent) {
            $mod = $stagedfile.FullName
            $sname = $stagedfile.Name
            DeleteNow "CheckNone"  "$mod" "$sname" $stagingfilter           # Check if module should be here at all 
        }

        $StageContent = Get-ChildItem $staginglocation -recurse -file  | Select Name,FullName, Length, LastWriteTime
        foreach ($stagedfile in $StageContent) {
            $stagedprops = Get-ItemProperty $stagedfile.FullName
            $stagedname = $stagedfile.FullName

            # Check if production differs from staged file
            $prodname = $stagedfile.FullName.ToUpper().Replace($staginglocation.ToUpper(),$targetdir)
            $sname = $Stagedfile.Name
            # $prodname
            if (Test-Path $prodname) {
                $prodprops = Get-ItemProperty $prodname 
                if (($prodprops.Length -ne $stagedprops.Length) -or ($prodprops.LastWriteTime.ToString().Trim() -ne $stagedprops.LastWriteTime.ToString().Trim())) {
                    # Write-Warning "Difference found"
                    
                    DeployNow "Replace" "$sname" "$stagedname"  "$prodname" $targetfilter
                }
                else {
                    # Write-Host "No Difference found"
                }
            }
            else {
                # Write-Warning "File not found"
                DeployNow "Add" "$sname" "$stagedname" "$prodname" $targetfilter
            }

            # Check if DSL differs from staged file
            $DSLname = $stagedfile.FullName.ToUpper().Replace($staginglocation.ToUpper(),$dsldir)
               
            if (Test-Path $DSLname) {
                $DSLprops = Get-ItemProperty $DSLname 
                if (($DSLprops.Length -ne $stagedprops.Length) -or ($DSLprops.LastWriteTime.ToString().Trim() -ne $stagedprops.LastWriteTime.ToString().Trim())) {
                    # Write-Warning "Difference found"
                    DeployNow "Replace" "$sname" "$stagedname" "$dslname" $dslfilter
                }
                else {
                    # Write-Host "No Difference found"
                }
            }
            else {
                # Write-Warning "File not found"
                DeployNow "Add" "$sname" "$stagedname" "$dslname" $dslfilter
            }
        }

        # Determine deletions in target directory
        Set-Location "$targetDir"
        $TargetList = Get-ChildItem -file -recurse | select-object FullName,Name 
        
        foreach ($targetMod in $TargetList) {
            $mod = $Targetmod.FullName
            $sname = $Targetmod.Name
            $stagename = $TargetMod.Fullname.ToUpper().Replace($targetDir.ToUpper(), $staginglocation)
            # $stagename
            if (Test-Path $stagename) {
                DeleteNow "CheckNone"  "$mod" "$sname" $targetfilter           # Check if module should be here at all 
            }
            else {
                # Module has been deleted from staging, delete it from target as well, but ONLY if it ALSO STILL exists in DSL!!!!
                # Reason: DSL is filled with a DELAY!!!!
                $dslname = $TargetMod.Fullname.ToUpper().Replace($targetDir.ToUpper(), $dsldir)
                if (Test-Path $dslname) {
                     
                    Report "C" "Production module $targetMod.FullName is obsolete and will be deleted on computer $ADHC_Computer"
                    DeleteNow "Delete"  "$mod" "$sname" $targetfilter
                }

            } 
 
        }
    
        # Determine deletions in DSL directory
        Set-Location "$DSLDir"
        $DSLList = Get-ChildItem -file -recurse| select-object FullName, Name 
        
        foreach ($DSLMod in $DSLList) {
            $mod = $DSLMod.FullName
            $sname = $DSLmod.Name
            $stagename = $DSLMod.Fullname.ToUpper().Replace($DSLDir.ToUpper(), $staginglocation)
            # $stagename
            if (Test-Path $stagename) {
                DeleteNow "CheckNone"  "$mod" "$sname" $dslfilter           # Check if module should be here at all 
            }
            else {
                # Module has been deleted from staging, delete it from DSL as well, DELETEX will do a rename! 
                
               Report "C" "DSL module $mod is obsolete and will be deleted on computer $ADHC_Computer"
               
               DeleteNow "Delete"  "$mod" "$sname" $dslfilter
         

            } 
 
        }

    }
}
catch {
    $global:scripterror = $true
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
}
finally {
    # Init jobstatus file
    $dir = $ADHC_OutputDirectory + $ADHC_Jobstatus
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $p = $myname.Split(".")
    $process = $p[0]
    $jobstatus = $ADHC_OutputDirectory + $ADHC_Jobstatus + $ADHC_Computer + "_" + $Process + ".jst" 
    
    Report "N" " "

        
    if ($global:scripterror) {
        Report "E" ">>> Script ended abnormally"
        
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "9" + "|" + $version + "|" + $dt.ToString()
        Set-Content $jobstatus $jobline
       
        Add-Content $jobstatus "Failed item = $FailedItem"
        Add-Content $jobstatus "Ërrormessage = $ErrorMessage"
        exit 16        
    }
   
    if ($global:scriptaction) {
        Report "W" ">>> Script ended normally with action required"
        
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "6" + "|" + $version + "|" + $dt.ToString()
        Set-Content $jobstatus $jobline
       
        exit 8
    }

    if ($global:scriptchange) {
        Report "C" ">>> Script ended normally with reported changes, but no action required"
        
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "3" + "|" + $version + "|" + $dt.ToString()
        Set-Content $jobstatus $jobline
       
        exit 4
    }

    Report "I" ">>> Script ended normally without reported changes, and no action required"
   
    $dt = Get-Date
    $jobline = $ADHC_Computer + "|" + $process + "|" + "0" + "|" + $version + "|" + $dt.ToString()
    Set-Content $jobstatus $jobline
       
    exit 0
   

} 





