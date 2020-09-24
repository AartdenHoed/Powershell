$Version = " -- Version: 6.0"

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
    
    Add-Content $Report " "

    $DevList = Get-ChildItem $ADHC_DevelopDir -Directory | Select Name,FullName
    foreach ($DevDir in $DevLIst) {
        
        Add-Content $Report " "
        $msg = "----------"+ $Devdir.FullName.PadRight(100,"-") 
        Add-Content $Report $msg
        $configfile = $ADHC_StagingDir + $DevDir.Name + "\" + $ADHC_ConfigFile   # ATTENTION, WE USE THE CONFIG FILE IN THE STAGING DIRECTORY
        # $configfile = $ADHC_DevelopDir + $DevDir.Name + "\" + $ADHC_ConfigFile  # TEST TEST TEST TEST
        if (Test-Path $configfile) {
            [xml]$ConfigXML = Get-Content $configfile
        }
        else {
            $scriptaction = $true
            $msg = "Warning *".Padright(10," ") + "Configuration file $configfile not found, skipping directory"
            Add-Content $Report $msg
            Add-Content $Report " "
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
            # Check for each development file te corrsponding staging file

		    "COPY" {
			    $DevContent = Get-ChildItem $Devdir.FullName -recurse -file  | `
                                    Where-Object {($_.FullName -notlike "*.git*") -and ($_.FullName -notlike "*MyExample*") } | `
                                    Select FullName,LastWriteTime,Length 
			    foreach ($devfile in $devcontent) {
				   		
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
					    $msg = "Info    *".Padright(10," ") + "Staged file not found"
                        Add-Content $Report $msg
					    $msg = " ".Padright(10," ") + "Development file = ".Padright(20," ") + $devfile.FullName.Padright(90," ") 
					    Add-Content $Report $msg
					    $msg = " ".Padright(10," ") + "Development file = ".Padright(20," ") + $stagename.PadRight(90," ") + "NOT FOUND!"
					    Add-Content $Report $msg
                        Add-Content $Report " "
                        
                        $scriptchange = $true
            
				    } 
				    else {
					    $devprops = Get-ItemProperty $devfile.FullName
					    if (($devprops.Length -ne $stageprops.Length) -or ($devprops.LastWriteTime.ToString().Trim() -ne $stageprops.LastWriteTime.ToString().Trim())) {
                            if ($devprops.LastWriteTime -lt $stageprops.LastWriteTime) {
                                $msg = "Warning *".Padright(10," ") + "Development file is OLDER than staging file"
                                $scriptaction = $true
                            }
                            else {
                                $msg = "Info    *".Padright(10," ") + "Development file differs from staging file"
                                $scriptchange = $true
                            }

                            Add-Content $Report $msg
						    $msg = " ".Padright(10," ") + "Development file = ".Padright(20," ") + $devfile.FullName.Padright(90," ") + 
                                    "Length = ".PadRight(10," ") + $devprops.Length.ToString().PadRight(10," ") + "Last update = ".Padright(16," ") + $devprops.LastWriteTime 
						    Add-Content $Report $msg
                            $msg = " ".Padright(10," ") + "Stage file = ".Padright(20," ") + $stagename.Padright(90," ") + 
                                    "Length = ".PadRight(10," ") + $stageprops.Length.ToString().PadRight(10," ") + "Last update = ".Padright(16," ") + $stageprops.LastWriteTime 
						    Add-Content $Report $msg
                            Add-Content $Report " "
						   
                            
                  
					    }

				    } 
				

				   

    
                } 
                
                # Check for each staging file whether a development file exists 
                if (!(Test-Path $stagedir)) {
                    $msg = "Warning *".Padright(10," ") + "Staging directory $stagedir niet gevonden"
					Add-Content $Report $msg 
					Add-Content $Report " "
					
                    $scriptaction = $true        
				}
				else {

					$stagecontent = Get-ChildItem $stagedir -recurse -file  | Select FullName,LastWriteTime,Length 
					foreach ($stagefile in $stagecontent) {
					  

					    # Check correctness of DEVELOPMENT directory
                        $repname = $DevDir.FullName + "\"
					    $devname = $stagefile.FullName.Replace($stagedir,$repname)

					    if (!(Test-Path $devname)) {
						   
						    $msg = "Warning *".Padright(10," ") + "Development file $devname not found for staged file " + $stagefile.FullName 
						    Add-Content $Report $msg
                            Add-Content $Report " "
                            $scriptaction = $true
                              
						    # Write-Warning "$devname niet gevonden"
					    }
					    else {
						    # Write-Host "$devname wel gevonden"
					    }

					
				    }

        
			    }    
		    } 
		
		    default {
			    
                $msg = "Info    *".Padright(10," ") + "Staging directory $stagedir : BUILD process $process not implemented yet, skipping this directory"
                Add-Content $Report $msg
                Add-Content $Report " "
               
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
    Add-Content $Report " "

    $StageLIst = Get-ChildItem $ADHC_StagingDir -Directory | Select Name,FullName
    foreach ($StageDir in $StageLIst) {
        $msg = "----------"+ $Stagedir.FullName.PadRight(100,"-") 
        Add-Content $Report $msg

        $configfile = $ADHC_StagingDir + $StageDir.Name + "\" + $ADHC_ConfigFile   # ATTENTION, WE USE THE CONFIG FILE IN THE STAGING DIRECTORY
        if (Test-Path $configfile) {
            [xml]$ConfigXML = Get-Content $configfile
        }
        else {
            $scriptaction = $true
            $msg = "Warning *".Padright(10," ") + "Configuration file $configfile not found, skipping directory"
            Add-Content $Report $msg
            Add-Content $Report " "
            continue
        }
        
        # Get TARGET info
        $targetdir = $ConfigXML.ADHCinfo.Target.Root + $ConfigXML.ADHCinfo.Target.SubRoot
        
        $targetnodelist = $ConfigXML.ADHCinfo.Nodes.ToUpper().Split(",")      
                
        if (!($targetnodelist -contains $ADHC_Computer.ToUpper())) {
            $msg = "Info    *".Padright(10," ") + "Node $ADHC_Computer dus not match nodelist {$targetnodelist}, directory skipped"
            Add-Content $report $msg
            Add-Content $report " "
            Continue
        }

        # Get DSL info
        $DSLdir = $ConfigXML.ADHCinfo.DSL.Root + $ConfigXML.ADHCinfo.DSL.SubRoot
    
        $StagedContent = Get-ChildItem $Stagedir.FullName -recurse -file  | Select FullName,LastWriteTime,Length 
        foreach ($stagedfile in $Stagedcontent) {
            
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
                $msg = "Info    *".Padright(10," ") + "Production file not found"
                Add-Content $Report $msg
				$msg = " ".Padright(10," ") + "Staged file = ".Padright(20," ") + $stagedfile.FullName.Padright(90," ") 
				Add-Content $Report $msg
				$msg = " ".Padright(10," ") + "Production file = ".Padright(20," ") + $targetname.PadRight(90," ") + "NOT FOUND!"
				Add-Content $Report $msg
                Add-Content $Report " "
                
                $scriptchange = $true
            
            } 
            else {
                $stageprops = Get-ItemProperty $stagedfile.FullName
                if (($stageprops.Length -ne $targetprops.Length) -or ($stageprops.LastWriteTime.ToString().Trim() -ne $targetprops.LastWriteTime.ToString().Trim())) {
                    
                    if ($stageprops.LastWriteTime -lt $targetprops.LastWriteTime) {
                        $msg = "Warning *".Padright(10," ") + "Staged file is OLDER than production file"
                        $scriptaction = $true
                    }
                    else {
                        $msg = "Info    *".Padright(10," ") + "Staging file differs from production file"
                        $scriptchange = $true
                    }

                    Add-Content $Report $msg
					$msg = " ".Padright(10," ") + "Staged file = ".Padright(20," ") + $stagedfile.FullName.Padright(90," ") + 
                            "Length = ".PadRight(10," ") + $stageprops.Length.ToString().PadRight(10," ") + "Last update = ".Padright(16," ") + $stageprops.LastWriteTime 
					Add-Content $Report $msg
                    $msg = " ".Padright(10," ") + "Stage file = ".Padright(20," ") + $targetname.Padright(90," ") + 
                            "Length = ".PadRight(10," ") + $targetprops.Length.ToString().PadRight(10," ") + "Last update = ".Padright(16," ") + $targetprops.LastWriteTime 
					Add-Content $Report $msg
                    Add-Content $Report " "
                                       
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
                $msg = "Info    *".Padright(10," ") + "DSL file not found"
                Add-Content $Report $msg
				$msg = " ".Padright(10," ") + "Staged file = ".Padright(20," ") + $stagedfile.FullName.Padright(90," ") 
				Add-Content $Report $msg
				$msg = " ".Padright(10," ") + "DSL file = ".Padright(20," ") + $DSLname.PadRight(90," ") + "NOT FOUND!"
				Add-Content $Report $msg
                Add-Content $Report " "
                
                $scriptchange = $true
                            
            } 
            else {
                $stageprops = Get-ItemProperty $stagedfile.FullName
                if (($stageprops.Length -ne $DSLprops.Length) -or ($stageprops.LastWriteTime.ToString().Trim() -ne $DSLprops.LastWriteTime.ToString().Trim())) {
                    
                    if ($stageprops.LastWriteTime -lt $DSLprops.LastWriteTime) {
                        $msg = "Warning *".Padright(10," ") + "Staged file is OLDER than DSL file"
                        $scriptaction = $true
                    }
                    else {
                        $msg = "Info    *".Padright(10," ") + "Staged file differs from DSL file"
                        $scriptchange = $true
                    }

                    Add-Content $Report $msg
					$msg = " ".Padright(10," ") + "Staged file = ".Padright(20," ") + $stagedfile.FullName.Padright(90," ") + 
                            "Length = ".PadRight(10," ") + $stageprops.Length.ToString().PadRight(10," ") + "Last update = ".Padright(16," ") + $stageprops.LastWriteTime 
					Add-Content $Report $msg
                    $msg = " ".Padright(10," ") + "DSL file = ".Padright(20," ") + $DSLname.Padright(90," ") + 
                            "Length = ".PadRight(10," ") + $DSLprops.Length.ToString().PadRight(10," ") + "Last update = ".Padright(16," ") + $DSLprops.LastWriteTime 
					Add-Content $Report $msg
                    Add-Content $Report " "
                    
                }

            }       
            


        } 
    

        # CHECK DSL directory backwards

        if (!(Test-Path $DSLdir)) {
            
            $msg = "Warning *".Padright(10," ") +  "DSL directory $DSLdir niet gevonden"
            Add-Content $Report $msg 
            Add-Content $Report " "
            $scriptaction = $true        
        }
        else {

            $DSLContent = Get-ChildItem $DSLdir -recurse -file  | Select FullName,LastWriteTime,Length,Name 
            foreach ($dslfile in $DSLcontent) {
                
                if ($dslfile.Name.ToUpper().Contains("#ADHC_DELETED_")) {
                    
                    $msg = "Info    *".Padright(10," ") + "DSL file " + $dslfile.FullName + " will be deleted on after programmed delay"
                    Add-Content $Report $msg
                    Add-Content $Report " "
                   
                } 
                else {
                    # Check correctness of TARGET directory
                    $repname = $StageDir.FullName + "\"
                    $stagename = $dslfile.FullName.Replace($DSLdir,$repname)

                    if (!(Test-Path $stagename)) {
                        $msg = "Warning *".Padright(10," ") + "Staged file not found"
                        Add-Content $Report $msg
				        $msg = " ".Padright(10," ") + "DSL file = ".Padright(20," ") + $dslfile.FullName.Padright(90," ") 
				        Add-Content $Report $msg
				        $msg = " ".Padright(10," ") + "Staged file = ".Padright(20," ") + $stagename.PadRight(90," ") + "NOT FOUND!"
				        Add-Content $Report $msg
                        Add-Content $Report " "
                
                        $scriptaction = $true
                                                                              
                        # Write-Warning "$stagename niet gevonden"
                    }
                    else {
                        # Write-Host "$stagename wel gevonden"
                    }

                    $deployname = $dslfile.FullName.Replace($DSLdir,$targetdir)

                    if (!(Test-Path $deployname)) {
                        $msg = "Warning *".Padright(10," ") + "Production file not found"
                        Add-Content $Report $msg
				        $msg = " ".Padright(10," ") + "DSL file = ".Padright(20," ") + $dslfile.FullName.Padright(90," ") 
				        Add-Content $Report $msg
				        $msg = " ".Padright(10," ") + "Production file = ".Padright(20," ") + $deployname.PadRight(90," ") + "NOT FOUND!"
				        Add-Content $Report $msg
                        Add-Content $Report " "
                
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
