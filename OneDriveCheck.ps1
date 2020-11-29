$Version = " -- Version: 3.0"

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

    if (!$ADHC_InitSuccessfull) {
        # Write-Warning "YES"
        throw $ADHC_InitError
    }

# END OF COMMON CODING

    # init flags
    $scripterror = $false
    $scriptaction = $false  

    $OneDrive = $ADHC_OneDrive
    $FileList = Get-ChildItem $OneDrive -recurse  -name -force
    # $FileList | Out-Gridview

    # Init temporary reporting file
    $dir = $ADHC_TempDirectory + $ADHC_OneDriveCheck.Directory
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $TempFile = $dir + $ADHC_OneDriveCheck.Name

    Set-Content $TempFile $Scriptmsg -force
    Add-Content $TempFile "Overview of OneDrive conficts"
    Add-Content $TempFile " "

    foreach ($HostName in $ADHC_Hostlist) {
        $SearchFor1 = "-" + $HostName.ToUpper() + "\."
        $SearchFor1
        $SearchFor2 = "-" + $HostName.ToUpper() + "\Z"
        $SearchFor2
        $SearchFor3 = "-" + $HostName.ToUpper() + "-\d"
        $SearchFor3
        Add-Content $TempFile "Computer $Hostname :"
        $ConflictsFound = $false
        foreach ($FileName in $FileList) {        
            $a = select-string -InputObject $FileName.ToUpper() -pattern $SearchFor1 
            $a
            $b = select-string -InputObject $FileName.ToUpper() -pattern $SearchFor2 
            $b
            $c = select-string -InputObject $FileName.ToUpper() -pattern $SearchFor3 
            $c
            if ($a -or $b -or $c) {
                $ConflictsFound = $true
                Add-Content $TempFile "  ==> $FileName"
                
            }
        
        }
        if (!$ConflictsFound) {
            Add-Content $TempFile "  No Conflicts Found"
        }
        else {
            $scriptaction = $true
        }
    
    }

}
catch {
    $scripterror = $true
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
    
    Add-Content $TempFile " "

        
    if ($scripterror) {
        Add-Content $TempFile "Failed item = $FailedItem"
        Add-Content $TempFile "Errormessage = $ErrorMessage"
        $msg = ">>> Script ended abnormally"
        Add-Content $TempFile $msg
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "9" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        Add-Content $jobstatus "Failed item = $FailedItem"
        Add-Content $jobstatus "Errormessage = $ErrorMessage"
        Add-Content $jobstatus "Dump info = $dump"

        Add-Content $TempFile "Failed item = $FailedItem"
        Add-Content $TempFile "Errormessage = $ErrorMessage"
        Add-Content $TempFile "Dump info = $dump"
        exit 16        
    }
   
    if ($scriptaction) {
        $msg = ">>> Script ended normally with action required"
        Add-Content $TempFile $msg
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "6" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        exit 8
    }

    if ($scriptchange) {
        $msg = ">>> Script ended normally with reported changes, but no action required"
        Add-Content $TempFile $msg
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "3" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        exit 4
    }

    $msg = ">>> Script ended normally without reported changes, and no action required"
    Add-Content $TempFile $msg
    Add-Content $TempFile " "

    try {

        $deffile = $ADHC_OutputDirectory + $ADHC_OneDriveCheck.Directory + $ADHC_OneDriveCheck.Name 
        & $ADHC_CopyMoveScript $TempFile $deffile "MOVE" "REPLACE" $TempFile
    }
    Catch {

    }
    Finally {

        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "0" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        exit 0
    }
}