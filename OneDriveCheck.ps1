$Version = " -- Version: 4.1"

# COMMON coding
CLS

$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"

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
        ("G") {
            $rptline = "GIT:    *".Padright(10," ") + $line
        }
        default {
            $rptline = "Error   *".Padright(10," ") + "Messagelevel $level is not valid"
            $global:scripterror = $true
        }
    }
    Add-Content $tempfile $rptline

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
    & "$LocalInitVar"

    if (!$ADHC_InitSuccessfull) {
        # Write-Warning "YES"
        throw $ADHC_InitError
    }

# END OF COMMON CODING

    # init flags
    $global:scripterror = $false
    $global:scriptaction = $false
    $global:scriptchange = $false  

    $OneDrive = $ADHC_OneDrive
    $FileList = Get-ChildItem $OneDrive -recurse  -name -force
    # $FileList | Out-Gridview

    # Init temporary reporting file
    $dir = $ADHC_TempDirectory + $ADHC_OneDriveCheck.Directory
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $TempFile = $dir + $ADHC_OneDriveCheck.Name

    Set-Content $TempFile $Scriptmsg -force
    Report "N" " "
    $msg = "----------Overview of OneDrive conficts".PadRight(120,"-") 
    Report "N" $msg
    Report "N" " "
    Report "N" $line
    Report "N" " "
    foreach ($HostName in $ADHC_Hostlist) {
        Report "I" "Processing computer $Hostname"

        $searchlist = @()
        $SearchFor1 = "-" + $HostName.ToUpper() + "\."
        $searchlist += $searchfor1        
        $SearchFor2 = "-" + $HostName.ToUpper() + "\Z"
        $searchlist += $searchfor2
        $SearchFor3 = "-" + $HostName.ToUpper() + "-\d"
        $searchlist += $searchfor3
        
        $ConflictsFound = $false
        foreach ($pattern in $searchlist) {
            Report "I" "Search pattern: $pattern" 
            foreach ($FileName in $FileList) {
                      
                $a = select-string -InputObject $FileName.ToUpper() -pattern $pattern 
                
                if ($a) {
                    $ConflictsFound = $true
                    Report "W" "==> $FileName"
                
                }
        
            }
        }
        if (!$ConflictsFound) {
           Report "N" " "
           Report "I" "No Conflicts Found"
        }
        else {
            $global:scriptaction = $true
        }
        Report "N" " "
        Report "N" $line
        Report "N" " "
    
    }

}
catch {
    $global:scripterror = $true
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
    
    Report "N" " "
    $returncode = 99
        
    if ($global:scripterror) {
        Report "E" ">>> Script ended abnormally"
        Report "N" " " 
       
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "9" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline       
        Add-Content $jobstatus "Failed item = $FailedItem"
        Add-Content $jobstatus "Errormessage = $ErrorMessage"
        Add-Content $jobstatus "Dump info = $dump"

        Report "E" "Failed item = $FailedItem"
        Report "E" "Errormessage = $ErrorMessage"
        Report "E" "Dump info = $dump"
        $returncode = 16       
    }
   
    if (($global:scriptaction) -and ($returncode -eq 99)) {
        Report "W" ">>> Script ended normally with action required"
        Report "N" " " 

        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "6" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode = 8
    }

    if (($global:scriptchange) -and ($returncode -eq 99)) {
        Report "C" ">>> Script ended normally with reported changes, but no action required"
        Report "N" " " 
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "3" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode = 4
    }

    if ($returncode -eq 99) {
        Report "I" ">>> Script ended normally without reported changes, and no action required"
        Report "N" " "
        
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "0" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline 
        $returncode = 0
    }

    $d = Get-Date
    $Datum = " -- Date: " + $d.ToString("dd-MM-yyyy")
    $Tijd = " -- Time: " + $d.ToString("HH:mm:ss")
    $Scriptmsg = "*** ENDED ***** " + $mypath + " -- PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node
    Report "N" $scriptmsg
    Report "N" " "
    


    try {

        $deffile = $ADHC_OutputDirectory + $ADHC_OneDriveCheck.Directory + $ADHC_OneDriveCheck.Name 
        & $ADHC_CopyMoveScript $TempFile $deffile "MOVE" "REPLACE" $TempFile
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
        Write-Information $Scriptmsg
       
        exit $returncode
    }
}