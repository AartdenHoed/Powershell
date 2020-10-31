$Version = " -- Version: 2.2"

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

    # Init reporting file
    $str = $ADHC_ConflictRpt.Split("/")
    $dir = $ADHC_OutputDirectory + $str[0]
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $TxtFile = $ADHC_OutputDirectory + $ADHC_ConflictRpt

    Set-Content $TxtFile $Scriptmsg
    Add-Content $TxtFile "Overview of OneDrive conficts"
    Add-Content $TxtFile " "

    foreach ($HostName in $ADHC_Hostlist) {
        $SearchFor1 = "-" + $HostName.ToUpper() + "\."
        $SearchFor1
        $SearchFor2 = "-" + $HostName.ToUpper() + "\Z"
        $SearchFor2
        $SearchFor3 = "-" + $HostName.ToUpper() + "-\d"
        $SearchFor3
        Add-Content $TxtFile "Computer $Hostname :"
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
                Add-Content $TxtFile "  ==> $FileName"
                
            }
        
        }
        if (!$ConflictsFound) {
            Add-Content $TxtFile "  No Conflicts Found"
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
}
finally {
    # Init jobstatus file
    $dir = $ADHC_OutputDirectory + $ADHC_Jobstatus
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $p = $myname.Split(".")
    $process = $p[0]
    $jobstatus = $ADHC_OutputDirectory + $ADHC_Jobstatus + $ADHC_Computer + "_" + $Process + ".jst" 
    
    Add-Content $Txtfile " "

        
    if ($scripterror) {
        Add-Content $TxtFile "Failed item = $FailedItem"
        Add-Content $TxtFile "Errormessage = $ErrorMessage"
        $msg = ">>> Script ended abnormally"
        Add-Content $TxtFile $msg
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "9" + "|" + $version + "|" + $dt.ToString()
        Set-Content $jobstatus $jobline
       
        Add-Content $jobstatus "Failed item = $FailedItem"
        Add-Content $jobstatus "Errormessage = $ErrorMessage"
        exit 16        
    }
   
    if ($scriptaction) {
        $msg = ">>> Script ended normally with action required"
        Add-Content $TxtFile $msg
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "6" + "|" + $version + "|" + $dt.ToString()
        Set-Content $jobstatus $jobline
       
        exit 8
    }

    if ($scriptchange) {
        $msg = ">>> Script ended normally with reported changes, but no action required"
        Add-Content $TxtFile $msg
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "3" + "|" + $version + "|" + $dt.ToString()
        Set-Content $jobstatus $jobline
       
        exit 4
    }

    $msg = ">>> Script ended normally without reported changes, and no action required"
    Add-Content $TXTfile $msg
    $dt = Get-Date
    $jobline = $ADHC_Computer + "|" + $process + "|" + "0" + "|" + $version + "|" + $dt.ToString()
    Set-Content $jobstatus $jobline
       
    exit 0
}