$Version = " -- Version: 1.1"

# COMMON coding
CLS

# init flags
$global:scripterror = $false
$global:scriptaction = $false
$global:scriptchange = $false

$global:recordslogged = $false

$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"

# nog:
# - Standaardiseren
# - Doorlooptijd noteren
# - Log met overall statistieken (ping / notping. Bij not ping: welke foutboodschap) 
# - Reportfile
# - Hoogste gebruikte jobnummer rapporteren + gebruik per job

function Report ([string]$level, [string]$line) {
    switch ($level) {
        ("N") {$rptline = $line}
        ("I") {
            $rptline = "Info    *".Padright(10," ") + $line
        }
        ("H") {
            $rptline = "-------->".Padright(10," ") + $line
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
    Add-Content $tempfile $rptline

}
function WriteLog ([string]$Action, [string]$line) {
    $oldrecords = Get-Content $templog 

    $logdate = Get-Date
    $logrec = $logdate.ToSTring("yyyy-MMM-dd HH:mm:ss").PadRight(24," ") + $ADHC_Computer.PadRight(24," ") +
                    (" *** " + $Action + " *** ").Padright(40," ") + $line.PadRight(160," ") + $logdate.ToString("dd-MM-yyyy HH:mm:ss")
    Set-Content $templog $logrec
    $global:recordslogged = $true

    $now = Get-Date

    $nrofnotkeep = 0

    foreach ($record in $oldrecords) {
        $keeprecord = $false
        if ($record.Length -ge 248) {
            $dtstring = $record.Substring(248)
            #$dtstring
            $timest = [datetime]::ParseExact($dtstring,"dd-MM-yyyy HH:mm:ss",$null)
            # $timest.ToString("yyyy-MMM-dd HH:mm:ss")
            $recordage = NEW-TIMESPAN –Start $timest –End $now
            if ($recordage.Days -le 50) {
                $keeprecord = $true    
            }
            else {
                $nrofnotkeep += 1
            }
        }
        if ($keeprecord) {
            Add-Content $templog $record
        }
        
    }
    if ($nrofnotkeep -gt 0 ) {
        $logdate = Get-Date
        $line = "Housekeeping: $nrofnotkeep Old log records deleted"
        $logrec = $logdate.ToSTring("yyyy-MMM-dd HH:mm:ss").PadRight(24," ") + $ADHC_Computer.PadRight(24," ") +
                    (" *** Log Record Purge *** ").Padright(40," ") + $line.PadRight(160," ") + $logdate.ToString("dd-MM-yyyy HH:mm:ss")
        
        Add-Content $templog $logrec 
    } 

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
    & "$LocalInitVar"

    if (!$ADHC_InitSuccessfull) {
        # Write-Warning "YES"
        throw $ADHC_InitError
    }
    $m = & $ADHC_LockScript "Lock" "IpScan" "$enqprocess" 
    
    # END OF COMMON CODING   

    # Init reporting file
    $dir = $ADHC_TempDirectory + $ADHC_IpScan.Directory
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $tempfile = $dir + $ADHC_IpScan.Name

    Set-Content $Tempfile $Scriptmsg -force

    $ENQfailed = $false 
    foreach ($msgentry in $m) {
        $msglvl = $msgentry.level
        if ($msglvl -eq "E") {
            # ENQ failed
            $ENQfailed = $true
        }
        $msgtext = $msgentry.Message
        Report $msglvl $msgtext
    }
    
    if ($ENQfailed) {
        throw "Could not lock resource 'IpScan'"
    } 
    
    # Init log
    $ldir = $ADHC_TempDirectory + $ADHC_IpScanLog.Directory
    New-Item -ItemType Directory -Force -Path $ldir | Out-Null
    $templog = $ldir + $ADHC_IpScanLog.Name

    $deflog = $ADHC_OutputDirectory + $ADHC_IpScanLog.Directory + $ADHC_IpScanLog.Name 
    $defdir = $ADHC_OutputDirectory + $ADHC_IpScanlog.Directory 

    $lt = Test-Path $deflog
    if (!$lt) {
        New-Item -ItemType Directory -Force -Path $defdir | Out-Null
        Set-Content $deflog " " -force
    } 

    # Copy current log to templog
    & $ADHC_CopyMoveScript $deflog $templog "COPY" "REPLACE" $TempFile | Out-Null   


    $base = "192.168.178."    $teller = 0
    $wait = 2 

    $resultlist = @()

    $joblist = @()
    $maxjobs = 8
    $i = 0

    $dt = Get-Date
    Report "I" ">>>>> Start $dt"
    WriteLog "START" ">>>>>"

    do {
        $i += 1
        $jobname = "IPjob" + $i.ToString("000") 
        $jobentry = [PSCustomObject] [ordered] @{Number = $i;
                                           JobName = $jobname;
                                           Status = "INIT";
                                           UseCount = 0}
                                       
        $joblist += $jobentry

    } until ($i -eq $maxjobs)

    do {
        $teller += 1
        $ipaddr = $base + $teller.ToString()
        Write-Host "Processing $ipaddr"
        try {
            $jobslotfound = $false
            do {
                # Get free job slot and if available, put this job in free slot
                foreach ($jobslot in $joblist) {
                    if ($jobslot.Status -ne "BUSY") {
                        $jobname = $jobslot.Jobname
                        $myjob = Start-Job -Name $jobname -ArgumentList $ipaddr -ScriptBlock {
                                    param (
                                        [string]$IpAddress = "Iets"   
                                    )
                                    $InformationPreference = "Continue"
                                    $WarningPreference = "Continue"
                                    $ErrorActionPreference = "Stop"
        
                                    try {
                                        $t = (Test-Connection -ComputerName $ipaddress -Count 2   | Measure-Object -Property ResponseTime -Average).average  
                                        $ping = $true   
                                        $em = "OK"
                                    }
                                    Catch {
                                        $t = $null
                                        $em = $_.Exception.Message
                                        $ping =$false
                                    }
                                    $returnobj = [PSCustomObject] [ordered] @{IPaddress = $ipaddress;
                                                                            Pingtime = $t;
                                                                            Pingable = $ping;
                                                                            Message = $em}
                                    return $returnobj
                    
                        }  
                    
                        if ($jobslot.Status -eq "INIT") {
                            $jobslot | Add-Member -NotePropertyName Job -NotePropertyValue $myjob 
                        }
                        else {
                            $jobslot.Job = $myjob
                        }
                        $jobslot.Status = "BUSY"
                        $jobslot.UseCount +=1
                        $jobslotfound = $true
                        break
                    } 
                }
                # no free slots, wait 1 second and try again
                if (!$jobslotfound) {
                    Report "I" "All jobs busy, wait $wait second(s)"
                    Start-Sleep -s $wait  
                }

                # check all jobs on completion        
                foreach ($jobslot in $joblist) {
                    # Only check busy slots
                    if ($jobslot.Status -ne "BUSY") {
                        continue
                    }
                    #$myjob | Wait-Job -Timeout 30 | Out-Null
                    if ($jobslot.Job) { 
                        $mystate = $jobslot.Job.state
                    }  
                 
                    if ($mystate -eq "Completed") {
                        $mj = $jobslot.Job.Name
                        
                        #write-host "YES"
                        $Response = (Receive-Job -Job $jobslot.Job)
                        $jobslot.Job | Stop-Job | Out-Null
                        # $jobslot.Job | Remove-Job | Out-null
                        $jobslot.Status = "FREE"
                        $resultlist += $Response
                        
                        $ia = $Response.IpAddress
                        Report "I" "==> Remote job $mj ended with status $mystate for Ip Address $ia"
                    }
                       
            
                }
            
        
            } until ($jobslotfound)
        }
        Catch {
            $em = $ErrorMessage = $_.Exception.Message
            Report "E" "ERROR *** $em"
        }
    } until ($teller -ge 255)

    do {
        $alljobscomplete = $true
        # check all remaning jobs on completion        
        foreach ($jobslot in $joblist) {
            # Only check busy slots
            if ($jobslot.Status -ne "BUSY") {
                continue
            }
            else {
                $alljobscomplete = $false
            }
            #$myjob | Wait-Job -Timeout 30 | Out-Null
            if ($jobslot.Job) { 
                $mystate = $jobslot.Job.state
            }  
                 
            if ($mystate -eq "Completed") {
                $mj = $jobslot.Job.Name
                        
                #write-host "YES"
                $Response = (Receive-Job -Job $jobslot.Job)
                $jobslot.Job | Stop-Job | Out-Null
                # $jobslot.Job | Remove-Job | Out-null
                $jobslot.Status = "FREE"
                $resultlist += $Response
                        
                $ia = $Response.IpAddress
                Report "I" "==> Remote job $mj ended with status $mystate for Ip Address $ia"
            }

        }
        Report "I" "Waiting on busy jobs to complete, wait $wait second(s)"
        Start-Sleep -s $wait                         
            

    } until ($alljobscomplete) 
    $dt = Get-Date
    Report "I" ">>>>> End $dt"
    WriteLog "END" ">>>>>"
}
catch {
    
    $global:scripterror = $true
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    $Dump = $_.Exception.ToString()

}
finally {
    $resultlist | Out-Gridview
    # Copy temp log to definitive BEFORE DEQ
    if ($global:recordslogged) {
        & $ADHC_CopyMoveScript  $Templog $deflog "MOVE" "REPLACE" $TempFile | Out-Null
    }
    else {
        Report "I" "No records logged, delete $templog without copy-back"
        Remove-Item $templog
    }

    $m = & $ADHC_LockScript "Free" "IpScan" "$enqprocess"
    foreach ($msgentry in $m) {
        $msglvl = $msgentry.level
        $msgtext = $msgentry.Message
        Report $msglvl $msgtext
    }
    # Init jobstatus file
    $dir = $ADHC_OutputDirectory + $ADHC_Jobstatus
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $p = $myname.Split(".")
    $process = $p[0]
    $jobstatus = $ADHC_OutputDirectory + $ADHC_Jobstatus + $ADHC_Computer + "_" + $Process + ".jst" 
    
    Report "N" " "

    $returncode = 99

    if ($ENQfailed) {
        $msg = ">>> Script could not run"
        Report "E" $msg
        Report "N" " "
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "7" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        Add-Content $jobstatus "Failed item = $FailedItem"
        Add-Content $jobstatus "Errormessage = $ErrorMessage"
        Add-Content $jobstatus "Dump info = $dump"

        Report "E" "Failed item = $FailedItem"
        Report "E" "Errormessage = $ErrorMessage"
        Report "E" "Dump info = $dump"
        $returncode = 12       

    }
        
    if (($global:scripterror) -and ($returncode -eq 99)) {
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

    try { # Free resource and copy temp file
        
        $deffile = $ADHC_OutputDirectory + $ADHC_IpScan.Directory + $ADHC_IpScan.Name 
        & $ADHC_CopyMoveScript $TempFile $deffile "MOVE" "REPLACE" $TempFile "IpScan,$enqprocess"  | Out-Null
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
        Exit $Returncode
        
    }  
   

}
