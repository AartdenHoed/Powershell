$Version = " -- Version: 10.5.1"

# COMMON coding
CLS
# init flags
$StatusOBJ = [PSCustomObject] [ordered] @{Scripterror = $false;
                                          ScriptChange = $false;
                                          ScriptAction = $false;
                                          }

$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"

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

try {                                        
    $Node = " -- Node: " + $env:COMPUTERNAME
    $d = Get-Date
    $Datum = " -- Date: " + $d.ToString("dd-MM-yyyy")
    $Tijd = " -- Time: " + $d.ToString("HH:mm:ss")

    $myname = $MyInvocation.MyCommand.Name
    $enqprocess = $myname.ToUpper().Replace(".PS1","")
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
    $m = & $ADHC_LockScript "Lock" "Git" "$enqprocess" 10 "OBJECT"   

# END OF COMMON CODING

    # Init reporting file
    $odir = $ADHC_TempDirectory + $ADHC_GitCheck.Directory
    New-Item -ItemType Directory -Force -Path $odir | Out-Null
    $tempfile = $odir + $ADHC_Gitcheck.Name

    Set-Content $tempfile $Scriptmsg -force 

    foreach ($entry in $InitObj.MessageList){
        Report $entry.Level $entry.Message $StatusObj $Tempfile
    }
    
    $ENQfailed = $false  
    foreach ($msgentry in $m.MessageList) {
        $msglvl = $msgentry.level
        if ($msglvl -eq "E") {
            # ENQ failed
            $ENQfailed = $true
        }
        $msgtext = $msgentry.Message
        Report $msglvl $msgtext $StatusObj $Tempfile
    }
    
    if ($ENQfailed) {
        throw "Could not lock resource 'Git'"
    }

    Report "N" "" $StatusObj $Tempfile
    $a = & git --version
    $msg = "GIT version: $a" 
    Report "I" $msg $StatusObj $Tempfile
    Report "N" "" $StatusObj $Tempfile


    Set-Location -Path $ADHC_DevelopDir
    $gitdirs = Get-ChildItem "*.git" -Force -Directory
    
    $line = "=".PadRight(120,"=")

    $alarmlist = @()
    
    foreach ($gitentry in $gitdirs) {
        $gdir = $gitentry.FullName          
        
        Report "N" "" $StatusObj $Tempfile
        $msg = "----------Directory $gdir".PadRight(120,"-") 
        Report "N" $msg $StatusObj $Tempfile

        Set-Location $gdir
        Write-Host ">>> $gdir"

        $ErrorActionPreference = "Continue"  
       
        & {git status} 6>&1 5>&1 4>&1 3>&1 2>&1 | Tee-Object -Variable a

        $ErrorActionPreference = "Stop"  
        
        Report "N" " " $StatusObj $Tempfile
        Report "B" "git status" $StatusObj $Tempfile
        Report "N" $line $StatusObj $Tempfile
        Report "B" "==> Start of GIT output" $StatusObj $Tempfile
        foreach ($l in $a) {
            Report "G" $l $StatusObj $Tempfile
        }
        Report "B" "==> End of GIT output" $StatusObj $Tempfile
        Report "N" $line $StatusObj $Tempfile

        if (($a -like "*error:*") -or ($a -like "*fatal:*")) {
            Report "W" "==> Git Status command failed" $StatusObj $Tempfile
            $alarm = [PSCustomObject] [ordered] @{Desc = "Git Status Command failed";
                                                  Repo = $gdir}
            $alarmlist += $alarm            
        }
        else {
        
            if ($a -like "*nothing to commit, working tree clean*") {
                Report "I" "==> No uncommitted changes" $StatusObj $Tempfile
            }
            else {
                Report "C" "==> Uncommitted changes    ***" $StatusObj $Tempfile
                $alarm = [PSCustomObject] [ordered] @{Desc = "Uncommitted changes";
                                                      Repo = $gdir}
                $alarmlist += $alarm
            
            } 
        }

        $ErrorActionPreference = "Continue"  
        
        & {git push ADHCentral master --dry-run} 6>&1 5>&1 4>&1 3>&1 2>&1 | Tee-Object -Variable a 

        $ErrorActionPreference = "Stop" 
        
        Report "N" " " $StatusObj $Tempfile
        Report "B" "git push ADHCentral master --dry-run" $StatusObj $Tempfile
        Report "N" $line $StatusObj $Tempfile
        Report "B" "==> Start of GIT output" $StatusObj $Tempfile
        foreach ($l in $a) {
            Report "G" $l $StatusObj $Tempfile
        }
        Report "B" "==> End of GIT output" $StatusObj $Tempfile
        Report "N" $line $StatusObj $Tempfile
        
        if (($a -like "*error:*") -or ($a -like "*fatal:*")) {
            Report "W" "==> Git Push command (dry run ADHCentral) failed" $StatusObj $Tempfile
            $alarm = [PSCustomObject] [ordered] @{Desc = "Git Push command (dry run ADHCentral) failed";
                                                  Repo = $gdir}
            $alarmlist += $alarm            
        }
        else { 
                        
            if ($a -like "*Everything up-to-date*")  {
                Report "I" "==> No unpushed commits" $StatusObj $Tempfile
            }
            else {
                Report "W" "==> Unpushed commits       ***" $StatusObj $Tempfile
                $alarm = [PSCustomObject] [ordered] @{Desc = "Unpushed commits (ADHCentral)";
                                                      Repo = $gdir}
                $alarmlist += $alarm
            
            }
        }
        Report "N" $line $StatusObj $Tempfile
        Report "N" " " $StatusObj $Tempfile

         $ErrorActionPreference = "Continue"  

        & {git push GITHUB master --dry-run} 6>&1 5>&1 4>&1 3>&1 2>&1 | Tee-Object -Variable a

        $ErrorActionPreference = "Stop"  
                                   
        Report "N" " " $StatusObj $Tempfile
        Report "B" "git push GITHUB master --dry-run" $StatusObj $Tempfile
        Report "N" $line $StatusObj $Tempfile
        Report "B" "==> Start of GIT output" $StatusObj $Tempfile
        foreach ($l in $a) {
            Report "G" $l $StatusObj $Tempfile
        }
        Report "B" "==> End of GIT output" $StatusObj $Tempfile
        Report "N" $line $StatusObj $Tempfile

        if (($a -like "*error:*") -or ($a -like "*fatal:*")) {
            Report "W" "==> Git Push command (dry run GITHUB) failed" $StatusObj $Tempfile
            $alarm = [PSCustomObject] [ordered] @{Desc = "Git Push command (dry run GITHUB) failed";
                                                  Repo = $gdir}
            $alarmlist += $alarm            
        }
        else { 
                
            if ($a -like "*Everything up-to-date*")  {
                 Report "I" "==> No unpushed commits" $StatusObj $Tempfile
            }
            else {
                Report "W" "==> Unpushed commits       ***" $StatusObj $Tempfile
                $alarm = [PSCustomObject] [ordered] @{Desc = "Unpushed commits (GITHUB)";
                                                      Repo = $gdir}
                $alarmlist += $alarm
            }
        }
        Report "N" $line $StatusObj $Tempfile
        Report "N" " "  $StatusObj $Tempfile
   
        
        
    }    

    Set-Location -Path $ADHC_RemoteDir
    $remdirs = Get-ChildItem "*.git" -Force -Directory

    foreach ($rementry in $remdirs) {
        $rdir = $rementry.FullName

        Report "N" "" $StatusObj $Tempfile
        $msg = "----------Remote Repository $rdir".PadRight(120,"-") 
        Report "N" $msg $StatusObj $Tempfile

        Set-Location $rdir
        Write-Host ">>> $rdir"

        $ErrorActionPreference = "Continue"  
       
        & {git rev-parse --is-bare-repository} 6>&1 5>&1 4>&1 3>&1 2>&1 | Tee-Object -Variable a

        $ErrorActionPreference = "Stop"  
        
        Report "N" " " $StatusObj $Tempfile
        Report "B" "git rev-parse --is-bare-repository" $StatusObj $Tempfile
        Report "N" $line $StatusObj $Tempfile
        Report "B" "==> Start of GIT output" $StatusObj $Tempfile
        foreach ($l in $a) {
            Report "G" $l $StatusObj $Tempfile
        }
        Report "B" "==> End of GIT output" $StatusObj $Tempfile
        Report "N" $line $StatusObj $Tempfile

        if (($a -like "*error:*") -or ($a -like "*fatal:*")) {
            Report "W" "==> Git Status command failed" $StatusObj $Tempfile
            $alarm = [PSCustomObject] [ordered] @{Desc = "Git Status Command failed";
                                                  Repo = $rdir}
            $alarmlist += $alarm            
        }
        else {
            if ($a -like "*true*")  {
                 Report "I" "==> Repository is bare (= OK)" $StatusObj $Tempfile
            }
            else {
                Report "W" "==> Non-bare repository ***" $StatusObj $Tempfile
                $alarm = [PSCustomObject] [ordered] @{Desc = "Non-bare repository";
                                                      Repo = $rdir}
                $alarmlist += $alarm
            }
                        
        }

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
    $jdir = $ADHC_OutputDirectory + $ADHC_Jobstatus
    New-Item -ItemType Directory -Force -Path $jdir | Out-Null
    $p = $myname.Split(".")
    $process = $p[0]
    $jobstatus = $ADHC_OutputDirectory + $ADHC_Jobstatus + $ADHC_Computer + "_" + $Process + ".jst" 
    
    Report "N" " " $StatusObj $Tempfile

    Report "I" "Short report:" $StatusObj $Tempfile
    foreach ($al in $alarmlist) {
        $d = $al.Desc
        $r = $al.Repo
        $l = $r.PadRight(80," ") + "===> " + $d
        Report "B" "$l" $StatusObj $Tempfile
    }
    Report "N" " " $StatusObj $Tempfile

    $returncode = 99

    if ($ENQfailed) {
        $msg = ">>> Script could not run"
        Report "E" $msg $StatusObj $Tempfile
        Report "N" " " $StatusObj $Tempfile
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "7" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        Add-Content $jobstatus "Failed item = $FailedItem"
        Add-Content $jobstatus "Errormessage = $ErrorMessage"
        Add-Content $jobstatus "Dump info = $dump"

        Report "E" "Failed item = $FailedItem" $StatusObj $Tempfile
        Report "E" "Errormessage = $ErrorMessage" $StatusObj $Tempfile
        Report "E" "Dump info = $dump" $StatusObj $Tempfile
        $returncode = 12       

    }
        
    if (($StatusObj.scripterror) -and ($returncode -eq 99)) {
        $msg = ">>> Script ended abnormally"
        Report "E" $msg $StatusObj $Tempfile
        Report "N" " " $StatusObj $Tempfile
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "9" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        Add-Content $jobstatus "Failed item = $FailedItem"
        Add-Content $jobstatus "Errormessage = $ErrorMessage"
        Add-Content $jobstatus "Dump info = $dump"

        Report "E" "Failed item = $FailedItem" $StatusObj $Tempfile
        Report "E" "Errormessage = $ErrorMessage" $StatusObj $Tempfile
        Report "E" "Dump info = $dump" $StatusObj $Tempfile
        $retruncode = 16       
    }
   
    if (($StatusObj.scriptaction) -and ($returncode -eq 99)) {
        $msg = ">>> Script ended normally with action required"
        Report "W" $msg $StatusObj $Tempfile
        Report "N" " " $StatusObj $Tempfile
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "6" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode = 8
    }

    if (($StatusObj.scriptchange) -and ($returncode -eq 99)) {
        $msg = ">>> Script ended normally with reported changes, but no action required"
        Report "C" $msg $StatusObj $Tempfile
        Report "N" " " $StatusObj $Tempfile
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "3" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode = 4
    }

    if ($returncode -eq 99) {

        $msg = ">>> Script ended normally without reported changes, and no action required"
        Report "I" $msg $StatusObj $Tempfile
        Report "N" " " $StatusObj $Tempfile
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "0" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
        
        $returncode = 0

    }
        
    
    try { # Free resource and copy temp file
        
        $m = & $ADHC_LockScript "Free" "Git" "$enqprocess" "10" "OBJECT" 
        foreach ($msgentry in $m.MessageList) {
            $msglvl = $msgentry.level
            $msgtext = $msgentry.Message
            Report $msglvl $msgtext $StatusObj $Tempfile
        }

        $deffile = $ADHC_OutputDirectory + $ADHC_GitCheck.Directory + $ADHC_GitCheck.Name 
        $CopMov = & $ADHC_CopyMoveScript $TempFile $deffile "MOVE" "REPLACE" $TempFile "GIT,$enqprocess"  
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
