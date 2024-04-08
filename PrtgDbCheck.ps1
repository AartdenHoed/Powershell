# Dit script checkt de PTG database op onregelmatigheden

cls
$Version = " -- Version: 1.5"


# init flags
$StatusOBJ = [PSCustomObject] [ordered] @{Scripterror = $false;
                                          ScriptChange = $false;
                                          ScriptAction = $false;
                                          }

function Report ([string]$level, [string]$line, [object]$Obj, [string]$file ) {
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

$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Continue"             

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
    $InitObj = & "$LocalInitVar" "OBJECT"

    if ($Initobj.AbEnd) {
        # Write-Warning "YES"
        throw "INIT script $LocalInitVar Failed"

    }
    $m = & $ADHC_LockScript "Lock" "PRTG" "$enqprocess" 10 "OBJECT" 
   
# END OF COMMON CODING

    # Init reporting file
    $odir = $ADHC_TempDirectory + $ADHC_PrtgDbCheck.Directory
    New-Item -ItemType Directory -Force -Path $odir | Out-Null
    $tempfile = $odir + $ADHC_PrtgDbCheck.Name
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
        throw "Could not lock resource 'PRTG'"
    }

    # Check for invalid sensor states
    $query = "SELECT Group_Device, ID, Type, Object, Sensor, Status, Message_Raw, LastValue
                FROM [PRTG].[dbo].[Sensors]
                where status <> 'ok' or LastValue like '%geconfigureerde lookup%'"
    $result = invoke-sqlcmd -ServerInstance '.\sqlexpress' -Database "PRTG" `
                        -Query "$query" `
                        -ErrorAction Stop
    Report "N" $line $StatusObj $Tempfile
    
    if ($result -eq $null) {
        Report "B" " " $StatusObj $Tempfile
        Report "I" "No invalid sensor states found" $StatusObj $Tempfile
        
    }                        
    else {
        foreach ($rec in $result) {
            Report "B" " " $StatusObj $Tempfile
            if ($rec.Lastvalue -match "geconfigureerde lookup") {
                Report "W" "Invalid Sensor State" $StatusObj $Tempfile
            } 
            else {
                Report "C" "Invalid Sensor State" $StatusObj $Tempfile
            } 
            $msg = "Sensor ID    = " + $rec.ID 
            Report "B" $msg $StatusObj $Tempfile
            $msg = "Group/Device = " + $rec.Group_Device             
            Report "B" $msg $StatusObj $Tempfile
            $msg = "Sensor Name  = " + $rec.Sensor 
            Report "B" $msg $StatusObj $Tempfile
            $msg = "Object       = " + $rec.Object
            Report "B" $msg $StatusObj $Tempfile
            $msg = "Type         = " + $rec.Type
            Report "B" $msg $StatusObj $Tempfile
            $msg = "Status       = " + $rec.Status
            Report "B" $msg $StatusObj $Tempfile
            $msg = "Message      = " + $rec.Message_Raw
            Report "B" $msg $StatusObj $Tempfile
            $msg = "Last Value   = " + $rec.Lastvalue
            Report "B" $msg $StatusObj $Tempfile
        }
       
    }
    Report "B" " " $StatusObj $Tempfile
    Report "N" $line $StatusObj $Tempfile
    

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
            Report "B" " " $StatusObj $Tempfile
            Report "W" "Sensor Attributes not Standard" $StatusObj $Tempfile
            $msg = "Sensor       = " + $rec.ID 
            Report "B" $msg $StatusObj $Tempfile
            $msg = "Group/Device = " + $rec.Group_Device             
            Report "B" $msg $StatusObj $Tempfile
            $msg = "Sensor Name  = " + $rec.Sensor 
            Report "B" $msg $StatusObj $Tempfile
            $msg = "Object       = " + $rec.Object
            Report "B" $msg $StatusObj $Tempfile
            $msg = "Type         = " + $rec.Type 
            Report "B" $msg $StatusObj $Tempfile
            if ($rec.Interval -ne $std_Interval) {
                $msg = "Interval     = " + $rec.Interval + " ====> Should be: " + $std_Interval
                Report "B" $msg $StatusObj $Tempfile
            }
            if ($rec.Priority -ne $std_Priority) {
                $msg = "Priority     = " + $rec.Priority + " ====> Should be: " + $std_Priority
                Report "B" $msg $StatusObj $Tempfile
            }
            if ($rec.Tags -ne $std_Tags) {
                $msg = "Tags         = " + $rec.Tags + " ====> Should be: " + $std_Tags
                Report "B" $msg $StatusObj $Tempfile
            }

        }
 
    }
    if (!$nonstandardfound) {
        Report "B" " " $StatusObj $Tempfile
        Report "I" "No nonstandard sensor attributes found" $StatusObj $Tempfile
        
    }
    Report "B" " " $StatusObj $Tempfile
    Report "N" $line $StatusObj $Tempfile
   

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
        Report "B" " " $StatusObj $Tempfile
        Report "I" "No empty channels found on healthy sensors" $StatusObj $Tempfile
        
    }                        
    else {
         foreach ($rec in $result) {
            Report "B" " " $StatusObj $Tempfile
            Report "W" "Empty channel" $StatusObj $Tempfile
            
            $msg = "Sensor ID    = " + $rec.SensorID 
            Report "B" $msg $StatusObj $Tempfile
            $msg = "Group/Device = " + $rec.Group_Device             
            Report "B" $msg $StatusObj $Tempfile
            $msg = "Sensor Name  = " + $rec.Sensor 
            Report "B" $msg $StatusObj $Tempfile
            $msg = "Object       = " + $rec.Object
            Report "B" $msg $StatusObj $Tempfile
            $msg = "Type         = " + $rec.Type
            Report "B" $msg $StatusObj $Tempfile
            $msg = "Channel name = " + $rec.Name
            Report "B" $msg $StatusObj $Tempfile
            $msg = "Channel nr.  = " + $rec.Number
            Report "B" $msg $StatusObj $Tempfile
            $msg = "Last Value   = " + $rec.Lastvalue
            Report "B" $msg $StatusObj $Tempfile
        }
        
    }
    Report "B" " " $StatusObj $Tempfile
    Report "N" $line $StatusObj $Tempfile


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
            Report "B" " " $StatusObj $Tempfile
            Report "W" "Core device not being monitored in PRTG" $StatusObj $Tempfile
            $msg = "Naam         = " + $ip.Naam 
            Report "B" $msg $StatusObj $Tempfile
            $msg = "IP Address   = " + $ip.IPaddress
            Report "B" $msg $StatusObj $Tempfile
            $msg = "Type         = " + $ip.Type
            Report "B" $msg $StatusObj $Tempfile
        }
    }
    if (!$unmonitored) {
        Report "B" " " $StatusObj $Tempfile
        Report "I" "All core equipment is being monitored" $StatusObj $Tempfile
         
    }
    Report "B" " " $StatusObj $Tempfile
    Report "N" $line $StatusObj $Tempfile
   
    

}

catch {
        $StatusObj.scripterror = $true
        
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        $Dump = $_.Exception.ToString()
        write-warning "$ErrorMessage"
}

finally { 


    $m = & $ADHC_LockScript "Free" "PRTG" "$enqprocess" 10 "OBJECT" 
    foreach ($msgentry in $m.MessgeList) {
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
        
        $deffile = $ADHC_OutputDirectory + $ADHC_PrtgDbCheck.Directory + $ADHC_PrtgDbCheck.Name 
        $CopMov = & $ADHC_CopyMoveScript $TempFile $deffile "MOVE" "REPLACE" $TempFile "PRTG,$enqprocess"  
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