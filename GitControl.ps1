$Version = " -- Version: 2.0"

# COMMON coding
CLS

$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Continue"              # PUSH creating error still has to be solved!

#try {                                             PUSH creating error still has to be solved!
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

    # init flags
    $scripterror = $false
    $scriptaction = $false
    $scriptchange = $false

# END OF COMMON CODING



    # Init reporting file
    $str = $ADHC_SourceControl.Split("/")
    $odir = $ADHC_OutputDirectory + $str[0]
    New-Item -ItemType Directory -Force -Path $odir | Out-Null
    $gitstatus = $ADHC_OutputDirectory + $ADHC_SourceControl

    Set-Content $gitstatus $Scriptmsg -force  

    Set-Location -Path $ADHC_DevelopDir
    $gitdirs = Get-ChildItem "*.git" -Recurse -Force
    $ofile = $odir + "/gitoutput.txt"

    foreach ($gitentry in $gitdirs) {
        $gdir = $gitentry.FullName
   
        $gdir = $gdir.replace(".git","")
        Add-Content $gitstatus ""
        Add-Content $gitstatus "Directory $gdir"

        Set-Location $gdir
        Write-Host ">>> $gdir"
       
        & {git status} 6>&1 5>&1 4>&1 3>&1 2>&1 > $ofile 
        
        $a = Get-Content $ofile
        $x = $a[1]
        Write-Host "    $x"
        if ($a[1] -eq "nothing to commit, working tree clean") {
            Add-Content $gitstatus "==> No uncommitted changes"
        }
        else {
            Add-Content $gitstatus "==> Uncommitted changes    ***"
            $scriptchange = $true
        }
        Remove-Item $ofile

        #&{git log ADHCentral/master..HEAD} 6>&1 5>&1 4>&1 3>&1 2>&1 > $ofile
        
        & {git push ADHCentral master --dry-run} 6>&1 5>&1 4>&1 3>&1 2>&1 > $ofile 

        $a = Get-Content $ofile
        $x = $a[0]
        Write-Host "    $x"
        if ($a[0] -eq "git : Everything up-to-date")  {
            Add-Content $gitstatus "==> No unpushed commits"
        }
        else {
            Add-Content $gitstatus "==> Unpushed commits       ***"
            $scriptaction = $true
        }
        Remove-Item $ofile
    }
#}
#catch {
#    $scripterror = $true
#    $ErrorMessage = $_.Exception.Message
#    $FailedItem = $_.Exception.ItemName
#}
#finally {
    # Init jobstatus file
    $jdir = $ADHC_OutputDirectory + $ADHC_Jobstatus
    New-Item -ItemType Directory -Force -Path $jdir | Out-Null
    $p = $myname.Split(".")
    $process = $p[0]
    $jobstatus = $ADHC_OutputDirectory + $ADHC_Jobstatus + $ADHC_Computer + "_" + $Process + ".jst" 
    
    Add-Content $Gitstatus " "

        
    if ($scripterror) {
        $msg = ">>> Script ended abnormally"
        Add-Content $gitstatus $msg
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "9" + "|" + $version + "|" + $dt.ToString()
        Set-Content $jobstatus $jobline
       
        Add-Content $jobstatus "Failed item = $FailedItem"
        Add-Content $jobstatus "Ërrormessage = $ErrorMessage"
        exit 16        
    }
   
    if ($scriptaction) {
        $msg = ">>> Script ended normally with action required"
        Add-Content $gitstatus $msg
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "6" + "|" + $version + "|" + $dt.ToString()
        Set-Content $jobstatus $jobline
       
        exit 8
    }

    if ($scriptchange) {
        $msg = ">>> Script ended normally with reported changes, but no action required"
        Add-Content $gitstatus $msg
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "3" + "|" + $version + "|" + $dt.ToString()
        Set-Content $jobstatus $jobline
       
        exit 4
    }

    $msg = ">>> Script ended normally without reported changes, and no action required"
    Add-Content $gitstatus $msg
    $dt = Get-Date
    $jobline = $ADHC_Computer + "|" + $process + "|" + "0" + "|" + $version + "|" + $dt.ToString()
    Set-Content $jobstatus $jobline
       
    exit 0
   

#} 
