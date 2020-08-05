CLS
$InformationPreference = "Continue"
$WarningPreference = "Continue"

$Version = " -- Version: 3.2"
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
$str = $ADHC_ProdCompare.Split("/")
$dir = $ADHC_OutputDirectory + $str[0]
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$Report = $ADHC_OutputDirectory + $ADHC_ProdCompare
Set-Content $Report $Scriptmsg -force

# Proces development directories
$DevList = Get-ChildItem $ADHC_DevelopDir -Directory | Select Name,FullName
foreach ($DevDir in $DevLIst) {
    $configfile = $DevDir.FullName + "\" + $ADHC_ConfigFile
    [xml]$ConfigXML = Get-Content $configfile

    # Get Staging info
    $t = $ConfigXML.ADHCinfo.Stagelib.Directory
    if ($t.'#text') {
        $stagedir = $t.'#text'
    }
    else {
        $stagedir = $t
    }
	$process = "COPY"
	$c = $ConfigXML.ADHCinfo.Stagelib.Directory.Build
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
				$stagename = $devfile.FullName.Replace($Devdir.FullName,$Stagedir)

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
                  
					}

				} 
				

				if (!(Test-Path $stagedir)) {
					Add-Content $Report " "
					$msg = ">>> Staging directory $stagedir niet gevonden"
					Add-Content $Report $msg         
				}
				else {

					$stagecontent = Get-ChildItem $stagedir -recurse -file  | Select FullName,LastWriteTime,Length 
					foreach ($stagefile in $stagecontent) {
					    $linewritten = $false

					    # Check correctness of DEVELOPMENT directory
					    $devname = $stagefile.FullName.Replace($stagedir,$DevDir.FullName)

					    if (!(Test-Path $devname)) {
						    if (!$linewritten) {
							    Add-Content $Report " "
							    $msg = "Staging file " + $stagefile.FullName
							    Add-Content $Report $msg
							    $linewritten = $true
						    }
						    $msg = ">>> Corresponding development file $devname not found for staged file " + $stagefile.FullName 
						    Add-Content $Report $msg
                              
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
$StageLIst = Get-ChildItem $ADHC_StagingDir -Directory | Select Name,FullName
foreach ($StageDir in $StageLIst) {
    $configfile = $Stagedir.FullName + "\" + $ADHC_ConfigFile
    [xml]$ConfigXML = Get-Content $configfile

    # Get TARGET info
    $t = $ConfigXML.ADHCinfo.Target.Directory
    if ($t.'#text') {
        $targetdir = $t.'#text'
    }
    else {
        $targetdir = $t
    }
        
    if ($targetdir.substring(0,6) -eq '$ADHC_'){ 
        $targetdir = Invoke-Expression($targetdir); 
    }
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

    # Get DSL info
    $t = $ConfigXML.ADHCinfo.DSL.Directory
    if ($t.'#text') {
        $DSLdir = $t.'#text'
    }
    else {
        $DSLdir = $t
    }
        
    if ($DSLdir.substring(0,6) -eq '$ADHC_'){ 
        $DSLdir = Invoke-Expression($DSLdir); 
    }
    
    $StagedContent = Get-ChildItem $Stagedir.FullName -recurse -file  | Select FullName,LastWriteTime,Length 
    foreach ($stagedfile in $Stagedcontent) {
        $linewritten = $false

        # Check correctness of TARGET directory
        $targetname = $stagedfile.FullName.Replace($Stagedir.FullName,$targetdir)

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
                
               


            }

        } 
         # Check correctness of DSL directory
        $DSLname = $stagedfile.FullName.Replace($Stagedir.FullName,$DSLdir)

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
                
               


            }

        }       
            


    } 

    if (!(Test-Path $DSLdir)) {
        Add-Content $Report " "
        $msg = ">>> DSL directory $DSLdir niet gevonden"
        Add-Content $Report $msg         
    }
    else {

        $DSLContent = Get-ChildItem $DSLdir -recurse -file  | Select FullName,LastWriteTime,Length 
        foreach ($dslfile in $DSLcontent) {
            $linewritten = $false

            # Check correctness of TARGET directory
            $stagename = $dslfile.FullName.Replace($DSLdir,$StageDir.FullName)

            if (!(Test-Path $stagename)) {
                if (!$linewritten) {
                    Add-Content $Report " "
                    $msg = "DSL file " + $dslfile.FullName
                    Add-Content $Report $msg
                    $linewritten = $true
                }
                $msg = ">>> Corresponding staged file $stagename not found for DSL file " + $DSLfile.FullName 
                Add-Content $Report $msg
                              
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
                # Write-Warning "$deployname niet gevonden"
            }
            else {
                # Write-Host "$deployname wel gevonden"
            }
        }

        
    }

    
        
} 


$msg = ">>> Script ended" 
Add-Content $Report " "
Add-Content $Report $msg
exit
