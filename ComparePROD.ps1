$Version = " -- Version: 5.1"

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

# END OF COMMON CODING

    # init flags
    $scripterror = $false
    $scriptaction = $false
    $scriptchange = $false

    # Init reporting file
    $str = $ADHC_ProdCompare.Split("/")
    $dir = $ADHC_OutputDirectory + $str[0]
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $Report = $ADHC_OutputDirectory + $ADHC_ProdCompare
    Set-Content $Report $Scriptmsg -force

    # Proces development directories
    $msg = " "
    Add-Content $Report $msg
    $msg = "##########                                         ##########"
    Add-Content $Report $msg
    $msg = "########## Checking D E V E L O P M E N T directoy ##########"
    Add-Content $Report $msg
    $msg = "##########                                         ##########"
    Add-Content $Report $msg

    $DevList = Get-ChildItem $ADHC_DevelopDir -Directory | Select Name,FullName
    foreach ($DevDir in $DevLIst) {
        $configfile = $ADHC_StagingDir + $DevDir.Name + "\" + $ADHC_ConfigFile   # ATTENTION, WE USE THE CONFIG FILE IN THE STAGING DIRECTORY
        # $configfile = $ADHC_DevelopDir + $DevDir.Name + "\" + $ADHC_ConfigFile  # TEST TEST TEST TEST
        if (Test-Path $configfile) {
            [xml]$ConfigXML = Get-Content $configfile
        }
        else {
            $scriptaction = $true
            $msg = ">>> Configuration file $configfile not found, skipping directory"
            Add-Content $Report $msg
            continue
        }

        # Get Staging info
        $stagedir = $ConfigXML.ADHCinfo.StageLib.Root + $ConfigXML.ADHCinfo.StageLib.SubRoot
        
        $process = "COPY"
	    $c = $ConfigXML.ADHCinfo.Stagelib.Build
	    if ($c) {
		    $process = $c
	    }
    
	    switch ($process.ToUpper()) {

		    "COPY" {
			    $DevContent = Get-ChildItem $Devdir.FullName -recurse -file  | `
                                    Where-Object {($_.FullName -notlike "*.git*") -and ($_.FullName -notlike "*MyExample*") } | `
                                    Select FullName,LastWriteTime,Length 
			    foreach ($devfile in $devcontent) {
				    $linewritten = $false
		
				    # Check correctness of Staging directory
                    $repname =  $Devdir.FullName + "\"
				    $stagename = $devfile.FullName.Replace($repname,$Stagedir)

				    if (Test-Path $stagename) {
					    $stageprops = Get-ItemProperty $stagename
					    $stagefound = $true
				    }
				    else {
					    $stagefound = $false
				    }

				    if (!$stagefound) {
					    Add-Content $Report " "
					    $msg = "Development file " + $devfile.FullName + " (Process = $process)"
					    Add-Content $Report $msg
					    $linewritten = $true
					    $msg = ">>> Staged file not found: " + $stagename
					    Add-Content $Report $msg
                        $scriptchange = $true
            
				    } 
				    else {
					    $devprops = Get-ItemProperty $devfile.FullName
					    if (($devprops.Length -ne $stageprops.Length) -or ($devprops.LastWriteTime.ToString().Trim() -ne $stageprops.LastWriteTime.ToString().Trim())) {
						    Add-Content $Report " "
						    $msg = "Development file " + $devfile.FullName 
						    Add-Content $Report $msg
						    $linewritten = $true
						    $msg = "Length = " + $devprops.Length + " --- Last updated = " + $devprops.LastWriteTime
						    Add-Content $Report $msg
						    $msg = ">>> Staged file " + $stagename 
						    Add-Content $Report $msg
						    $msg = ">>> Length = " + $stageprops.Length + "--- Last updated = " + $stageprops.LastWriteTime
						    Add-Content $Report $msg
                            $scriptchange = $true
                  
					    }

				    } 
				

				    if (!(Test-Path $stagedir)) {
					    Add-Content $Report " "
					    $msg = ">>> Staging directory $stagedir niet gevonden"
					    Add-Content $Report $msg 
                        $scriptaction = $true        
				    }
				    else {

					    $stagecontent = Get-ChildItem $stagedir -recurse -file  | Select FullName,LastWriteTime,Length 
					    foreach ($stagefile in $stagecontent) {
					        $linewritten = $false

					        # Check correctness of DEVELOPMENT directory
                            $repname = $DevDir.FullName + "\"
					        $devname = $stagefile.FullName.Replace($stagedir,$repname)

					        if (!(Test-Path $devname)) {
						        if (!$linewritten) {
							        Add-Content $Report " "
							        $msg = "Staging file " + $stagefile.FullName
							        Add-Content $Report $msg
							        $linewritten = $true
						        }
						        $msg = ">>> Corresponding development file $devname not found for staged file " + $stagefile.FullName 
						        Add-Content $Report $msg
                                $scriptaction = $true
                              
						        # Write-Warning "$devname niet gevonden"
					        }
					        else {
						        # Write-Host "$devname wel gevonden"
					        }

					
				        }

        
			        }

    
                }      
		    } 
		
		    default {
			    Add-Content $Report " "
                $msg = ">>> Staging directory $stagedir : BUILD process $process not implemented yet, skipping this directory"
                Add-Content $Report $msg
               
                continue
		    }
	    }
    }

    # Proces staging directories
    $msg = " "
    Add-Content $Report $msg
    $msg = "##########                                 ##########"
    Add-Content $Report $msg
    $msg = "########## Checking S T A G I N G directoy ##########"
    Add-Content $Report $msg
    $msg = "##########                                 ##########"
    Add-Content $Report $msg

    $StageLIst = Get-ChildItem $ADHC_StagingDir -Directory | Select Name,FullName
    foreach ($StageDir in $StageLIst) {
        $configfile = $ADHC_StagingDir + $StageDir.Name + "\" + $ADHC_ConfigFile   # ATTENTION, WE USE THE CONFIG FILE IN THE STAGING DIRECTORY
        # $configfile = $ADHC_DevelopDir + $StageDir.Name + "\" + $ADHC_ConfigFile  # TEST TEST TEST TEST
        
        [xml]$ConfigXML = Get-Content $configfile

        # Get TARGET info
        $targetdir = $ConfigXML.ADHCinfo.Target.Root + $ConfigXML.ADHCinfo.Target.SubRoot
        
        $targetnodelist = $ConfigXML.ADHCinfo.Nodes.ToUpper().Split(",")      
                
        if (!($targetnodelist -contains $ADHC_Computer.ToUpper())) {
            Add-Content $report " "
            $msg = "Directory $targetdir : "
            Add-Content $report $msg
            $msg = "==> Node $ADHC_Computer dus not match nodelist {$targetnodelist}, directory skipped"
	        Add-Content $report $msg
            Continue
        }

        # Get DSL info
        $DSLdir = $ConfigXML.ADHCinfo.DSL.Root + $ConfigXML.ADHCinfo.DSL.SubRoot
    
        $StagedContent = Get-ChildItem $Stagedir.FullName -recurse -file  | Select FullName,LastWriteTime,Length 
        foreach ($stagedfile in $Stagedcontent) {
            $linewritten = $false

            # Check correctness of TARGET directory
            $repname = $Stagedir.FullName + "\"
            $targetname = $stagedfile.FullName.Replace($repname,$targetdir)

            if (Test-Path $targetname) {
                $targetprops = Get-ItemProperty $targetname
                $targetfound = $true
            }
            else {
                $targetfound = $false
            }

            if (!$targetfound) {
                Add-Content $Report " "
                $msg = "Staged file " + $stagedfile.FullName
                Add-Content $Report $msg
                $linewritten = $true
                $msg = ">>> Target file not found: " + $targetname
                Add-Content $Report $msg
                $scriptaction = $true
            
            } 
            else {
                $stagedprops = Get-ItemProperty $stagedfile.FullName
                if (($stagedprops.Length -ne $targetprops.Length) -or ($stagedprops.LastWriteTime.ToString().Trim() -ne $targetprops.LastWriteTime.ToString().Trim())) {
                    Add-Content $Report " "
                    $msg = "Staged file " + $stagedfile.FullName 
                    Add-Content $Report $msg
                    $linewritten = $true
                    $msg = "Length = " + $stagedprops.Length + " --- Last updated = " + $stagedprops.LastWriteTime
                    Add-Content $Report $msg
                    $msg = ">>> Target file " + $targetname 
                    Add-Content $Report $msg
                    $msg = ">>> Length = " + $targetprops.Length + "--- Last updated = " + $targetprops.LastWriteTime
                    Add-Content $Report $msg
                    $scriptchange = $true
                
               


                }

            } 
             # Check correctness of DSL directory
            $repname = $Stagedir.FullName + "\"
            $DSLname = $stagedfile.FullName.Replace($repname,$DSLdir)

            if (Test-Path $DSLname) {
                $DSLprops = Get-ItemProperty $DSLname
                $DSLfound = $true
            }
            else {
                $DSLfound = $false
            }

            if (!$DSLfound) {
                if (!$linewritten) {
                    Add-Content $Report " "
                    $msg = "Staged file " + $stagedfile.FullName
                    Add-Content $Report $msg
                    $linewritten = $true
                }
                $msg = ">>> DSL file not found: " + $DSLname
                Add-Content $Report $msg
                $scriptchange = $true
            
            } 
            else {
                $stagedprops = Get-ItemProperty $stagedfile.FullName
                if (($stagedprops.Length -ne $DSLprops.Length) -or ($stagedprops.LastWriteTime.ToString().Trim() -ne $DSLprops.LastWriteTime.ToString().Trim())) {
                    if (!$linewritten) {
                        Add-Content $Report " "
                        $msg = "Staged file " + $stagedfile.FullName 
                        Add-Content $Report $msg
                        $linewritten = $true
                    }
                    $msg = "Length = " + $stagedprops.Length + " --- Last updated = " + $stagedprops.LastWriteTime
                    Add-Content $Report $msg
                    $msg = ">>> DSL file " + $DSLname 
                    Add-Content $Report $msg
                    $msg = ">>> Length = " + $DSLprops.Length + "--- Last updated = " + $DSLprops.LastWriteTime
                    Add-Content $Report $msg
                    $scriptchange = $true
                
               


                }

            }       
            


        } 

        if (!(Test-Path $DSLdir)) {
            Add-Content $Report " "
            $msg = ">>> DSL directory $DSLdir niet gevonden"
            Add-Content $Report $msg 
            $scriptaction = $true        
        }
        else {

            $DSLContent = Get-ChildItem $DSLdir -recurse -file  | Select FullName,LastWriteTime,Length,Name 
            foreach ($dslfile in $DSLcontent) {
                $linewritten = $false

                if ($dslfile.Name.ToUpper().Contains("#ADHC_DELETED_")) {
                    Add-Content $Report " "
                    $msg = "DSL file " + $dslfile.FullName + " will be deleted on after programmed delay"
                    Add-Content $Report $msg
                    $linewritten = $true
                } 
                else {
                    # Check correctness of TARGET directory
                    $repname = $StageDir.FullName + "\"
                    $stagename = $dslfile.FullName.Replace($DSLdir,$repname)

                    if (!(Test-Path $stagename)) {
                        if (!$linewritten) {
                            Add-Content $Report " "
                            $msg = "DSL file " + $dslfile.FullName
                            Add-Content $Report $msg
                            $linewritten = $true
                        }
                        $msg = ">>> Corresponding staged file $stagename not found for DSL file " + $DSLfile.FullName 
                        Add-Content $Report $msg
                        $scriptaction = $true
                              
                        # Write-Warning "$stagename niet gevonden"
                    }
                    else {
                        # Write-Host "$stagename wel gevonden"
                    }

                     $deployname = $dslfile.FullName.Replace($DSLdir,$targetdir)

                    if (!(Test-Path $deployname)) {
                        if (!$linewritten) {
                            Add-Content $Report " "
                            $msg = "DSL file " + $dslfile.FullName
                            Add-Content $Report $msg
                            $linewritten = $true
                        }
                        $msg = ">>> Corresponding production file $deployname not found for DSL file " + $DSLfile.FullName 
                        Add-Content $Report $msg
                        $scriptaction = $true
                        # Write-Warning "$deployname niet gevonden"
                    }
                    else {
                        # Write-Host "$deployname wel gevonden"
                    }
                }
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
    
    Add-Content $Report " "

        
    if ($scripterror) {
        Add-Content $Report "Failed item = $FailedItem"
        Add-Content $Report "Errormessage = $ErrorMessage"
        $msg = ">>> Script ended abnormally"
        Add-Content $Report $msg
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "9" + "|" + $version + "|" + $dt.ToString()
        Set-Content $jobstatus $jobline
       
        Add-Content $jobstatus "Failed item = $FailedItem"
        Add-Content $jobstatus "Errormessage = $ErrorMessage"
        exit 16        
    }
   
    if ($scriptaction) {
        $msg = ">>> Script ended normally with action required"
        Add-Content $Report $msg
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "6" + "|" + $version + "|" + $dt.ToString()
        Set-Content $jobstatus $jobline
       
        exit 8
    }

    if ($scriptchange) {
        $msg = ">>> Script ended normally with reported changes, but no action required"
        Add-Content $Report $msg
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "3" + "|" + $version + "|" + $dt.ToString()
        Set-Content $jobstatus $jobline
       
        exit 4
    }

    $msg = ">>> Script ended normally without reported changes, and no action required"
    Add-Content $Report $msg
    $dt = Get-Date
    $jobline = $ADHC_Computer + "|" + $process + "|" + "0" + "|" + $version + "|" + $dt.ToString()
    Set-Content $jobstatus $jobline
       
    exit 0
   

} 
