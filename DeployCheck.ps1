$Version = " -- Version: 2.4"

# COMMON coding
CLS
# init flags
$global:scripterror = $false
$global:scriptaction = $false
$global:scriptchange = $false

function CheckModule ([string]$direction, [string]$shortname, [string]$from, [string]$to, [System.Collections.ArrayList]$filter) {
    # $r = "$direction"+ " ~ " + $from + " ~ " +  $to
    # write-host $r
    $direction = $direction.ToUpper()
    

    if ($shortname.ToUpper().Contains("#ADHC_DELETED_")) {
        $searchname = $shortname.Replace("^#ADHC_DELETED_\d{8}$", "")
        $deletion = $true
        $delyear = $shortname.Substring(14,4)
        $delmonth = $shortname.Substring(18,2)
        $delday = $shortname.Substring(20,2)
            # $delyear
            # $delmonth
            # $delday
        $deldate = Get-Date -Year $delyear -Month $delmonth -Day $delday
        
    }
    else {
        $searchname = $shortname
        $deletion = $false
    }

    $currentdate = Get-Date

    foreach ($entry in $filter) {
        $included = $false
        $excluded = $false
        
        if (($entry.includes.ToUpper() -contains "*ALL*")  -or ($entry.includes.ToUpper() -contains $searchname.ToUpper())) {
            if ($entry.excludes.ToUpper() -contains $searchname.ToUpper()) {
                $excluded = $true
                
            }
            else {
                $included = $true
            }
            
        }
        else {
            if ($entry.excludes.ToUpper() -contains "*ALL*") {
                
                $excluded = $true
             
            }
        }
        if ($included -or $excluded) {
            $myprocess = $entry.process.ToUpper()
            $mydelay = $entry.delay
            
            break
        }
                    
    }
    if ($excluded) { return } 
    
    if (!$included) {
        $m = "Module '" + "$shortname" + "' has no corresponding INCLUDE/EXCLUDE statement"
        Report "A" $m 
        
        return
    }     
        
    $existfrom = Test-Path $from
    $existto = Test-Path $To
    if ($existto) {
        $toprops = Get-ItemProperty $to
    }
    if ($existfrom) {
        $fromprops = Get-ItemProperty $from
        
        $timeDifference = New-TimeSpan –Start $fromprops.LastWriteTime –End $currentDate
        
        If ($timeDifference.Days -ge $mydelay) {
            $shouldbedone = $true
            $timeleap = 0
        }
        else {
            $shouldbedone = $false
            $timeleap = $mydelay - $timeDifference.Days
                           
        }        
    }
    else {
        if ($deletion) {
             $timeDifference = New-TimeSpan –Start $deldate –End $currentDate
        
            If ($timeDifference.Days -ge $mydelay) {
                $shouldbedone = $true
                $timeleap = 0
            }
            else {
                $shouldbedone = $false
                $timeleap = $mydelay - $timeDifference.Days
                           
            }        
         
        }

    }
    

    if (($from.ToUpper().Contains("#ADHC_DELETED_")) -and ($direction -eq "FORWARD")) {
        # Report "I" "File $from will be deleted in the future depending on DELAY parameter of target library"
        # reporting already takes place checking backward
        return
    }
    
    if (($to.ToUpper().Contains("#ADHC_DELETED_")) -and ($direction -eq "BACKWARD")) {
        if ($shouldbedone) {
            Report "W" "File $to should have been deleted by now"
            return
        }
        else {
            Report "I" "File $to will be deleted in $timeleap days"
            return
        }
    }

    if ($myprocess.ToUpper() -eq "WINDOWSSCHEDULER") { 
        $situation = $direction + "-" + "COPY"
    }
    else {
        $situation = $direction + "-" + $myprocess 
    }


   
    switch ($situation) {
        "FORWARD-COPY" {
            if  (!$existfrom) {
                Report "E" "Unexpected situation: 'FROM dataset' $from does not exist while checking $direction"
                return                
            }
            if (!$existto) {
                if ($shouldbedone) {
                    Report "W" "Target file $to not found for source file $from "
                    return
                }
                else {
                    Report "I" "Target file $to does not exist yet but will be added in $timeleap days"
                    return
                }
            }
            # If both exits then compare properties
            $attention = $false
            if (($toprops.Length -ne $fromprops.Length) -or ($toprops.LastWriteTime.ToString().Trim() -ne $fromprops.LastWriteTime.ToString().Trim())) {
                if ($fromprops.LastWriteTime -lt $toprops.LastWriteTime) {
                    Report "w" "Source file $from is OLDER than target file $to"
                }
                else {
                    If ($shouldbedone) {
                        Report "W" "Target file differs from source file" 
                        $attention = $true                      
                    }
                    else {
                        Report "I" "Target file differs from sourcefile but will be replaced in $timeleap days"  
                        $attention = $true                     
                    }
                }
            }
            else {
                # if properties are the same, check if this is meant to be
                if (!$shouldbedone) {
                     Report "W" "Source and target file are identical, but this should be the case only after $timeleap days from now"  
                     $attention = $true 
                  
                }
            }
            if ($attention) {
                $l =  "Source file = ".Padright(20," ") + $from.Padright(90," ") + 
                            "Length = ".PadRight(10," ") + $fromprops.Length.ToString().PadRight(10," ") + "Last update = ".Padright(16," ") + $fromprops.LastWriteTime.ToString("yyyy-MMM-dd HH:mm") 
                Report "B" $l
						
                $l = "Target file = ".Padright(20," ") + $to.Padright(90," ") + 
                        "Length = ".PadRight(10," ") + $toprops.Length.ToString().PadRight(10," ") + "Last update = ".Padright(16," ") + $toprops.LastWriteTime.ToString("yyyy-MMM-dd HH:mm") 
                Report "B" $l
            }
			return

        }
        "BACKWARD-COPY" {
            if (!$existto) {
                Report "E" "Unexpected situation: 'TO dataset' $to does not exist while checking $direction"
                return
            }
            if (!$existfrom) {
                Report "W" "Target file $To does not have a corresponding source file $from"
                return 
                               
            }
        }
        
        "FORWARD-SOURCECOPY" {
            if  (!$existfrom) {
                Report "E" "Unexpected situation: 'FROM dataset' $from does not exist while checking $direction"
                return                
            }
            if (!$existto) {
                if ($shouldbedone) {
                    Report "W" "Target file $to not found for source file $from "
                    return
                }
                else {
                    Report "C" "Target file $to does not exist yet and should be added in $timeleap days"
                    return
                }
            }
            # If both exits then compare properties
            $attention = $false
            if (($toprops.Length -ne $fromprops.Length) -or ($toprops.LastWriteTime.ToString().Trim() -ne $fromprops.LastWriteTime.ToString().Trim())) {
                if ($fromprops.LastWriteTime -lt $toprops.LastWriteTime) {
                    Report "w" "Source file $from is OLDER than target file $to"
                }
                else {
                    If ($shouldbedone) {
                        Report "W" "Target file differs from source file" 
                        $attention = $true                      
                    }
                    else {
                        Report "C" "Target file differs from sourcefile and should be replaced in $timeleap days"  
                        $attention = $true                     
                    }
                }
            }
            
            if ($attention) {
                $l =  "Source file = ".Padright(20," ") + $from.Padright(90," ") + 
                            "Length = ".PadRight(10," ") + $fromprops.Length.ToString().PadRight(10," ") + "Last update = ".Padright(16," ") + $fromprops.LastWriteTime.ToString("yyyy-MMM-dd HH:mm")  
                Report "B" $l
						
                $l = "Target file = ".Padright(20," ") + $to.Padright(90," ") + 
                        "Length = ".PadRight(10," ") + $toprops.Length.ToString().PadRight(10," ") + "Last update = ".Padright(16," ") + $toprops.LastWriteTime.ToString("yyyy-MMM-dd HH:mm") 
                Report "B" $l
            }
			return

        }
        "BACKWARD-SOURCECOPY" {
            if (!$existto) {
                Report "E" "Unexpected situation: 'TO dataset' $to does not exist while checking $direction"
                return
            }
            if (!$existfrom) {
                
                if ($from.ToUpper().Contains("#ADHC_DELETED_")) {
                    Report "I" "Target file $from will be deleted after programmed delay"
                    return
                } 
                else {
                    Report "W" "Target file $To does not have a corresponding source file $from"
                    return 
                }               
            }
        }
        "FORWARD-NONE" {
            if (!$existfrom) {
                Report "E" "Unexpected situation: 'FROM dataset' $from does not exist while checking $direction"
                return                
            }
            if ($existto) {
                Report "W" "Target file $to not expected for source file $from because process is $myprocess"
                return
            }                   
    
        }
        "BACKWARD-NONE" {
            if (!$existto) {
                Report "E" "Unexpected situation: 'TO dataset' $to does not exist while checking $direction"
                return
            }
            if ($existfrom) {
                Report "W" "Target file $to not expected for source file $from because process is $myprocess"
                return                
            }
            else {
                Report "W" "Target file $to not expected because process is $myprocess (NOTE: source file $from NOT FOUND!)"
                return 
            }
        }
        "FORWARD-MASTER" {
             Report "W" "$direction process $myprocess not expected for module $shortname"
             return
        }
        "BACKWARD-MASTER" {
             if ($shortname.ToUpper() -ne $ADHC_ConfigFile.ToUpper()) {
                Report "W" "Target file $from is not known for proces $myprocess"
                return
            } 
            if ($existfrom) {
                Report "W" "Target file $from not expected for source file $to because process is $myprocess"
            }
            $existmaster = Test-Path $ADHC_MasterXml
            if (!$existmaster) {
                Report "W" "Master XML file $ADHC_MasterXml does not exist foro $to"
                return
            }
            else {
                $masterprops = Get-ItemProperty $ADHC_MasterXml
                

                if ($masterprops.LastWriteTime -gt $toprops.LastWriteTime) {
                
                    $timeDifference = New-TimeSpan –Start $masterprops.LastWriteTime –End $currentDate        
                    If ($timeDifference.Days -ge $mydelay) {
                        $shouldbedone = $true
                        $timeleap = 0
                    }
                    else {
                        $shouldbedone = $false
                        $timeleap = $mydelay - $timeDifference.Days
                           
                    }
                    If ($shouldbedone) {
                        Report "W" "Master file is more recent than config file - regeneration is required" 
                                              
                    }
                    else {
                        Report "I" "Master file $ADHC_MasterXml is more recent than $to - regeneration will be required within $timeleap days"  
                                           
                    }
                    $l =  "Master file = ".Padright(20," ") + $ADHC_MasterXml.Padright(90," ") + 
                            "Last update = ".Padright(16," ") + $masterprops.LastWriteTime.ToString("yyyy-MMM-dd HH:mm")  
                    Report "B" $l
						
                    $l = "Config file = ".Padright(20," ") + $to.Padright(90," ") + 
                         "Last update = ".Padright(16," ") + $toprops.LastWriteTime.ToString("yyyy-MMM-dd HH:mm")  
                    Report "B" $l
                }
                            
                   

            }
        }
        "FORWARD-C#" {
            Report "A" "$direction process $myprocess not yet implemented for module $shortname"
        }
        "BACKWARD-C#" {
            Report "A" "$direction process $myprocess not yet implemented for module $shortname" 
        }
        default {
            Report "E" "$direction process $myprocess UNKNOWN for module $shortname"
            
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

    if (!$ADHC_InitSuccessfull) {
        # Write-Warning "YES"
        throw $ADHC_InitError
    }

# END OF COMMON CODING

    # Init report file 
    $str = $ADHC_DeployCheck.Split("\")   
    $rptdir = $ADHC_OutputDirectory + $str[0]
    New-Item -ItemType Directory -Force -Path $rptdir | Out-Null
    $Report = $ADHC_OutputDirectory + $ADHC_DeployCheck
    Set-Content $Report $Scriptmsg -force

    $StagingList = Get-ChildItem $ADHC_StagingDir -Directory | Select Name,FullName

    # LOOP through all config files
    foreach ($StageDir in $StagingList) {
        
        Report "N" " "
        $msg = "----------"+ $Stagedir.FullName.PadRight(100,"-") 
        Report "N" $msg
        $configfile = $StageDir.Fullname + "\" + $ADHC_ConfigFile             
        
        if (Test-Path $configfile) {
            [xml]$ConfigXML = Get-Content $configfile
            $version = $ConfigXml.ADHCinfo.Version
            Report "I" "Config file = $configfile, version = $version"           
        }
        else {
            $scriptaction = $true
            Report "W" "Configuration file $configfile not found, skipping directory"
            Report "N" " "
            continue
        }
        $nodes = $ConfigXml.ADHCinfo.Nodes
        Report "I" "Target node list: $nodes"
        
        $targetnodelist = $nodes.Split(",")     
                
        if (!($targetnodelist -contains $ADHC_Computer.ToUpper())) {
            Report "I" "Node $ADHC_Computer dus not match nodelist {$targetnodelist}, directory skipped"
            Report "N" " "
            Continue
        }
#=========================================================================================================

        $factory = $ConfigXml.ADHCinfo.Factory
        $subroot = $COnfigXml.ADHCinfo.SubRoot
        $devdir = $factory + $subroot

        $stagingroot = $ConfigXml.ADHCinfo.Stagelib.Root
        $stagingsubroot = $ConfigXml.ADHCinfo.Stagelib.SubRoot
        $Stagingdir = $stagingroot + $stagingsubroot

        $Modules = $ConfigXml.ADHCinfo.Stagelib.Childnodes
        $modulefilter = @()
        foreach ($moduleentry in $Modules) {
            $process = $moduleentry.Process
            $delay = $moduleentry.Delay
            $includes = $moduleentry.Include.SPlit(",")
            $excludes = $moduleentry.Exclude.Split(",")
            $filter = [PSCustomObject] [ordered] @{process = $process;
                                            delay = $delay;    
                                            includes = $includes; 
                                            excludes = $excludes}
            $modulefilter += $filter 
            
        }

        # 1 - Forward  check with FROM = DEV     and TO   = STAGING
        Report "N" " "
        Report "N" "##########                                                                          ########## $subroot"
        Report "N" "########## Checking FORWARD:  D E V E L O P M E N T versus S T A G I N G directory  ########## $subroot"
        Report "N" "##########                                                                          ########## $subroot"
        
        Report "I" "Development directory: $devdir"
        Report "I" "Staging directory: $stagingdir"
        Report "N" " "

        $devmodules = Get-ChildItem "$devdir" -recurse -file  | `
                                    Where-Object {($_.FullName -notlike "*.git*") -and ($_.FullName -notlike "*MyExample*") } | `
                                    Select FullName, Name
        foreach ($naam in $devmodules) {
            # Write-Host $module.FullName
            $toname = $naam.Fullname.ToUpper().Replace($devdir.ToUpper(),$stagingdir)
            CheckModule "Forward" $naam.Name $naam.FullName $toname $modulefilter

        } 

        # 2 - Backward check with TO   = STAGING and FROM = DEV
        Report "N" " "
        Report "N" "##########                                                                          ########## $subroot"
        Report "N" "########## Checking BACKWARD: S T A G I N G versus D E V E L O P M E N T directory  ########## $subroot"
        Report "N" "##########                                                                          ########## $subroot"

        Report "I" "Staging directory: $stagingdir"
        Report "I" "Development directory: $devdir"
        Report "N" " "

        $stagingmodules = Get-ChildItem $stagingdir -recurse -file  | `
                                     Select FullName, Name
        foreach ($naam in $stagingmodules) {
            # Write-Host $module.FullName
            $fromname = $naam.Fullname.ToUpper().Replace($stagingdir.ToUpper(), $devdir)
            CheckModule "Backward" $naam.Name $fromname $naam.FullName $modulefilter

        } 
       

#=========================================================================================================
        
       
        # 3 - Forward  check with FROM = STAGING and TO   = TARGET (may be multiple targets)
        $x = 0
        
        $targetlist = $ConfigXml.ADHCinfo.SelectNodes("//Target")
        
        foreach ($targetentry in $targetlist) {
            $targetroot = $targetentry.Root
            $targetsubroot = $targetentry.SubRoot
            $targetdir = $targetroot + $targetsubroot
            $x = $x + 1
            Report "N" " "
            Report "N" "##########                                                                          ########## $subroot"
            Report "N" "########## Checking FORWARD:  S T A G I N G versus T A R G E T directory ($x)        ########## $subroot"
            Report "N" "##########                                                                          ########## $subroot"   

            Report "I" "Staging directory: $stagingdir"
            Report "I" "Target directory: $targetdir"
            Report "N" " " 
           
        
            $Modules = $targetentry.Childnodes
            $modulefilter = @()
            foreach ($moduleentry in $Modules) {
                $process = $moduleentry.Process
                $delay = $moduleentry.Delay
                $includes = $moduleentry.Include.SPlit(",")
                $excludes = $moduleentry.Exclude.Split(",")
                $filter = [PSCustomObject] [ordered] @{process = $process;
                                                delay = $delay;    
                                                includes = $includes; 
                                                excludes = $excludes}
                $modulefilter += $filter 
            
            }
            
            foreach ($naam in $stagingmodules) {
                # Write-Host $module.FullName
                $toname = $naam.Fullname.ToUpper().Replace($stagingdir.ToUpper(), $targetdir)
                CheckModule "FORWARD" $naam.Name $naam.FullName $toname $modulefilter
            }
        }

        

        # 4 - Backward check with To   = TARGET  and FROM = STAGING
        $x = 0

        foreach ($targetentry in $targetlist) {
            $targetroot = $targetentry.Root
            $targetsubroot = $targetentry.SubRoot
            $targetdir = $targetroot + $targetsubroot
            $x = $x + 1


            Report "N" " "
            Report "N" "##########                                                                          ########## $subroot"
            Report "N" "########## Checking BACKWARD: T A R G E T versus S T A G I N G directory ($x)        ########## $subroot"
            Report "N" "##########                                                                          ########## $subroot" 

            Report "I" "Target directory: $targetdir"
            Report "I" "Staging directory: $stagingdir"
            Report "N" " "
        
            $targetmodules = Get-ChildItem $targetdir -recurse -file  | `
                                     Select FullName, Name

            $Modules = $targetentry.Childnodes
            $modulefilter = @()
            foreach ($moduleentry in $Modules) {
                $process = $moduleentry.Process
                $delay = $moduleentry.Delay
                $includes = $moduleentry.Include.SPlit(",")
                $excludes = $moduleentry.Exclude.Split(",")
                $filter = [PSCustomObject] [ordered] @{process = $process;
                                                delay = $delay;    
                                                includes = $includes; 
                                                excludes = $excludes}
                $modulefilter += $filter 
            
            }

            foreach ($naam in $targetmodules) {
                # Write-Host $module.FullName
                $fromname = $naam.Fullname.ToUpper().Replace($targetdir.ToUpper(), $stagingdir)
                CheckModule "Backward" $naam.Name $fromname $naam.FullName $modulefilter
            }

        }   

#========================================================================================================= 

        $dslroot = $ConfigXml.ADHCinfo.DSL.Root
        $dslsubroot = $ConfigXml.ADHCinfo.DSL.SubRoot
        $dsldir = $dslroot + $dslsubroot
        
        $Modules = $ConfigXml.ADHCinfo.DSL.Childnodes
        $modulefilter = @()
        foreach ($moduleentry in $Modules) {
            $process = "COPY"
            $delay = $moduleentry.Delay
            $includes = $moduleentry.Include.SPlit(",")
            $excludes = $moduleentry.Exclude.Split(",")
            $filter = [PSCustomObject] [ordered] @{process = $process;
                                            delay = $delay;    
                                            includes = $includes; 
                                            excludes = $excludes}
            $modulefilter += $filter 
            
        }       

        # 5 - Forward  check with FROM = STAGING  and TO   = DSL
        Report "N" " "
        Report "N" "##########                                                                          ########## $subroot"
        Report "N" "########## Checking FORWARD:  S T A G I N G versus D S L directory                  ########## $subroot"
        Report "N" "##########                                                                          ########## $subroot"   

        Report "I" "Staging directory: $stagingdir"
        Report "I" "DSL directory: $dsldir"
        Report "N" " "

        foreach ($naam in $stagingmodules) {
            # Write-Host $module.FullName
            $toname = $naam.Fullname.ToUpper().Replace($stagingdir.ToUpper(), $dsldir)
            CheckModule "FORWARD" $naam.Name $naam.FullName $toname $modulefilter
        }

        
        # 6 - Backward check with TO   = DSL     and FROM = STAGING
        Report "N" " "
        Report "N" "##########                                                                          ########## $subroot"
        Report "N" "########## Checking BACKWARD: D S L versus S T A G I N G directory                  ########## $subroot"
        Report "N" "##########                                                                          ########## $subroot"       
        
        Report "I" "DSL directory: $dsldir"
        Report "I" "Staging directory: $stagingdir"
        Report "N" " "
        
        $dslmodules = Get-ChildItem $dsldir -recurse -file  | `
                                     Select FullName, Name 

        foreach ($naam in $dslmodules) {
            # Write-Host $module.FullName
            $fromname = $naam.Fullname.ToUpper().Replace($dsldir.ToUpper(), $stagingdir)
            CheckModule "BACKWARD" $naam.Name $fromname $naam.FullName $modulefilter
        }
    }
} 

catch {
    $global:scripterror = $true
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    $Dump = $_.Exception.ToSTring()
}

finally {
    # Init jobstatus file
    $dir = $ADHC_OutputDirectory + $ADHC_Jobstatus
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $p = $myname.Split(".")
    $process = $p[0]
    $jobstatus = $ADHC_OutputDirectory + $ADHC_Jobstatus + $ADHC_Computer + "_" + $Process + ".jst" 
    
    Add-Content $Report " "

        
    if ($global:scripterror) {
        Add-Content $Report "Failed item = $FailedItem"
        Add-Content $Report "Errormessage = $ErrorMessage"
        Add-Content $Report "Dump info = $Dump"
        $msg = ">>> Script ended abnormally"
        Add-Content $Report $msg

        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "9" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
        Add-Content $jobstatus "Failed item = $FailedItem"
        Add-Content $jobstatus "Errormessage = $ErrorMessage"
        Add-Content $jobstatus "Dump info = $Dump"
        exit 16        
    }
   
    if ($global:scriptaction) {
        $msg = ">>> Script ended normally with action required"
        Add-Content $Report $msg
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "6" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        exit 8
    }

    if ($global:scriptchange) {
        $msg = ">>> Script ended normally with reported changes, but no action required"
        Add-Content $Report $msg
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "3" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        exit 4
    }

    $msg = ">>> Script ended normally without reported changes, and no action required"
    Add-Content $Report $msg
    $dt = Get-Date
    $jobline = $ADHC_Computer + "|" + $process + "|" + "0" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
    Set-Content $jobstatus $jobline
       
    exit 0
   

} 
