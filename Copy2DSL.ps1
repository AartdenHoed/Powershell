$InformationPreference = "Continue"
$WarningPreference = "Continue"

$Version = " -- Version: 1.1"
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

    # Get all modules in this source directory
    $sourceDir = $loc + "\"
    # write $sourceDir 

    $SourceList = Get-ChildItem -File | select-object Name, LastWriteTime 
    # write $Sourcelist
   
    # Determine target directory
    $TargetDir = $ADHC_DslLocation + $dirFound.Name + "\"


    $msg = "==> Target directory: "+ $targetDir
    Write-Information $msg

    $currentdate = (Get-Date) 

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
            $timeDifference = New-TimeSpan –Start $sourceMod.LastWriteTime –End $currentDate
            If ($timeDifference.Days -ge 14) {
                $copyme = $true
                $msg = "Module " + $sourceMod.Name + " does not exist and will be added to computer " + $env:COMPUTERNAME
                Write-Warning $msg 
            }
            else {
                $waitTime = 14 - $timeDifference.Days
                $msg = "Module " + $sourceMod.Name + " does not exist and will be added to computer " + $env:COMPUTERNAME + " in " + $waitTime + " days."
                Write-Warning $msg 
            }
        }
        else { 
            # Get-ItemProperty -path "$targetPath" | Select-Object Name, LastWriteTime | Out-GridView
            $targetMod = Get-ItemProperty -path "$targetPath" 
            
            $msg = "Processing target module " + $targetMod.Name + " with timestamp " + $targetMod.LastWriteTime
            Write-Information $msg 
            

            if ($targetMod.LastWriteTime -eq $sourceMod.LastWriteTime) {
                $msg = "Module " + $targetMod.Name + " is up to date on computer " + $env:COMPUTERNAME
                Write-Information $msg 
            }
            else {
                $timeDifference = New-TimeSpan –Start $sourceMod.LastWriteTime –End $currentDate
                If ($timeDifference.Days -ge 14) {
                    if ($targetMod.LastWriteTime -lt $sourceMod.LastWriteTime) {
                        $copyme = $true
                        $msg = "Module " + $targetMod.Name  + " is older and will be replaced on computer " + $env:COMPUTERNAME 
                        Write-Warning $msg 
                    }
                    else {
                        $msg = "Module " + $targetMod.Name + " should not be replaced by an older version on " + $env:COMPUTERNAME
                        Write-Warning $msg 
                    }

                }
            }     
         
        }
        if ($copyme) {
            # Copy from staging to PROD
            Copy-Item "$sourcePath" "$targetPath" -force 
            Write-Information "Copy action completed" 
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
            $msg = "Production module " + $targetMod.Name + " is obsolete and will be deleted on computer " + $env:COMPUTERNAME
            Write-Warning $msg
            $item = $targetmod.Name
            Remove-Item "$item" 
         }      
    }
}

