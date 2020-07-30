
$InformationPreference = "Continue"
$WarningPreference = "Continue"

$Version = " -- Version: 2.0"
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

$StageLIst = Get-ChildItem $ADHC_StagingDir -Directory | Select Name,FullName

New-Item -ItemType Directory -Force -Path $ADHC_ProdCompareDir | Out-Null
$Report = $ADHC_ProdCompareDir + "Report_" +  $ADHC_Computer  +  ".txt"
Set-Content $Report $Scriptmsg -force


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
    $targetnodelist = $ConfigXML.ADHCinfo.Target.Nodes

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
    $DSLnodelist = $ConfigXML.ADHCinfo.DSL.Nodes


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


} 

exit
