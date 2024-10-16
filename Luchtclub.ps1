$ScriptVersion = " -- Version: 1.2"

# COMMON coding
CLS
$StatusOBJ = [PSCustomObject] [ordered] @{Scripterror = $false;
                                          ScriptChange = $false;
                                          ScriptAction = $false;
                                          }
$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"
$myhost = $ADHC_Computer.ToUpper()


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

   
# END OF COMMON CODING   

    # Init reporting file
    
    $dir = $ADHC_TempDirectory + $ADHC_LuchtClub.Directory
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $Tempfile = $dir + $ADHC_LuchtClub.Name
    Set-Content $Tempfile $Scriptmsg -force

    foreach ($entry in $InitObj.MessageList){
        Report $entry.Level $entry.Message $StatusObj $Tempfile
    }


    # Get all sensors of luchtclub
    Report "I" "Get list of sensor objects (Thing) <$cururi> " $StatusObj $Tempfile

    $skip = 0
    $top = 100
    $sensoritemlist = @()
    $listcount = 999
    do { 
        
        $suffix = '&$top=' + $top.ToString() + '&$skip=' + $skip.ToString() 
        $uri = 'https://api-samenmeten.rivm.nl/v1.0/Things?%24filter=startswith(name,%27LUC%27)'+ $suffix
        $cururi = $uri           
        
        $SensorobjList = Invoke-RestMethod  -Uri $uri 

        # $SensorobjList.value
        $skip = $skip + $top
        $listcount = $SensorobjList.value.Count

        Report "I" "$listcount Sensors found" $StatusObj $Tempfile

        foreach ($Sensorobj in $SensorobjList.value) {
            $sensoritemlist += $SensorObj
        }

    } until ($listcount -lt 100)


    $Totalsensors = $sensoritemlist.Count
    write-host "$Totalsensors sensors found"
    Report "I" "$Totalsensors sensors found" $StatusObj $Tempfile

    $excluded = 0

    $templist = @()
    $Currentdate = Get-Date
    $CurrentTime = $Currentdate.ToString()

    Report "I" "Get last measurement of each sensor " $StatusObj $Tempfile

    $Totaal = $Totalsensors
    $n = 0
    $percentiel = [math]::floor($totaal / 10)
    $part = $percentiel

    foreach ($sensoritem in $sensoritemlist) {
        $n = $n + 1;
        if ($n -eq $part) {
            $percentage = [math]::round($n * 100 / $totaal)
            Write-host "Processing $n van $totaal ($percentage %)"
            $part = $part + $percentiel
        }         

        $sensorid = $sensoritem.'@iot.id'
        $sensorname = $sensoritem.name
        $sensorgemeente = $sensoritem.properties.owner
        $sensorproject =  $sensoritem.properties.project

        # next links to follow 
        $locationlink = $Sensoritem.'Locations@iot.navigationLink'
        $datastreamlink = $Sensoritem.'Datastreams@iot.navigationLink'

        # get location of sensor
        $uri = $locationlink
        $cururi = $uri                
        
        $Locationobj = Invoke-RestMethod  -Uri $uri 

        $Oosterlengte = $locationobj.value.location.coordinates[0]
        $Noorderbreedte = $locationobj.value.location.coordinates[1]

        # get data from sensor
        $uri = $datastreamlink
        $cururi = $uri
    
        $Datastreamobj = Invoke-RestMethod  -Uri $uri 
    
        $Metingen = @()        
    
        # loop through metingen
        for ($y=0; $y -le $Datastreamobj.value.count-1; $y++) {
            $measurement = $Datastreamobj.value[$y]
            $MetingObj = [PSCustomObject] [ordered] @{Unit = "?";
                                            Name = "?";
                                            Description = "?";
                                          Observationslink = "?";
                                          Propertylink = "?";
                                          LastMeasureTime = '';
                                          CurrentTime = '';
                                          MinutesAgo = 0;
                                          LastResult = 0
                                          }
            $MetingObj.Unit = $measurement.unitOfMeasurement.Symbol
            $MetingObj.Observationslink = $measurement.'Observations@iot.navigationLink'
            $MetingObj.Propertylink = $measurement.'ObservedProperty@iot.navigationLink'

            # get the most recent data of this meting
            $uri2 = $MetingObj.Observationslink
            $cururi = $uri2
        
            $ObservationsObj = Invoke-RestMethod  -Uri $uri2 

            # the first meting in the list is the most recent one
            if ($ObservationsObj.value[0].phenomenonTime) {
                $MetingObj.LastMeasureTime = Get-Date -Date $ObservationsObj.value[0].phenomenonTime 
            }
            else {
                $MetingObj.LastMeasureTime = Get-Date -Date "2000-01-01T00:00:00"
            }
            $Hulp = Get-Date -Date $MetingObj.LastMeasureTime       
            $diff = NEW-TIMESPAN -Start $Hulp -End $CurrentDate                
            $MetingObj.MinutesAgo = [math]::round($diff.TotalMinutes,0)
            $MetingObj.LastResult = $ObservationsObj.value[0].result
            $MetingObj.CurrentTime = $CurrentTime
            
            
            # Get the properties of this meting
            $uri3 = $Metingobj.PropertyLink
            $cururi = $uri3
        
            $PropertyObj = Invoke-RestMethod  -Uri $uri3 

            $MetingObj.Name = $PropertyObj.name
            $MetingObj.Description = $PropertyObj.description

            $Metingen += $MetingObj

            
     
        }

        if (($sensorgemeente -ne "Gemeente Rotterdam") -or ($sensorproject -ne "Luchtclub")) {
            Report "W" "$sensorName (ID = $sensorid) excluded: gemeente = $sensorgemeente and project = $sensorproject"
            $exclude = $excluded + 1
        }
        else {


            $ReportObj = [PSCustomObject] [ordered] @{SensorID = $sensorid;
                          SensorName = $sensorname;
                          OosterLengte = $oosterlengte;
                          NoorderBreedte = $noorderbreedte;
                          Gemeente = $sensorgemeente;
                          Project = $sensorproject;
                          Metingen = $metingen
                          }        

            $templist += $ReportObj
        }
        # for test purposes limit the numer of sensors
        # if ($templist.count -eq 20) { break }
    }

    Report "I" "Sort list by sensor ID" $StatusObj $Tempfile
    $Reportlist = $templist | Sort-Object -Property SensorID 

    Report "I" "Start reporting" $StatusObj $Tempfile

    Report "N" " " $StatusObj $Tempfile
    Report "H" "Actieve sensoren ".PadRight(140,"-") $StatusObj $Tempfile
    Report "N" " " $StatusObj $Tempfile

    $record = "ID".Padright(6, " ") + 
              "Sensor Naam".Padright(24, " ") +
              "Gemeente".PadRight(24," ") +
              "Project".PadRight(24," ") +
              "O.L.".PadRight(8," ") + 
              "N.B.".ToString().PadRight(8," ") +
              "Meting".Padright(40," ") +                    
              "Waarde".Padright(10," ") +
              "Eenheid".PadRight(8," ") +
              "Laatste Meting".Padright(24," ") +
              "Leeftijd meting in minuten" 

    Report "N" $record $StatusObj $Tempfile
    Report "N" " " $StatusObj $Tempfile

    $Active = 0

    foreach ($reportline in $reportlist) {
        if ($reportline.Metingen[0].MinutesAgo -GT 1440) {
            continue
        }
        else {
            $active = $active + 1
        }
        if (!$reportline.Metingen[0].LastResult){
            $reportline.Metingen[0].LastResult = '- n/a -'
        }
        $record = $reportline.SensorID.ToSTring().Padright(6, " ") + 
                    $reportline.SensorName.Padright(24, " ") +
                    $reportline.Gemeente.Padright(24, " ") +
                    $reportline.Project.Padright(24, " ") +
                    $reportline.OosterLengte.ToString().PadRight(8," ") + 
                    $reportline.Noorderbreedte.ToString().PadRight(8," ") +
                    $reportline.Metingen[0].Description.Padright(40," ") +                    
                    $reportline.Metingen[0].LastResult.ToString().Padright(10," ") +
                    $reportline.Metingen[0].Unit.Padright(8," ") +
                    $reportline.Metingen[0].LastMeasuretime.ToString().Padright(24," ") +
                    $reportline.Metingen[0].MinutesAgo.ToString().Padright(10," ") 
                     
        Report "N" $record $StatusObj $Tempfile

        for ($y=1; $y -le $reportline.Metingen.value.count-1; $y++) {
            if (!$reportline.Metingen[$y].LastResult){
                $reportline.Metingen[$y].LastResult = '- n/a -'
            }
            $record = " ".Padright(6, " ") + 
                      " ".Padright(24, " ") +
                      " ".Padright(24, " ") +
                      " ".Padright(24, " ") +
                      " ".PadRight(8," ") + 
                      " ".PadRight(8," ") +
                    $reportline.Metingen[$y].Description.Padright(40," ") +                    
                    $reportline.Metingen[$y].LastResult.ToString().Padright(10," ") +
                    $reportline.Metingen[$y].Unit.Padright(8," ") +
                    $reportline.Metingen[$y].LastMeasuretime.ToString().Padright(24," ") +
                    $reportline.Metingen[$y].MinutesAgo.ToString().Padright(10," ") 
                     
            Report "N" $record $StatusObj $Tempfile

        }

    }

    Report "I" "$Active actieve sensoren" $StatusObj $Tempfile

    Report "N" " " $StatusObj $Tempfile
    Report "N" " " $StatusObj $Tempfile
    Report "H" "Inactieve sensoren ".PadRight(140,"-") $StatusObj $Tempfile
    Report "N" " " $StatusObj $Tempfile

    $record = "ID".Padright(6, " ") + 
              "Sensor Naam".Padright(24, " ") +
              "Gemeente".PadRight(24," ") +
              "Project".PadRight(24," ") +
              "O.L.".PadRight(8," ") + 
              "N.B.".ToString().PadRight(8," ") +
              "Meting".Padright(40," ") +                    
              "Waarde".Padright(10," ") +
              "Eenheid".PadRight(8," ") +
              "Laatste Meting".Padright(24," ") +
              "Leeftijd meting in minuten" 

    Report "N" $record $StatusObj $Tempfile
    Report "N" " " $StatusObj $Tempfile

    $InActive = 0

    foreach ($reportline in $reportlist) {
        if ($reportline.Metingen[0].MinutesAgo -LE 1440) {
            continue
        }
        else {
            $InActive = $InActive + 1
        }
        if (!$reportline.Metingen[0].LastResult){
            $reportline.Metingen[0].LastResult = '- n/a -'
        }
        $record = $reportline.SensorID.ToSTring().Padright(6, " ") + 
                    $reportline.SensorName.Padright(24, " ") +
                    $reportline.Gemeente.Padright(24, " ") +
                    $reportline.Project.Padright(24, " ") +
                    $reportline.OosterLengte.ToString().PadRight(8," ") + 
                    $reportline.Noorderbreedte.ToString().PadRight(8," ") +
                    $reportline.Metingen[0].Description.Padright(40," ") +                    
                    $reportline.Metingen[0].LastResult.ToString().Padright(10," ") +
                    $reportline.Metingen[0].Unit.Padright(8," ") +
                    $reportline.Metingen[0].LastMeasuretime.ToString().Padright(24," ") +
                    $reportline.Metingen[0].MinutesAgo.ToString().Padright(10," ") 
                     
        Report "N" $record $StatusObj $Tempfile

        for ($y=1; $y -le $reportline.Metingen.value.count-1; $y++) {
            if (!$reportline.Metingen[$y].LastResult){
                $reportline.Metingen[$y].LastResult = '- n/a -'
            }
            $record = " ".Padright(6, " ") + 
                      " ".Padright(24, " ") +
                      " ".Padright(24, " ") +
                      " ".Padright(24, " ") +
                      " ".PadRight(8," ") + 
                      " ".PadRight(8," ") +
                    $reportline.Metingen[$y].Description.Padright(40," ") +                    
                    $reportline.Metingen[$y].LastResult.ToString().Padright(10," ") +
                    $reportline.Metingen[$y].Unit.Padright(8," ") +
                    $reportline.Metingen[$y].LastMeasuretime.ToString().Padright(24," ") +
                    $reportline.Metingen[$y].MinutesAgo.ToString().Padright(10," ") 
                     
            Report "N" $record $StatusObj $Tempfile

        }

    }
    Report "I" "$InActive inactieve sensoren" $StatusObj $Tempfile

    Report "N" " " $StatusObj $Tempfile

    # Init luchtclub info file if not existent
    $timestamp = Get-Date
    $str = $ADHC_LuchtClubInfo.Split("\")
    $dir = $ADHC_OutputDirectory + $str[0] + "\" + $str[1]
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $LuchtClubInfoFile = $ADHC_OutputDirectory + $ADHC_LuchtClubInfo.Replace($ADHC_Computer, $myHost)
    $dr = Test-Path $LuchtClubInfoFile
    if (!$dr) { 
        $r = "0|0|Total|"   + $timestamp.ToString("dd-MM-yyyy HH:mm:ss")       
        Set-Content $LuchtClubInfoFile $r -force
        $r =  "0|0|Active"   + $timestamp.ToString("dd-MM-yyyy HH:mm:ss")
        Add-Content $LuchtClubInfoFile $r
        $r = "0|0|InActive" + $timestamp.ToString("dd-MM-yyyy HH:mm:ss")
        Add-Content $LuchtClubInfoFile $r
        $r = "0|0|Excluded" + $timestamp.ToString("dd-MM-yyyy HH:mm:ss")
        Add-Content $LuchtClubInfoFile $r
    }

    # Update info file (will be read by prtg sensor)
    
    $luchtlines = Get-Content $LuchtClubInfoFile
        
    $lastlist = @() 
    $i = 0     
    foreach ($line in $luchtlines) {
        $split = $line.Split("|")
        $last = $split[0]
        $lastlist += $last
    } 
    $r =  "$Totalsensors|" + $lastlist[0] + "|Total|"   + $timestamp.ToString("dd-MM-yyyy HH:mm:ss")
    Set-Content $LuchtClubInfoFile $r
    $r = "$Active|"       + $lastlist[1] + "|Active|"   + $timestamp.ToString("dd-MM-yyyy HH:mm:ss")
    Add-Content $LuchtClubInfoFile $r
    $r = "$InActive|"     + $lastlist[2] + "|InActive|" + $timestamp.ToString("dd-MM-yyyy HH:mm:ss")
    Add-Content $LuchtClubInfoFile $r
    $r = "$excluded|"     + $lastlist[3] + "|Excluded|" + $timestamp.ToString("dd-MM-yyyy HH:mm:ss")  
    Add-Content $LuchtClubInfoFile $r
     
    


}

catch {
    $StatusObj.scripterror = $true
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
    
    Report "N"  " " $StatusObj $Tempfile
    $returncode = 99
        
    if (($StatusObj.scripterror) -and ($returncode -eq 99)) {
        $msg = ">>> Script ended abnormally"
        Report "N"  $msg $StatusObj $Tempfile
        Report "N"  " " $StatusObj $Tempfile
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "9" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        Add-Content $jobstatus "Failed item = $FailedItem"
        Add-Content $jobstatus "Errormessage = $ErrorMessage"
        Add-Content $jobstatus "Dump info = $dump"

        Report "E" "Failed item = $FailedItem" $StatusObj $Tempfile
        Report "E" "Errormessage = $ErrorMessage" $StatusObj $Tempfile
        Report "E" "Dump info = $dump" $StatusObj $Tempfile
        $returncode =  16        
    }
   
    if (($StatusObj.scriptaction) -and ($returncode -eq 99)) {
        $msg = ">>> Script ended normally with action required"
        Report "W"  $msg $StatusObj $Tempfile
        Report "N"  " " $StatusObj $Tempfile
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "6" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode =  8
    }

    if (($StatusObj.scriptchange) -and ($returncode -eq 99)) {
        $msg = ">>> Script ended normally with reported changes, but no action required"
        Report "C"  $msg $StatusObj $Tempfile
        Report "N"  " " $StatusObj $Tempfile
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "3" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode =  4
    }

    if ($returncode -eq 99) {

        $msg = ">>> Script ended normally without reported changes, and no action required"
        Report "I"  $msg $StatusObj $Tempfile
        Report "N"  " " $StatusObj $Tempfile
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "0" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode = 0
    }

    try { # Free resource and copy temp file        
        
        $deffile = $ADHC_OutputDirectory + $ADHC_LuchtClub.Directory + $ADHC_LuchtClub.Name 
        $CopMov = & $ADHC_CopyMoveScript $TempFile $deffile "MOVE" "REPLACE" $TempFile 
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
