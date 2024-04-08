$Version = " -- Version: 4.2"

# COMMON coding
CLS

$StatusOBJ = [PSCustomObject] [ordered] @{Scripterror = $false;
                                          ScriptChange = $false;
                                          ScriptAction = $false;
                                          }

$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Continue"

function Report ([string]$level, [string]$line, [object]$Obj, [string]$file ) {
    switch ($level) {
        ("N") {$rptline = $line}
        ("H") {
            $rptline = "-------->".Padright(10," ") + $line
        }
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
            $obj.scriptchange = $true
        }
        ("W") {
            $rptline = "Warning *".Padright(10," ") + $line
            $obj.scriptaction = $true
        }
        ("E") {
            $rptline = "Error   *".Padright(10," ") + $line
            $obj.scripterror = $true
        }
        ("G") {
            $rptline = "GIT:    *".Padright(10," ") + $line
        }
        default {
            $rptline = "Error   *".Padright(10," ") + "Messagelevel $level is not valid"
            $Obj.Scripterror = $true
        }
    }
    Add-Content $file $rptline

}

$line = "=".PadRight(120,"=")

try {
    $Node = " -- Node: " + $env:COMPUTERNAME
    $d = Get-Date
    $Datum = " -- Date: " + $d.ToString("dd-MM-yyyy")
    $Tijd = " -- Time: " + $d.ToString("HH:mm:ss")
       
    $myname = $MyInvocation.MyCommand.Name
    $FullScriptName = $MyInvocation.MyCommand.Definition
    $mypath = $FullScriptName.Replace($MyName, "")

    $Scriptmsg = "*** STARTED *** " + $mypath + " -- PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node
    Write-Information $Scriptmsg 

    $LocalInitVar = $mypath + "InitVar.PS1"
    $InitObj = & "$LocalInitVar" "OBJECT"

    if ($Initobj.AbEnd) {
        # Write-Warning "YES"
        throw "INIT script $LocalInitVar Failed"

    }

# END OF COMMON CODING

    $OneDrive = $ADHC_OneDrive
    $FileList = Get-ChildItem $OneDrive -recurse  -name -force
    # $FileList | Out-Gridview

    # Init temporary reporting file
    $dir = $ADHC_TempDirectory + $ADHC_OneDriveCheck.Directory
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $TempFile = $dir + $ADHC_OneDriveCheck.Name

    Set-Content $TempFile $Scriptmsg -force

    foreach ($entry in $InitObj.MessageList){
        Report $entry.Level $entry.Message $StatusObj $Tempfile
    }

    Report "N" " " $StatusObj $Tempfile
    $msg = "----------Overview of OneDrive conficts".PadRight(120,"-") 
    Report "N" $msg $StatusObj $Tempfile
    Report "N" " " $StatusObj $Tempfile
    Report "N" $line $StatusObj $Tempfile
    Report "N" " " $StatusObj $Tempfile
    foreach ($HostName in $ADHC_Hostlist) {
        Report "I" "Processing computer $Hostname" $StatusObj $Tempfile

        $searchlist = @()
        $SearchFor1 = "-" + $HostName.ToUpper() + "\."
        $searchlist += $searchfor1        
        $SearchFor2 = "-" + $HostName.ToUpper() + "\Z"
        $searchlist += $searchfor2
        $SearchFor3 = "-" + $HostName.ToUpper() + "-\d"
        $searchlist += $searchfor3
        
        $ConflictsFound = $false
        foreach ($pattern in $searchlist) {
            Report "I" "Search pattern: $pattern"  $StatusObj $Tempfile
            foreach ($FileName in $FileList) {
                      
                $a = select-string -InputObject $FileName.ToUpper() -pattern $pattern 
                
                if ($a) {
                    $ConflictsFound = $true
                    Report "W" "==> $FileName" $StatusObj $Tempfile
                
                }
        
            }
        }
        if (!$ConflictsFound) {
           Report "N" " " $StatusObj $Tempfile
           Report "I" "No Conflicts Found" $StatusObj $Tempfile
        }
        else {
            $StatusObj.scriptaction = $true
        }
        Report "N" " " $StatusObj $Tempfile
        Report "N" $line $StatusObj $Tempfile
        Report "N" " " $StatusObj $Tempfile
    
    }

}
catch {
    $StatusObj.scripterror = $true
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    $Dump = $_.Exception.ToString()
}
finally {
    # Init jobstatus file
    $dir = $ADHC_OutputDirectory + $ADHC_Jobstatus
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $p = $myname.Split(".")
    $process = $p[0]
    $jobstatus = $ADHC_OutputDirectory + $ADHC_Jobstatus + $ADHC_Computer + "_" + $Process + ".jst" 
    
    Report "N" " " $StatusObj $Tempfile
    $returncode = 99
        
    if ($StatusObj.scripterror) {
        Report "E" ">>> Script ended abnormally" $StatusObj $Tempfile
        Report "N" " "  $StatusObj $Tempfile
       
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "9" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline       
        Add-Content $jobstatus "Failed item = $FailedItem"
        Add-Content $jobstatus "Errormessage = $ErrorMessage"
        Add-Content $jobstatus "Dump info = $dump"

        Report "E" "Failed item = $FailedItem" $StatusObj $Tempfile
        Report "E" "Errormessage = $ErrorMessage" $StatusObj $Tempfile
        Report "E" "Dump info = $dump" $StatusObj $Tempfile
        $returncode = 16       
    }
   
    if (($StatusObj.scriptaction) -and ($returncode -eq 99)) {
        Report "W" ">>> Script ended normally with action required" $StatusObj $Tempfile
        Report "N" " "  $StatusObj $Tempfile

        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "6" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode = 8
    }

    if (($StatusObj.scriptchange) -and ($returncode -eq 99)) {
        Report "C" ">>> Script ended normally with reported changes, but no action required" $StatusObj $Tempfile
        Report "N" " " $StatusObj $Tempfile
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "3" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode = 4
    }

    if ($returncode -eq 99) {
        Report "I" ">>> Script ended normally without reported changes, and no action required" $StatusObj $Tempfile
        Report "N" " " $StatusObj $Tempfile
        
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "0" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline 
        $returncode = 0
    }

    try {

        $deffile = $ADHC_OutputDirectory + $ADHC_OneDriveCheck.Directory + $ADHC_OneDriveCheck.Name 
        $CopMov = & $ADHC_CopyMoveScript $TempFile $deffile "MOVE" "REPLACE" $TempFile
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        $Dump = $_.Exception.ToSTring()
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "9" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
        Add-Content $jobstatus "Failed item = $FailedItem"
        Add-Content $jobstatus "Errormessage = $ErrorMessage"
        Add-Content $jobstatus "Dump info = $Dump"
        $Returncode = 16       


    }
    Finally {
        $d = Get-Date
        $Datum = " -- Date: " + $d.ToString("dd-MM-yyyy")
        $Tijd = " -- Time: " + $d.ToString("HH:mm:ss") 
        $Scriptmsg = "*** ENDED ***** " + $mypath + " -- PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node
        Report "N" $scriptmsg $StatusObj $deffile
        Report "N" " " $StatusObj $deffile
        Write-Host $scriptmsg
        Exit $Returncode
    }
}