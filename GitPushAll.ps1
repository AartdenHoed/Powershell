$Version = " -- Version: 1.0"

# COMMON coding
CLS
# init flags
$global:scripterror = $false
$global:scriptaction = $false
$global:scriptchange = $false

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
    Add-Content $gitstatus $rptline

}

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

# END OF COMMON CODING

    # Init reporting file
    $str = $ADHC_GitPushAll.Split("\")
    $odir = $ADHC_OutputDirectory + $str[0]
    New-Item -ItemType Directory -Force -Path $odir | Out-Null
    $gitstatus = $ADHC_OutputDirectory + $ADHC_GitPushAll

    Set-Content $gitstatus $Scriptmsg -force  

    Set-Location -Path $ADHC_DevelopDir
    $gitdirs = Get-ChildItem "*.git" -Recurse -Force
    $ofile = $odir + "\gitoutput.txt"
    $line = "=".PadRight(120,"=")

    foreach ($gitentry in $gitdirs) {
        $gdir = $gitentry.FullName
   
        $gdir = $gdir.replace(".git","")
        Report "N" ""
        $msg = "----------Directory $gdir".PadRight(120,"-") 
        Report "N" $msg

        Set-Location $gdir
        Write-Host ">>> $gdir"       
             
        & {git push ADHCentral master} 6>&1 5>&1 4>&1 3>&1 2>&1 > $ofile 

        $a = Get-Content $ofile
       
        Report "N" " "
        Report "I" "==> Start of GIT output"
        
        Report "N" $line

        $ok = $false
        foreach ($l in $a) {
            Report "B" $l
            if ($l -eq "git : Everything up-to-date")  {
                $ok = $true
                $showline = $l
            }
            if (!$ok) {
                $showline = $l
            }
            
        }
        Write-Host "       $showline"        
            
        Report "N" $line
        
        Report "I" "==> End of GIT output"
        if ($ok) {
            Report "I" "==> Nothing to push"
        } 
        else {
            Report "C" "==> Push executed"
        }
        
        Report "N" " "
        Remove-Item $ofile
    }

    Set-Location -Path $ADHC_RemoteDir
    $remdirs = Get-ChildItem "*.git" -Recurse -Force

    foreach ($rementry in $remdirs) {
        $rdir = $rementry.FullName

        Report "N" ""
        $msg = "----------Remote Repository $rdir".PadRight(120,"-") 
        Report "N" $msg

        Set-Location $rdir
        Write-Host ">>> $rdir"

        & {git push GITHUB master} 6>&1 5>&1 4>&1 3>&1 2>&1 > $ofile 
        Report "N" " "
        Report "I" "==> Start of GIT output"
        Report "N" $line

        $a = Get-Content $ofile
       
        $ok = $false
        foreach ($l in $a) {
            Report "B" $l
            if ($l -eq "Everything up-to-date")  {
                $ok = $true
                $showline = $l
            }
            if (!$ok) {
                $showline = $l
            }  
        } 
        
        Write-Host "        $showline"       
        Report "N" $line
        
        Report "I" "==> End of GIT output"
        if ($ok) {
            Report "I" "==> Nothing to push"
        } 
        else {
            Report "C" "==> Push executed"
        }        
        Report "N" " "

        Remove-Item $ofile
    }
#}
#catch {
#    $global:scripterror = $true
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
    
    Report "N" " "

        
    if ($global:scripterror) {
        $msg = ">>> Script ended abnormally"
        Report "E" $msg
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "9" + "|" + $version + "|" + $dt.ToString()
        Set-Content $jobstatus $jobline
       
        Add-Content $jobstatus "Failed item = $FailedItem"
        Add-Content $jobstatus "Ërrormessage = $ErrorMessage"
        exit 16        
    }
   
    if ($global:scriptaction) {
        $msg = ">>> Script ended normally with action required"
        Report "W" $msg
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "6" + "|" + $version + "|" + $dt.ToString()
        Set-Content $jobstatus $jobline
       
        exit 8
    }

    if ($global:scriptchange) {
        $msg = ">>> Script ended normally with reported changes, but no action required"
        Report "C" $msg
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "3" + "|" + $version + "|" + $dt.ToString()
        Set-Content $jobstatus $jobline
       
        exit 4
    }

    $msg = ">>> Script ended normally without reported changes, and no action required"
    Report "I" $msg
    $dt = Get-Date
    $jobline = $ADHC_Computer + "|" + $process + "|" + "0" + "|" + $version + "|" + $dt.ToString()
    Set-Content $jobstatus $jobline
       
    exit 0
   

#} 
