CLS
$InformationPreference = "Continue"
$WarningPreference = "Continue"

$Version = " -- Version: 2.1.2"
$Node = " -- Node: " + $env:COMPUTERNAME
$d = Get-Date
$Datum = " -- Date: " + $d.ToShortDateString()
$Tijd = " -- Time: " + $d.ToShortTimeString()
$Scriptmsg = "PowerShell script " + $MyInvocation.MyCommand.Name + $Version + $Datum + $Tijd +$Node
Write-Information $Scriptmsg 

$FullScriptName = $MyInvocation.MyCommand.Definition
$ScriptName = $MyInvocation.MyCommand.Name
$ADHC_PsPath = $FullScriptName.Replace($ScriptName, "")
$ADHC_InitVar = $ADHC_PsPath + "InitVar.PS1"
& "$ADHC_InitVar"

# Init reporting file
$str = $ADHC_Deploylog.Split("/")
$dir = $ADHC_OutputDirectory + $str[0]
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$ofile = $ADHC_OutputDirectory + $ADHC_Deploylog
Set-Content $ofile $Scriptmsg -force

# Generic delete function
function DeleteNow([string]$action, [string]$tobedeleted, [string]$process)
{
    Write-Host "$action $tobedeleted with process $process"

    if ($process.ToUpper() -eq "WINDOWSSCHEDULER") {
        $xml = [xml](Get-Content "$tobedeleted") 
    }
        
    switch ($action.ToUpper()) {
        "DELETE" { 
            $msg = "Module " + $tobedeleted + " will be deleted from computer " + $ADHC_Computer
            Remove-Item "$tobedeleted" -force
            Add-Content $ofile $msg
        }
        "DELETEX" {
            if (!($tobedeleted.ToUpper() -contains "#ADHC_DELETED_")) {
                # Only rename ONCE!!!
                $dt = Get-Date
                $yyyy = $dt.Year
                $mm = “{0:d2}” -f $dt.Month
                $dd = “{0:d2}” -f $dt.Day
                $splitname = $tobedeleted.Split("/\")
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
                Add-Content $ofile $msg
            }
                        
        }
        Default {
            $msg = "ERROR *** Wrong action $action encountered"
            Add-Content $ofile $msg
            exit 16
        }
    }

    # Post processing
    switch ($process.ToUpper()) {
        "COPY"   { } 
        "WINDOWSSCHEDULER" {
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
            Add-Content $ofile $msg
              
        }
        default    {
            $msg = "ERROR *** Wrong deploy process $process encountered"
            Add-Content $ofile $msg
            exit 16
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
                Add-Content $ofile $msg
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
                Add-Content $ofile $msg
            }
            else {
                $msg = "Module " + $from + " will replace " + $to + " in " + $waitTime + " days"
                Add-Content $ofile $msg
            } 
            
        }
        Default {
            $msg = "ERROR *** Wrong action $action encountered"
            Add-Content $ofile $msg
            exit 16
        }
    }

    # Post processing
    switch ($process.ToUpper()) {
        "COPY"   { } 
        "WINDOWSSCHEDULER" {
            $xml = [xml](Get-Content "$targetPath"); 
                    
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
            $msg = 'Scheduled task "' + $taskName + '" registered now.';
            Add-Content $ofile $msg


        }
        default    {
            $msg = "ERROR *** Wrong deploy process $process encountered"
            Add-Content $ofile $msg
            exit 16
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
    $staginglocation = $stagingdir.FullName        
       
    Add-Content $ofile " "
	$msg = "==> Staging directory: "+ $staginglocation
	Add-Content $ofile $msg

    $configfile = $staginglocation + "\" + $ADHC_ConfigFile
    if (!(Test-Path $configfile)) {
        $msg = "==> Configfile $configfile not found, directory skipped"
	    Add-Content $ofile $msg
        Continue
    } 
    else {
        [xml]$ConfigXML = Get-Content $configfile

        # Skip this directory if not meant for this computer node
        $targetnodelist = "*ALL*" 
        if ($ConfigXML.ADHCinfo.Nodes) {
            $targetnodelist = $ConfigXML.ADHCinfo.Nodes
        }
        if ($targetnodelist.ToUpper() -eq "*ALL*") {
            $targetnodelist = $ADHC_Hostlist
        }
        
        if (!($targetnodelist.ToUpper() -contains $ADHC_Computer.ToUpper())) {
            $msg = "==> Node $ADHC_Computer dus not match nodelist {$targetnodelist}, directory skipped"
	        Add-Content $ofile $msg
            Continue
        }
       
        # Get TARGET info
        $t = $ConfigXML.ADHCinfo.Target.Directory
        if ($t.'#text') {
            $targetdir = $t.'#text'
        }
        else {
            $targetdir = $t
        }
        if ($t.Delay) {
            $targetdelay = $t.delay
        }
        else {
            $targetdelay = 1                         # Default
        }
        $deploy = "COPY"                             # Default!!!
        if ($t.Deploy) {
            $deploy = $t.Deploy
        }
        
        if ($targetdir.substring(0,6) -eq '$ADHC_'){ 
            $targetdir = Invoke-Expression($targetdir); 
        }
        

        # Get DSL info
        $t = $ConfigXML.ADHCinfo.DSL.Directory
        if ($t.'#text') {
            $dsldir = $t.'#text'
        }
        else {
            $dsldir = $t
        }
               
        if ($dsldir.substring(0,6) -eq '$ADHC_'){ 
            $dsldir = Invoke-Expression($dsldir); 
        }
        
        if ($t.Delay) {
            $dsldelay = $t.delay
        }
        else {
            $dsldelay = 30                         # default
        }

        # Create production directory if it does not exits yet
        $x = Test-Path $targetdir
        if (!$x) {
            $msg = "      Directory " + $targetdir + " does not exist and will be created on computer " + $env:COMPUTERNAME
            Add-Content $ofile $msg
            New-Item -ItemType Directory -Force -Path "$targetdir"
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
    $TargetList = Get-ChildItem -file | select-object FullName 
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
                 DeleteNow "Delete"  "$mod" "$deploy" 
             }

         } 
 
    }
    
    # Determine deletions in DSL directory
    Set-Location "$DSLDir"
    $DSLList = Get-ChildItem -file | select-object FullName 
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
            DeleteNow "DeleteX"  "$mod" "COPY" 
            

         } 
 
    }

}






