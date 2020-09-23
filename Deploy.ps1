$Version = " -- Version: 4.0"

# COMMON coding
CLS

$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"

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

     # init flags
    $scripterror = $false
    $scriptaction = $false
    $scriptchange = $false

# END OF COMMON CODING   

    # Init reporting file
    $str = $ADHC_DeployReport.Split("\")
    $dir = $ADHC_OutputDirectory + $str[0]
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $ofile = $ADHC_OutputDirectory + $ADHC_DeployReport
    Set-Content $ofile $Scriptmsg -force

    # Init log
    $str = $ADHC_DeployLog.Split("\")
    $dir = $ADHC_OutputDirectory + $str[0]
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $log = $ADHC_OutputDirectory + $ADHC_Deploylog

    # Generic delete function
    function DeleteNow([string]$action, [string]$tobedeleted, [string]$delname, [string]$process, [int]$thisdelay)
    {
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
        if ($thisdelay -gt 0) {
            $action = "DELETEX"
        }
        $tobedeleted
        if ($delname.ToUpper().Contains("#ADHC_DELETED_")) {
            $action = "DELETED"
        }
        # $action
           
        switch ($action.ToUpper()) {
            "DELETE" { 
                $msg = "Module " + $tobedeleted + " will be deleted directly from computer " + $ADHC_Computer
                Remove-Item "$tobedeleted" -force
                $scriptchange = $true
                Add-Content $ofile $msg
                $logdate = Get-Date
                $logrec = $logdate.ToSTring() + " *** Directly DELETED *** ".Padright(40," ")+ $tobedeleted
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
                    $msg = "Renamed module " + $tobedeleted + " will be deleted directly from computer " + $ADHC_Computer + " (Delay $thisdelay has elapsed)"
                    Remove-Item "$tobedeleted" -force
                    $scriptchange = $true
                    Add-Content $ofile $msg
                    $logdate = Get-Date
                    $logrec = $logdate.ToString() + " *** Deferred DELETED *** ".Padright(40," ")+ $tobedeleted
                    Add-Content $log $logrec
                }
                else {
                    $wt = $thisdelay - $diff.Days
                    $msg = "Renamed module " + $tobedeleted + " will be deleted from computer " + $ADHC_Computer + " in $wt days"
                    Add-Content $ofile $msg
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
                        
                $msg = "Module " + $tobedeleted + " will be renamed to " + $deletename + " and removed later from computer " + $ADHC_Computer
                Rename-Item "$tobedeleted" "$deletename" -force
                $scriptchange = $true
                Add-Content $ofile $msg
                $logdate = Get-Date
                $logrec = $logdate.ToString() + " *** Staged for DELETION *** ".Padright(40," ")+ $tobedeleted
                Add-Content $log $logrec
          
                        
            }
            Default {
                $msg = "ERROR *** Wrong action $action encountered"
                Add-Content $ofile $msg
                $scripterror = $true
                
            }
        }

        # Post processing
        switch ($process.ToUpper()) {
            "COPY"   { } 
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
                    $scriptchange = $true
                    $msg = 'Scheduled task "' + $TaskName + '" unregistered now.'
                    Write-Warning $msg
                    Add-Content $ofile $msg
                    $logdate = Get-Date
                    $logrec = $logdate.ToString() + " *** UNREGISTERED *** ".Padright(40," ")+ $TaskName
                    Add-Content $log $logrec
                }
                else {
                    $msg = "$xmlname is not an valid XML file, $process processing skipped"
                    Add-Content $ofile $msg

                }
              
            }
            default    {
                $msg = "ERROR *** Wrong deploy process $process encountered"
                Add-Content $ofile $msg
                $scripterror = $true
            }
        }
    }

    # Generic COPY function
    function DeployNow([string]$action, [string]$from, [string]$to, [string]$process, [int]$delay)
    {
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
                if ($copyme) {            
                    $msg = "Module " + $to + " does not exist and will be added to computer " + $ADHC_Computer
                    Copy-Item "$from" "$to" -force
                    $scriptchange = $true
                    Add-Content $ofile $msg
                    $logdate = Get-Date
                    $logrec = $logdate.ToString() + " *** ADDED *** ".Padright(40," ")+ $to
                    Add-Content $log $logrec
                }
                else {
                    $msg = "Module " + $from + " will be copied to " + $to + " in " + $waitTime + " days"
                    Add-Content $ofile $msg
                }
            
            }
            "REPLACE" {
                if ($copyme) {
                    $msg = "Module " + $to + " has been updated and will be replaced on computer " + $ADHC_Computer
                    Copy-Item "$from" "$to" -force
                    $scriptchange = $true
                    Add-Content $ofile $msg
                    $logdate = Get-Date
                    $logrec = $logdate.ToString() + " *** REPLACED *** ".Padright(40," ")+ $to
                    Add-Content $log $logrec
                }
                else {
                    $msg = "Module " + $from + " will replace " + $to + " in " + $waitTime + " days"
                    Add-Content $ofile $msg
                } 
            
            }
            Default {
                $msg = "ERROR *** Wrong action $action encountered"
                Add-Content $ofile $msg
                $scripterror = $true
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
                    $scriptchange = $true
                    $msg = 'Scheduled task "' + $taskName + '" registered now.';
                    Add-Content $ofile $msg
                    $logdate = Get-Date
                    $logrec = $logdate.ToString() + " *** REGISTERED *** ".Padright(40," ") + $taskname
                    Add-Content $log $logrec
                }
                else {
                    $msg = "$from is not an valid XML file, $process processing skipped"
                    Add-Content $ofile $msg

                }

            }
            default    {
                $msg = "ERROR *** Wrong deploy process $process encountered"
                Add-Content $ofile $msg
                $scripterror = $true
            }
        }
    }

    #
    # Find sources
    #

    # Locate staging library and get all staging folders in $stagingdirlist

    Set-Location "$ADHC_StagingDir"
    $stagingdirlist = Get-ChildItem -Directory  | Select-Object Name, FullName 
    # write $stagingdirlist

    # Loop through subdirs of staging lib
    foreach ($stagingdir in $stagingdirlist) {
    
        # Get all modules in this staging directory
        $staginglocation = $stagingdir.FullName + "\"        
       
        Add-Content $ofile " "
	    $msg = "==> Staging directory: "+ $staginglocation
	    Add-Content $ofile $msg

        $configfile = $staginglocation + $ADHC_ConfigFile
        if (!(Test-Path $configfile)) {
            $msg = "==> Configfile $configfile not found, directory skipped"
	        Add-Content $ofile $msg
            Continue
        } 
        else {
            [xml]$ConfigXML = Get-Content $configfile

            # Skip this directory if not meant for this computer node
            $targetnodelist = $ConfigXML.ADHCinfo.Nodes.ToUpper().Split(",")
           
        
            if (!($targetnodelist -contains $ADHC_Computer.ToUpper())) {
                $msg = "==> Node $ADHC_Computer dus not match nodelist {$targetnodelist}, directory skipped"
	            Add-Content $ofile $msg
                Continue
            }
       
            # Get TARGET info
            $targetdir = $ConfigXML.ADHCinfo.Target.Root + $ConfigXML.ADHCinfo.Target.SubRoot
            $targetdelay = $ConfigXML.ADHCinfo.Target.Delay
            $deploy = $ConfigXML.ADHCinfo.Target.Deploy
            
            # Get DSL info
            $dsldir = $ConfigXML.ADHCinfo.DSL.Root + $ConfigXML.ADHCinfo.DSL.SubRoot
            $dsldelay = $ConfigXML.ADHCinfo.DSL.Delay
            
            # Create production directory if it does not exits yet
            $x = Test-Path $targetdir
            if (!$x) {
                $msg = "      Directory " + $targetdir + " does not exist and will be created on computer " + $env:COMPUTERNAME
                Add-Content $ofile $msg
                New-Item -ItemType Directory -Force -Path "$targetdir"
                $scriptchange = $true
            }
            else {
                $msg = "      Processing production directory " + $targetdir 
                Add-Content $ofile $msg
            }
        
            # Create DSL directory if it does not exits yet
            $x = Test-Path $dsldir
            if (!$x) {
                $msg = "      Directory " + $dsldir + " does not exist and will be created on computer " + $env:COMPUTERNAME
                Add-Content $ofile $msg
                New-Item -ItemType Directory -Force -Path "$dsldir"
                $scriptchange = $true
            }
             else {
                $msg = "      Processing DSL directory " + $dsldir 
                Add-Content $ofile $msg
            }


                       

        }

        $StageContent = Get-ChildItem $staginglocation -recurse -file  | Select Name,FullName,LastWriteTime,Length 

        foreach ($stagedfile in $StageContent) {
            $stagedprops = Get-ItemProperty $stagedfile.FullName
            $stagedname = $stagedfile.FullName

            # Check if production differs from staged file
            $prodname = $stagedfile.FullName.ToUpper().Replace($staginglocation.ToUpper(),$targetdir)
           
            $prodname
            if (Test-Path $prodname) {
                $prodprops = Get-ItemProperty $prodname 
                if (($prodprops.Length -ne $stagedprops.Length) -or ($prodprops.LastWriteTime.ToString().Trim() -ne $stagedprops.LastWriteTime.ToString().Trim())) {
                    Write-Warning "Difference found"
                    DeployNow "Replace" "$stagedname" "$prodname" "$deploy" $targetdelay
                }
                else {
                    Write-Host "No Difference found"
                }
            }
            else {
                Write-Warning "File not found"
                DeployNow "Add" "$stagedname" "$prodname" "$deploy" $targetdelay
            }

            # Check if DSL differs from staged file
            $DSLname = $stagedfile.FullName.ToUpper().Replace($staginglocation.ToUpper(),$dsldir)
               
            $DSLname
            if (Test-Path $DSLname) {
                $DSLprops = Get-ItemProperty $DSLname 
                if (($DSLprops.Length -ne $stagedprops.Length) -or ($DSLprops.LastWriteTime.ToString().Trim() -ne $stagedprops.LastWriteTime.ToString().Trim())) {
                    Write-Warning "Difference found"
                    DeployNow "Replace" "$stagedname" "$dslname" "COPY" $dsldelay
                }
                else {
                    Write-Host "No Difference found"
                }
            }
            else {
                Write-Warning "File not found"
                DeployNow "Add" "$stagedname" "$dslname" "COPY" $dsldelay
            }


        }

        # Determine deletions in target directory
        Set-Location "$targetDir"
        $TargetList = Get-ChildItem -file -recurse | select-object FullName,Name 
        foreach ($targetMod in $TargetList) {
             $stagename = $TargetMod.Fullname.ToUpper().Replace($targetDir.ToUpper(), $staginglocation)
             $stagename
             if (Test-Path $stagename) {
                 # Module exists in staging, no action
             }
             else {
                 # Module has been deleted from staging, delete it from target as well, but ONLY if it ALSO STILL exists in DSL!!!!
                 $dslname = $TargetMod.Fullname.ToUpper().Replace($targetDir.ToUpper(), $dsldir)
                 if (Test-Path $dslname) {
                     $msg = "Production module " + $targetMod.FullName + " is obsolete and will be deleted on computer " + $env:COMPUTERNAME
                     Write-Warning $msg
                     $mod = $Targetmod.FullName
                     $sname = $Targetmod.Name
                     DeleteNow "Delete"  "$mod" "$sname""$deploy" $targetdelay
                 }

             } 
 
        }
    
        # Determine deletions in DSL directory
        Set-Location "$DSLDir"
        $DSLList = Get-ChildItem -file -recurse| select-object FullName, Name 
        foreach ($DSLMod in $DSLList) {
             $stagename = $DSLMod.Fullname.ToUpper().Replace($DSLDir.ToUpper(), $staginglocation)
             $stagename
             if (Test-Path $stagename) {
                 # Module exists in staging, no action
             }
             else {
                 # Module has been deleted from staging, delete it from DSL as well, DELETEX will do a rename!             
             
                $msg = "DSL module " + $DSLmod.FullName + " is obsolete and will be deleted on computer " + $env:COMPUTERNAME
                Write-Warning $msg
                $mod = $DSLMod.FullName
                $sname = $DSLmod.Name
                DeleteNow "Delete"  "$mod" "$sname" "COPY" $dsldelay 
         

             } 
 
        }

    }
}
catch {
    $scripterror = $true
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
    
    Add-Content $ofile " "

        
    if ($scripterror) {
        $msg = ">>> Script ended abnormally"
        Add-Content $ofile $msg
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "9" + "|" + $version + "|" + $dt.ToString()
        Set-Content $jobstatus $jobline
       
        Add-Content $jobstatus "Failed item = $FailedItem"
        Add-Content $jobstatus "Ërrormessage = $ErrorMessage"
        exit 16        
    }
   
    if ($scriptaction) {
        $msg = ">>> Script ended normally with action required"
        Add-Content $ofile $msg
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "6" + "|" + $version + "|" + $dt.ToString()
        Set-Content $jobstatus $jobline
       
        exit 8
    }

    if ($scriptchange) {
        $msg = ">>> Script ended normally with reported changes, but no action required"
        Add-Content $ofile $msg
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "3" + "|" + $version + "|" + $dt.ToString()
        Set-Content $jobstatus $jobline
       
        exit 4
    }

    $msg = ">>> Script ended normally without reported changes, and no action required"
    Add-Content $ofile $msg
    $dt = Get-Date
    $jobline = $ADHC_Computer + "|" + $process + "|" + "0" + "|" + $version + "|" + $dt.ToString()
    Set-Content $jobstatus $jobline
       
    exit 0
   

} 





