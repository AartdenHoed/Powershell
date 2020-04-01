$InformationPreference = "Continue"
$WarningPreference = "Continue"

$Version = " -- Version: 1.6"
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


#
# Find sources
#

# Locate staging library and get all staging folders in $Dirlist

Set-Location "$ADHC_StagingDir"
$Dirlist = Get-ChildItem -Directory  | Select-Object Name 
# write $Dirlist

# Loop through subdirs of staging lib
foreach ($dirfound in $Dirlist) {
   
    # Get all modules in source directory
    $loc = $ADHC_StagingDir + $dirfound.Name    
    Set-Location "$loc"

    $msg = "==> Source directory: "+ $loc
    Write-Information $msg


    $sourceDir = $loc + "\"
    # write $sourceDir 

    $SourceList = Get-ChildItem -File | select-object Name, LastWriteTime 
    # write $Sourcelist
   

    # Determine target directory
    $targetFound = $false
    for ($i=0; $i -lt $ADHC_SourceTargetList.length; $i++) {
	    if ($ADHC_SourceTargetList[$i].source -eq $dirfound.name) {
            $targetDir = $ADHC_SourceTargetList[$i].target
            $targetType = $ADHC_SourceTargetList[$i].type
            $targetFound = $true
            break
        }
    } 
    If (! $targetFound) {
        $msg = "No target directory found for "+ $loc
        Write-Warning $msg     
        continue;
    }   
    # write $dirfound.Name
    # write "levert"
    # write $TargetDir 

    $msg = "==> Target directory: "+ $targetDir
    Write-Information $msg

    foreach ($sourceMod in $SourceList) {
        $copyme = $false
        $targetPath = $targetDir + $sourceMod.name
        $sourcePath = $sourceDir + $sourceMod.name

        # Create directory if necessary
        $x = Test-Path "$targetDir"
        if (!$x) {
            $msg = "Directory " + $targetDir + " does not exist and will be created on computer " + $env:COMPUTERNAME
            Write-Warning $msg 
            New-Item -ItemType Directory -Force -Path "$targetDir"
        }

        $x = Test-Path "$targetPath"
        # write $targetPath $x
        if (!$x) {
            $copyme = $true
            $msg = "Module " + $sourceMod.Name + " does not exist and will be added to computer " + $env:COMPUTERNAME
            Write-Warning $msg 
        }
        else { 
            # Get-ItemProperty -path "$targetPath" | Select-Object Name, LastWriteTime | Out-GridView
            $targetMod = Get-ItemProperty -path "$targetPath" 
            $msg = "Processing target module " + $targetMod.Name + " with timestamp " + $targetMod.LastWriteTime
            Write-Information $msg 
            if ($targetMod.LastWriteTime -ne $sourceMod.LastWriteTime) {
                $copyme = $true
                $msg = "Module " + $targetMod.Name  + " has a different timestamp and will be replaced on computer " + $env:COMPUTERNAME 
                Write-Warning $msg 
            }
            else {
                $msg = "Module " + $targetMod.Name + " is up to date on computer " + $env:COMPUTERNAME
                Write-Information $msg 
            }
        }
        if ($copyme) {
            # Copy from staging to PROD
            Copy-Item "$sourcePath" "$targetPath" -force
            Write-Information "Copy action completed" 

            # Post processing
            switch ($targetType) {
                "Module"   {Write-Information "No further action required" } 
                "Schedule" {$xml = [xml](Get-Content "$targetPath"); `

                            $Author = $xml.task.RegistrationInfo.Author; `
                            if ($Author) { `
                                # write $Author.substring(0,6); `
                                if  ($Author.substring(0,6) -eq '$ADHC_'){ `
                                    $xml.task.RegistrationInfo.Author = Invoke-Expression($Author); `
                                }; `
                                # write $xml.task.RegistrationInfo.Author `
                            }


                            $Userid = $xml.task.Triggers.LogonTrigger.UserId ; `
                            if ($Userid) { `
                                # write $Userid.substring(0,6); `
                                if  ($Userid.substring(0,6) -eq '$ADHC_'){ `
                                    $xml.task.Triggers.LogonTrigger.UserId = Invoke-Expression($Userid); `
                                }; `
                                # write $xml.task.RegistrationInfo.Userid `
                            }

                            $Userid = $xml.task.Principals.Principal.Userid ; `
                            if ($Userid) { `
                                # write $Userid.substring(0,6); `
                                if  ($Userid.substring(0,6) -eq '$ADHC_'){ `
                                    $xml.task.Principals.Principal.Userid = Invoke-Expression($Userid); `
                                }; `
                                # write $xml.task.Principals.Principal.Userid `
                            }

                            $StartTime = $xml.task.Triggers.CalendarTrigger.StartBoundary ; `
                            if ($StartTime) { `
                                # write $StartTime.substring(0,6); `
                                if  ($StartTime.substring(0,6) -eq '$ADHC_'){ `
                                    $xml.task.Triggers.CalendarTrigger.StartBoundary = Invoke-Expression($StartTime); `
                                }; `
                                # write $xml.task.Triggers.CalendarTrigger.StartBoundary `
                            }

                            $PythonExec = $xml.task.Actions.Exec.Command ; `
                            if ($PythonExec) { `
                                # write $PythonExec.substring(0,6); `
                                if  ($PythonExec.substring(0,6) -eq '$ADHC_'){ `
                                    $xml.task.Actions.Exec.Command = Invoke-Expression($PythonExec); `
                                }; `
                                # write $xml.task.Actions.Exec.Command `
                            }

                            $PythonArguments = $xml.task.Actions.Exec.Arguments ; `
                            if ($PythonArguments) { `
                                # write $PythonExec.substring(0,6); `
                                if  ($PythonArguments.substring(0,6) -eq '$ADHC_'){ `
                                    $xml.task.Actions.Exec.Arguments = Invoke-Expression($PythonArguments); `
                                }; `
                                # write $xml.task.Actions.Exec.Command `
                            }

                            $TaskName = $xml.Task.RegistrationInfo.URI; `
                            # write $xml.Task.Principals.Principal; `
                            # write $taskName; `
                            # write $sourceMod.Name; `
                            # write $xml.OuterXml; `
                            Register-ScheduledTask -Xml $xml.OuterXml -TaskName $TaskName -Force; `
                            $msg = 'Scheduled task "' + $taskName + '" registered now.'; `
                            Write-Warning $msg; `


                }
                default    {$msg = "Encountered unknown target type " + $targetType + " in DEPLOY script, unexpected errors may occur!" ;`
                                   write-error $msg `
                }
             } 
         }
    }
    # Delete items in production that do not exist in staging
    Set-Location "$targetDir"
    $TargetList = Get-ChildItem -file | select-object Name 
    foreach ($targetMod in $TargetList) {
         $deleteTarget = $true
         foreach ($sourceMod in $SourceList) {
            if ($targetMod.Name -eq $sourcemod.Name) {
                $deleteTarget = $false 
                break
            }
         }  
         if ($deleteTarget) { 
             $targetPath = $targetDir + $targetMod.name
             if ($targetType -eq "Schedule") {
                $xml = [xml](Get-Content "$targetPath") 
             }
             $msg = "Production module " + $targetMod.Name + " is obsolete and will be deleted on computer " + $env:COMPUTERNAME
             Write-Warning $msg
             $item = $targetmod.Name
             Remove-Item "$item"
        
          
            switch ($targetType) {
                "Module"   {Write-Information "No further action required" } 
                "Schedule" {$TaskName = $xml.Task.RegistrationInfo.URI
                            $i = $TaskName.LastIndexOf("\")
                            $len = $TaskName.Length
                            $TaskID = $TaskName.Substring($i+1,$len-$i-1)
                            # write $TaskID
                            $TaskPath = $TaskName.Substring(0,$i+1)
                            # write $TaskPath
                            # write $xml.Task.Principals.Principal; `
                            # write $taskName; `
                            # write $sourceMod.Name; `
                            # write $xml.OuterXml; `
                            Unregister-ScheduledTask -TaskName $TaskID -TaskPath $TaskPath -Confirm:$false
                            $msg = 'Scheduled task "' + $TaskName + '" unregistered now.'
                            Write-Warning $msg


                }
                default    {$msg = "Encountered unknown target type " + $targetType + " in DEPLOY script, unexpected errors may occur!" ;`
                                   write-error $msg `
                }
            } 
        }          
    }
}

