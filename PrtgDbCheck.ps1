# Dit script checkt de PTG database op onregelmatigheden

cls
$Version = " -- Version: 1.4.1"

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

$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"             

try { 
    $line = "=".PadRight(120,"=")                                            
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
    $m = & $ADHC_LockScript "Lock" "PRTG" "$enqprocess"     

# END OF COMMON CODING

    # Init reporting file
    $odir = $ADHC_TempDirectory + $ADHC_PrtgDbCheck.Directory
    New-Item -ItemType Directory -Force -Path $odir | Out-Null
    $tempfile = $odir + $ADHC_PrtgDbCheck.Name

    Set-Content $tempfile $Scriptmsg -force

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
        throw "Could not lock resource 'PRTG'"
    }

    # Check for invalid sensor states
    $query = "SELECT Group_Device, ID, Type, Object, Sensor, Status, Message_Raw, LastValue
                FROM [PRTG].[dbo].[Sensors]
                where status <> 'ok' or LastValue like '%geconfigureerde lookup%'"
    $result = invoke-sqlcmd -ServerInstance '.\sqlexpress' -Database "PRTG" `
                        -Query "$query" `
                        -ErrorAction Stop
    Report "N" $line
    
    if ($result -eq $null) {
        Report "B" " "
        Report "I" "No invalid sensor states found"
        
    }                        
    else {
        foreach ($rec in $result) {
            Report "B" " "
            if ($rec.Lastvalue -match "geconfigureerde lookup") {
                Report "W" "Invalid Sensor State"
            } 
            else {
                Report "C" "Invalid Sensor State"
            } 
            $msg = "Sensor ID    = " + $rec.ID 
            Report "B" $msg
            $msg = "Group/Device = " + $rec.Group_Device             
            Report "B" $msg
            $msg = "Sensor Name  = " + $rec.Sensor 
            Report "B" $msg
            $msg = "Object       = " + $rec.Object
            Report "B" $msg
            $msg = "Type         = " + $rec.Type
            Report "B" $msg
            $msg = "Status       = " + $rec.Status
            Report "B" $msg 
            $msg = "Message      = " + $rec.Message_Raw
            Report "B" $msg
            $msg = "Last Value   = " + $rec.Lastvalue
            Report "B" $msg
        }
       
    }
    Report "B" " "
    Report "N" $line
    

    # Check for non-standard sensor attributes
    $query = "SELECT   Type,  Object, Sensor, Tags, Interval, Priority, Group_Device, ID
                  FROM [PRTG].[dbo].[Sensors]
                  order by Type,  Object"
    $result = invoke-sqlcmd -ServerInstance '.\sqlexpress' -Database "PRTG" `
                        -Query "$query" `
                        -ErrorAction Stop
    $curtype = "plop"
    $curobject = "plop"
    $nonstandardfound = $false
    foreach ($rec in $result) {
        If (($curtype -ne $rec.Type) -or ($curobject -ne $rec.Object)) {
                
            $curtype = $rec.Type
            $curobject = $rec.Object
            $std_Interval = $rec.Interval
            $std_Priority = $rec.Priority
            $std_Tags = $rec.Tags
        }
                       
        if (($rec.Interval -ne $std_Interval) -or 
            ($rec.Priority -ne $std_Priority) -or 
            ($rec.Tags -ne $std_Tags)) {
            $standaard = $false
        }
        else {
            $standaard = $true
        }
        if (!$standaard) {
            $nonstandardfound = $true
            Report "B" " "
            Report "W" "Sensor Attributes not Standard"
            $msg = "Sensor       = " + $rec.ID 
            Report "B" $msg
            $msg = "Group/Device = " + $rec.Group_Device             
            Report "B" $msg
            $msg = "Sensor Name  = " + $rec.Sensor 
            Report "B" $msg
            $msg = "Object       = " + $rec.Object
            Report "B" $msg
            $msg = "Type         = " + $rec.Type 
            Report "B" $msg
            if ($rec.Interval -ne $std_Interval) {
                $msg = "Interval     = " + $rec.Interval + " ====> Should be: " + $std_Interval
                Report "B" $msg 
            }
            if ($rec.Priority -ne $std_Priority) {
                $msg = "Priority     = " + $rec.Priority + " ====> Should be: " + $std_Priority
                Report "B" $msg 
            }
            if ($rec.Tags -ne $std_Tags) {
                $msg = "Tags         = " + $rec.Tags + " ====> Should be: " + $std_Tags
                Report "B" $msg 
            }

        }
 
    }
    if (!$nonstandardfound) {
        Report "B" " "
        Report "I" "No nonstandard sensor attributes found"
        
    }
    Report "B" " "
    Report "N" $line
   

    # Check fot empty channels
    $query = "Select * FROM
                (SELECT  [SensorID],[Name],[Number],[Lastvalue]      
                FROM [PRTG].[dbo].[Channels]
                 where ((lastvalue = 'geen gegevens') or (lastvalue = '')) and (Name <> 'Uitvaltijd') ) AS a 
                 join 
                (SELECT  [ID],[Sensor],[Type],[Status],[Object],[Group_Device]      
                FROM [PRTG].[dbo].[Sensors]) AS b 
                on a.SensorID = b.ID 
                where (b.[Status] = 'ok' and b.[Type] = 'EXE/Script Geavanceerd')"
    $result = invoke-sqlcmd -ServerInstance '.\sqlexpress' -Database "PRTG" `
                        -Query "$query" `
                        -ErrorAction Stop
    if ($result -eq $null) {
        Report "B" " "
        Report "I" "No empty channels found on healthy sensors"
        
    }                        
    else {
         foreach ($rec in $result) {
            Report "B" " "
            Report "W" "Empty channel"
            
            $msg = "Sensor ID    = " + $rec.SensorID 
            Report "B" $msg
            $msg = "Group/Device = " + $rec.Group_Device             
            Report "B" $msg
            $msg = "Sensor Name  = " + $rec.Sensor 
            Report "B" $msg
            $msg = "Object       = " + $rec.Object
            Report "B" $msg
            $msg = "Type         = " + $rec.Type
            Report "B" $msg
            $msg = "Channel name = " + $rec.Name
            Report "B" $msg
            $msg = "Channel nr.  = " + $rec.Number
            Report "B" $msg
            $msg = "Last Value   = " + $rec.Lastvalue
            Report "B" $msg
        }
        
    }
    Report "B" " "
    Report "N" $line


    # Check whether all CORE equipment is presented as DEVICE
    $query = "SELECT [IPaddress], Naam, [Type] FROM [PRTG].[dbo].[IPadressen] where type = 'CORE'"
    $result = invoke-sqlcmd -ServerInstance '.\sqlexpress' -Database "PRTG" `
                        -Query "$query" `
                        -ErrorAction Stop
    $unmonitored = $false
    foreach ($ip in $result) {
        $query2 = "SELECT * FROM [PRTG].[dbo].[Devices] where host = '" + $ip.IPaddress.Trim() + "'"
        $result2 = invoke-sqlcmd -ServerInstance '.\sqlexpress' -Database "PRTG" `
                        -Query "$query2" `
                        -ErrorAction Stop
        if ($result2 -eq $null) {
            $unmonitored = $true
            Report "B" " "
            Report "W" "Core device not being monitored in PRTG"
            $msg = "Naam         = " + $ip.Naam 
            Report "B" $msg
            $msg = "IP Address   = " + $ip.IPaddress
            Report "B" $msg
            $msg = "Type         = " + $ip.Type
            Report "B" $msg
        }
    }
    if (!$unmonitored) {
        Report "B" " "
        Report "I" "All core equipment is being monitored"
         
    }
    Report "B" " "
    Report "N" $line
   
    

}

catch {
        $global:scripterror = $true
        
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        $Dump = $_.Exception.ToString()
        write-warning "$ErrorMessage"
}

finally { 


    $m = & $ADHC_LockScript "Free" "PRTG" "$enqprocess"
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
        
        $deffile = $ADHC_OutputDirectory + $ADHC_PrtgDbCheck.Directory + $ADHC_PrtgDbCheck.Name 
        & $ADHC_CopyMoveScript $TempFile $deffile "MOVE" "REPLACE" $TempFile "PRTG,$enqprocess"  
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