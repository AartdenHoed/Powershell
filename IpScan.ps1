param (
    [int]$maxjobs = 8 ,
    [int]$wait = 2 ,
    [int]$maxtry = 4
)

# COMMON coding
CLS
$Version = " -- Version: 2.4.2"

# init flags
$StatusOBJ = [PSCustomObject] [ordered] @{Scripterror = $false;
                                          ScriptChange = $false;
                                          ScriptAction = $false;
                                          RecordsLogged = $false
                                          }

$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Continue"

$nrofwaits = 0

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

function WriteLog ([string]$Action, [string]$line, [object]$obj, [string]$logfile) {
    $oldrecords = Get-Content $logfile 

    $logdate = Get-Date
    $logrec = $logdate.ToSTring("yyyy-MMM-dd HH:mm:ss").PadRight(24," ") + $ADHC_Computer.PadRight(24," ") +
                    (" *** " + $Action + " *** ").Padright(40," ") + $line.PadRight(160," ") 
    Set-Content $logfile $logrec
    $obj.recordslogged = $true

    $now = Get-Date

    $nrofnotkeep = 0

    foreach ($record in $oldrecords) {
        $keeprecord = $false
        if ($record.Length -ge 20) {
            $dtstring = $record.Substring(0,20)
            #$s = "'" + $dtstring + "'"
            #$s
            $timest = [datetime]::ParseExact($dtstring,"yyyy-MMM-dd HH:mm:ss",$null)
            #$timest.ToString("yyyy-MMM-dd HH:mm:ss")
            $recordage = NEW-TIMESPAN –Start $timest –End $now
            if ($recordage.Days -le 10) {
                $keeprecord = $true    
            }
            else {
                $nrofnotkeep += 1
            }
        }
        if ($keeprecord) {
            Add-Content $logfile $record
        }
        
    }
    if ($nrofnotkeep -gt 0 ) {
        $logdate = Get-Date
        $line = "Housekeeping: $nrofnotkeep Old log records deleted"
        $logrec = $logdate.ToSTring("yyyy-MMM-dd HH:mm:ss").PadRight(24," ") + $ADHC_Computer.PadRight(24," ") +
                    (" *** Log Record Purge *** ").Padright(40," ") + $line.PadRight(160," ")
        
        Add-Content $logfile $logrec 
    } 

}

function Totals ([string]$ip, [boolean]$pingable, [string]$message, [int]$retrycount, [object]$mylists) {
    $found = $false
    $genericmsg = $message.Replace($ip, "<IPaddress>")

    foreach ($stat in $mylists.totalslist) {
        if (($pingable -eq $stat.Pingable) -and ($genericmsg.Trim() -eq $stat.Message.Trim())) {
            $found = $true
            break
        }
        
    }
    if ($found) {
        $stat.Total += 1
    }
    else {
        $statentry = [PSCustomObject] [ordered] @{Pingable = $pingable;
                                           Message = $genericmsg;
                                           Total = 1} 
        $mylists.totalslist += $statentry
    }

    foreach ($retr in $mylists.Retrylist) {
        if ($retr.RetryCount -eq $retrycount) {
            $foundr = $true
            break
        }
        
    }
    if ($foundr) {
        $retr.Total += 1
    }
    else {
        $retrentry = [PSCustomObject] [ordered] @{RetryCount = $retrycount;
                                                    Total = 1} 
        $mylists.Retrylist += $retrentry
    }


}

try {
    $Totalslist = @()
    $Retrylist = @()
    $ListOBJ = [PSCustomObject] [ordered] @{TotalsList =$Totalslist;
                                            RetryList = $RetryList;
                                            }

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
    $m = & $ADHC_LockScript "Lock" "IpScan" "$enqprocess" 10 "OBJECT"
    
    # END OF COMMON CODING   

    # Init reporting file
    $dir = $ADHC_TempDirectory + $ADHC_IpScan.Directory
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $tempfile = $dir + $ADHC_IpScan.Name

    Set-Content $Tempfile $Scriptmsg -force

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
    $CopMov = & $ADHC_CopyMoveScript $deflog $templog "COPY" "REPLACE" $TempFile    
    
    $sdt = Get-Date
    $mline = ">".PadRight(99,">")
    Report "I" ">>>>> Start $sdt" $StatusObj $Tempfile
    WriteLog "START" $mline $StatusObj $templog

    # Create the object that will hold the jobs

    $joblist = @()
    $i = 0
    do {
        $i += 1
        $jobname = "IPjob" + $i.ToString("000") 
        $jobentry = [PSCustomObject] [ordered] @{Number = $i;
                                           JobName = $jobname;
                                           Status = "INIT";
                                           UseCount = 0}
                                       
        $joblist += $jobentry

    } until ($i -ge $maxjobs)

    # Create the object that will hold all IP's
    $base = "192.168.178."    $maxip = 254    $teller = 0
    $iplist = @()
    do {
        $teller += 1
        $ipaddr = $base + $teller.ToString()
        $ipobj = [PSCustomObject] [ordered] @{IPaddress = $ipaddr;
                                              Pingtime = 0;
                                              Pingable = $false;
                                              Started = $false;
                                              Processed = $false;
                                              Message = "init";
                                              Trycount = 0;
                                              TimeStamp = Get-Date }
        $iplist += $ipobj

    } until ($teller -ge $maxip)
    $ipaddr = "192.168.179.1"
    $ipobj = [PSCustomObject] [ordered] @{IPaddress = $ipaddr;
                                              Pingtime = 0;
                                              Pingable = $false;
                                              Started = $false;
                                              Processed = $false;
                                              Message = "init";
                                              Trycount = 0;
                                              TimeStamp = Get-Date }
    $iplist += $ipobj

    # Loop through IP list and process each IP    
    
    $alljobscompleted = $false 
    $allIPsprocessed = $false  
    do {
        # Get unprocessed IP
        $ipfound = $false
        if (!$allIPsprocessed) {
            foreach ($ip in $iplist) {
                if (!$ip.started) {
                    $ip.started = $true
                    $ipfound = $true
                    $currentip = $ip
                    break
                }
            } 
        }

        # Schedule unprocessed IP in free jobs
        
        if ($ipfound) {
            $ipaddr = $currentip.IPaddress
            write-Host "Processing $ipaddr"
            $jobslotfound = $false
            foreach ($jobslot in $joblist) {
                if ($jobslot.Status -ne "BUSY") {
                    $jobname = $jobslot.Jobname
                    $myjob = Start-Job -Name $jobname -ArgumentList $ipaddr -ScriptBlock {
                                param (
                                    [string]$IpAddress = "Iets"   
                                )
                                $ErrorActionPreference = "Stop"     
                                try {
                                    
                                    $t = (Test-Connection -ComputerName $ipaddress -Count 2  | Measure-Object -Property ResponseTime -Average).average  
                                    $ping = $true   
                                    $em = "OK"
                                }
                                Catch {
                                    $t = $null
                                    $em = $_.Exception.Message
                                    $ping =$false
                                }
                                $ts = Get-Date -Format “yyyy-MM-dd HH:mm:ss.fff”
                                $returnobj = [PSCustomObject] [ordered] @{IPaddress = $ipaddress;
                                                                        Pingtime = $t;
                                                                        Pingable = $ping;
                                                                        Message = $em;
                                                                        TimeStamp = $ts}
                                return $returnobj
                    
                    }
                    Report "I" "==> Remote job $jobname started for Ip Address $ipaddr" $StatusObj $Tempfile
                    
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
            # no free slots, wait xx second(s) and try again
            if (!$jobslotfound) {
                # Reset started status
                foreach ($ip in $iplist) {
                    if ($ip.IPaddress.Trim() -eq $ipaddr.Trim()) {
                        $ip.Started = $false
                        break
                    }

                }
                Report "I" "All jobs busy, wait $wait second(s)" $StatusObj $Tempfile
                $nrofwaits += 1
                Start-Sleep -s $wait  
            }
        }
        else {
            $allIPsprocessed = $true 
            Report "I" "Almost ready, waiting for all jobs to complete" $StatusObj $Tempfile
            $nrofwaits += 1
            Start-Sleep -s $wait  
        }
        
        # check all jobs on completion 
        $busyjobsfound = $false       
        foreach ($jobslot in $joblist) {
            # Only check busy slots
            if ($jobslot.Status -ne "BUSY") {
                continue
            }
            $busyjobsfound = $true
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
                
                $ia = $Response.IpAddress
                Report "I" "==> Remote job $mj ended with status $mystate for Ip Address $ia" $StatusObj $Tempfile

                # set response in IPlist
                foreach ($ip in $iplist) {
                    if ($ip.IPaddress.Trim() -eq $Response.ipaddress.Trim()) {
                        $ip.Pingtime = $Response.Pingtime;
                        $ip.Pingable = $Response.Pingable                        
                        $ip.Message = $Response.Message;
                        $ip.Trycount += 1
                        $ip.TimeStamp = $Response.TimeStamp
                        if (($Response.Message.Contains("het zoeken in de database")) -or 
                            ($Response.Message.Trim() -eq "OK") -or 
                            ($ip.Trycount -ge $maxtry))  {
                            $ip.Processed = $true;    
                        }
                        else {
                            if (($Response.Message.Contains("Fout vanwege tekort aan bronnen")) -or 
                                ($Response.Message.Contains("Unexpected error")) ) {
                                $ip.Started = $false 
                                $ip.Processed = $false 
                                $allIPsprocessed = $false 
                            }
                            else {
                                $m = $Response.Message
                                Report "W" "Unexpected message encountered: '$m'"  $StatusObj $Tempfile
                                $ip.Processed = $true;  
                            }  
                        }
                        break
                    }

                }

            }
                       
            
        }
        if (!$busyjobsfound) {
            $alljobscompleted = $true
        }

    } until ($alljobscompleted -and $allIPsprocessed) 

    foreach ($entry in $joblist) {
        $freq = $entry.usecount
        $name = $entry.jobname
        Report "I" "Job $name has been used $freq times" $StatusObj $Tempfile
        WriteLog "UseCount" "$Name :  $freq" $StatusObj $templog
    }

        

}
catch {
    
    $StatusObj.scripterror = $true
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    $Dump = $_.Exception.ToString()

}
finally {
    # $iplist | Out-Gridview

    foreach ($result in $iplist) {
        Totals $result.IpAddress $Result.Pingable $Result.Message $Result.Trycount $ListOBJ

        if ($result.Trycount -gt 1) {
            $i = $result.IPaddress
            $c = $Result.Trycount
            $m = $Result.Message
            Report "A" "IP Address $i with try count $c has return message '$m'" $StatusObj $Tempfile

        }

        $query = "SELECT * FROM [dbo].[IPadressen] WHERE [IPaddress] = '" + $result.IpAddress + "'"
        $db = invoke-sqlcmd -ServerInstance ".\SQLEXPRESS" -Database "PRTG" `
                        -Query "$query" `
                        -ErrorAction Stop
         If ($Result.Pingable) {
                $p = "Y"
            }
            else {
                $p = "N"
            }
        if (!$db) { 
            # Insert (record does not yet exist)
           
            $query = "INSERT INTO [dbo].[IPadressen]
           ([Naam]
           ,[IPaddress]
           ,[MACaddress]
           ,[AltMAC]
           ,[Type]
           ,[Authorized]
           ,[Pingable]
           ,[TimeStamp])
        VALUES (
           'FREE','" + 
           $result.IpAddress + 
           "','n/a',NULL,'Unused','N','" + 
           $p + "','"+ $result.TimeStamp + "')"
           
        }
        else {
            # Update with only pingstatus
            $query = "UPDATE [dbo].[IPadressen] SET [Pingable] = '" + $p + 
                                               "', [TimeStamp] = '" + $result.TimeStamp +  "' WHERE [IPaddress] = '" + $result.IpAddress + "'"

        }
        invoke-sqlcmd -ServerInstance ".\SQLEXPRESS" -Database "PRTG" `
                        -Query "$query" `
                        -ErrorAction Stop
           
            
    }
    # $Totalslist | Out-GridView
    Report "I" "Statistics:"  $StatusObj $Tempfile
    foreach ($tot in $ListOBJ.Totalslist) {
        
        $t = $tot.Total 
        if ($tot.Pingable) {
            $p = "pingable"
        }
        else {
            $p = "NOT pingable"
        }
        $m = $tot.Message
        Report "B" "$t IP Addresses are $p with message: $m" $StatusObj $Tempfile
        WriteLog "Statistics" "$t IP Addresses are $p with message: $m" $StatusObj $templog
    }
    foreach ($ret in $ListOBJ.Retrylist) {
        
        $r = $ret.Total 
        $c = $ret.Retrycount
        Report "B" "$r IP Addresses needed $c tries" $StatusObj $Tempfile
        WriteLog "Statistics" "$r IP Addresses needed $c tries" $StatusObj $templog
    }
    Report "B" "Number of waits for busy jobs: $nrofwaits" $StatusObj $Tempfile
    WriteLog "Statistics" "Number of waits for busy jobs: $nrofwaits" $StatusObj $templog
    $edt = Get-Date
    $diff = NEW-TIMESPAN –Start $sdt –End $edt
    $sec = $diff.Seconds
    $min = $diff.Minutes
    WriteLog "Duration" "Script execution took $min minutes and $sec seconds" $StatusObj $templog
    Report "I" "$Script execution took $min minutes and $sec seconds" $StatusObj $Tempfile
    Report "I" ">>>>> End $edt" $StatusObj $Tempfile
    WriteLog "END" $mline $StatusObj $templog

    # Copy temp log to definitive BEFORE DEQ
    if ($StatusObj.recordslogged) {
        $CopMov = & $ADHC_CopyMoveScript  $Templog $deflog "MOVE" "REPLACE" $TempFile 
    }
    else {
        Report "I" "No records logged, delete $templog without copy-back" $StatusObj $Tempfile
        Remove-Item $templog
    }

    $m = & $ADHC_LockScript "Free" "IpScan" "$enqprocess" 10 "OBJECT"
    foreach ($msgentry in $m.MessageList) {
        $msglvl = $msgentry.level
        $msgtext = $msgentry.Message
        Report $msglvl $msgtext $StatusObj $Tempfile
    }
    # Init jobstatus file
    $dir = $ADHC_OutputDirectory + $ADHC_Jobstatus
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $p = $myname.Split(".")
    $process = $p[0]
    $jobstatus = $ADHC_OutputDirectory + $ADHC_Jobstatus + $ADHC_Computer + "_" + $Process + ".jst" 
    
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
        Report "E" ">>> Script ended abnormally" $StatusObj $Tempfile
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
        $returncode = 16        
    }
   
    if (($StatusObj.scriptaction) -and ($returncode -eq 99)) {
        Report "W" ">>> Script ended normally with action required" $StatusObj $Tempfile
        Report "N" " " $StatusObj $Tempfile
        
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
   
    try { # Free resource and copy temp file
        
        $deffile = $ADHC_OutputDirectory + $ADHC_IpScan.Directory + $ADHC_IpScan.Name 
        $CopMOv = & $ADHC_CopyMoveScript $TempFile $deffile "MOVE" "REPLACE" $TempFile "IpScan,$enqprocess"  
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
