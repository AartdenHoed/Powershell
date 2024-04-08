# Dit script haalt een sensor overzicht uit PRTG en stopt dit in een database
# Toegang tot PRTG gaat via credentials. LET OP: Je autorisatie bepaalt hoeveel PRTG laat zien!
# Channel in JSON: https://prtg.shl-groep.nl/api/table.json?noraw=0&content=channels&columns=name,objid,type,active,tags,minimum,maximum,condition,lastvalue&id=1001

cls
$Version = " -- Version: 3.2"
class TrustAllCertsPolicy : System.Net.ICertificatePolicy {
    [bool] CheckValidationResult([System.Net.ServicePoint] $a,
                                 [System.Security.Cryptography.X509Certificates.X509Certificate] $b,
                                 [System.Net.WebRequest] $c,
                                 [int] $d) {
        return $true
    }
}
[System.Net.ServicePointManager]::CertificatePolicy = [TrustAllCertsPolicy]::new()

# This piece of code alllows self signed certificates
#if (-not("dummy" -as [type])) {
#    add-type -TypeDefinition @"
#using System;
#using System.Net;
#using System.Net.Security;
#using System.Security.Cryptography.X509Certificates;
#
#public static class Dummy {
#    public static bool ReturnTrue(object sender,
#        X509Certificate certificate,
#        X509Chain chain,
#        SslPolicyErrors sslPolicyErrors) { return true; }
#
#    public static RemoteCertificateValidationCallback GetDelegate() {
#        return new RemoteCertificateValidationCallback(Dummy.ReturnTrue);
#    }
#}
#"@
#}
$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Continue"  

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
    $m = & $ADHC_LockScript "Lock" "PRTG" "$enqprocess" 10 "OBJECT" 
       

# END OF COMMON CODING

    # Init reporting file
    $odir = $ADHC_TempDirectory + $ADHC_PRTGoverviewDB.Directory
    New-Item -ItemType Directory -Force -Path $odir | Out-Null
    $tempfile = $odir + $ADHC_PRTGoverviewDB.Name
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


    #[System.Net.ServicePointManager]::ServerCertificateValidationCallback = [dummy]::GetDelegate()

    $t = Get-Date
    Report "I" "$t *** Call API for sensors" $StatusObj $Tempfile
    #$cred = Get-Credential -Credential $env:UserName
    $user = $ADHC_Credentials.UserName
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ADHC_Credentials.Password)
    $pass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    $SensorCSV = $null
    $SensorOBJ = $null
    $uri = 'https://192.168.178.143:9443/api/table.xml?content=sensors&output=csvtable&columns=objid,type,name,tags,active,
    downtime,downtimetime,downtimesince,uptime,uptimetime,uptimesince,knowntime,cumsince,
    sensor,interval,lastcheck,lastup,lastdown,device,group,probe,grpdev,
    access,dependency,probegroupdevice,
    status,message,priority,lastvalue,favorite,schedule,comments,basetype,baselink,parentid
    &count=50000'
    $uri = $uri + '&username=' + $user + '&password=' + $pass

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    #[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls,ssl3"
    $SensorCSV = Invoke-RestMethod  -Uri $uri 

    #$SensorCSV = Invoke-RestMethod  -Uri "https://www.google.com" 

    # Hier kan je een selectie maken van de sensoren die je wilt hebben
    $SensorOBJ = ConvertFrom-Csv -InputObject $SensorCSV -Delimiter ',' 
    $t = Get-Date
    Report "I" "$t *** Add real device" $StatusObj $Tempfile

    foreach ($entry1 in $SensorOBJ) {
        if ($entry1.Apparaat -eq $null) { 
            $realdev = "?"
        }
        else {
            $realsplit = $entry1.Apparaat.split("()")
            $reallast = $realsplit.Count - 2
            if ($reallast -ge 0) {
                $realdev = $realsplit[$reallast]
            }
            else {
                $realdev = $entry1.Apparaat
            }
        } 
    $entry1 | Add-Member -NotePropertyName RealDevice -NotePropertyValue $realdev
    
    }
    
}
catch {
    $StatusObj.Scripterror = $true
    
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    $Dump = $_.Exception.ToString()
}

if (!$StatusObj.Scripterror) {
    try {
        $t = Get-Date
        Report "I" "$t *** Truncate sensor table" $StatusObj $Tempfile

        $query = "TRUNCATE TABLE dbo.Sensors" 
        invoke-sqlcmd -ServerInstance '.\sqlexpress' -Database "PRTG" `
                        -Query "$query" `
                        -ErrorAction Stop
        $t = Get-Date
        Report "I" "$t *** Reload sensor table" $StatusObj $Tempfile
        foreach ($entry1 in $SensorOBJ) {
            if ((!$entry1.'Fout Gedurende(RAW)') -or ($entry1.'Fout Gedurende(RAW)' -eq "-")) {
                $downforraw = "null"
            }
            else {
                $downforraw = $entry1.'Fout Gedurende(RAW)'
            }

            if ((!$entry1.'Ok Gedurende(RAW)') -or ($entry1.'Ok Gedurende(RAW)' -eq "-")) {
                $upforraw = "null"
            }
            else {
                $upforraw = $entry1.'Ok Gedurende(RAW)'
            }

            if ((!$entry1.'Laatste fout(RAW)') -or($entry1.'Laatste fout(RAW)' -eq "-")) {
                $lastdownraw = "null"
            }
            else {
                $lastdownraw = $entry1.'Laatste fout(RAW)'
            }

            if ((!$entry1.'Laatste Waarde(RAW') -or(!$entry1.'Laatste Waarde(RAW')) {
                $lastvalueraw = "null"
            }
            else {
                $lastvalueraw = $entry1.'Laatste Waarde(RAW)'
            }
    
            if ((!$entry1.'Laatste ok(RAW)') -or($entry1.'Laatste ok(RAW)' -eq "-")) {
                $lastupraw = "null"
            }
            else {
                $lastupraw = $entry1.'Laatste ok(RAW)'
            }

            if ((!$entry1.'Laatste Controle(RAW)') -or($entry1.'Laatste Controle(RAW)' -eq "-")) {
                $lastcheckraw = "null"
            }
            else {
                $lastcheckraw = $entry1.'Laatste Controle(RAW)'
            }

            $comments = $entry1.Notities.Replace("'", "''") 
            $commentsraw = $entry1.'Notities(RAW)'.Replace("'", "''") 
            $message = $entry1.Bericht.Replace("'", "''") 
            $messageraw = $entry1.'Bericht(RAW)'.Replace("'", "''") 
            $device = $entry1.Apparaat.Replace("'", "''") 
            $deviceraw = $entry1.'Apparaat(RAW)'.Replace("'", "''") 
            $groupdevice = $entry1.'Groep/Apparaat'.Replace("'", "''") 
            $groupdeviceraw = $entry1.'Groep/Apparaat(RAW)'.Replace("'", "''") 
            $dependency = $entry1.Afhankelijkheid.Replace("'", "''") 
            $dependencyraw = $entry1.'Afhankelijkheid(RAW)'.Replace("'", "''") 
            $object = $entry1.Object.Replace("'", "''") 
            $objectraw = $entry1.'Object(RAW)'.Replace("'", "''") 
            $sensor = $entry1.Sensor.Replace("'", "''") 
            $sensorraw = $entry1.'Sensor(RAW)'.Replace("'", "''") 
            $lastvalue = $entry1.'Laatste Waarde'.Replace("'", "''") 
            

            $query = "INSERT INTO [dbo].[Sensors]
               ([ID]
               ,[ID_Raw]
               ,[Type]
               ,[Type_Raw]
               ,[Object]
               ,[Object_Raw]
               ,[Tags]
               ,[Tags_Raw]
               ,[Active_Paused]
               ,[Active_Paused_Raw]
               ,[DowntimePCT]
               ,[DowntimePCT_Raw]
               ,[DowntimeSEC]
               ,[DowntimeSEC_Raw]
               ,[Down_For]
               ,[Down_For_Raw]
               ,[UptimePCT]
               ,[UptimePCT_Raw]
               ,[UptimeSEC]
               ,[UptimeSEC_Raw]
               ,[Up_For]
               ,[Up_For_Raw]
               ,[UpDowntimeCoverage]
               ,[UpDowntimeCoverage_Raw]
               ,[AccumulatedSince]
               ,[AccumulatedSince_Raw]
               ,[Sensor]
               ,[Sensor_Raw]
               ,[Interval]
               ,[Interval_Raw]
               ,[LastCheck]
               ,[LastCheck_Raw]
               ,[LastUp]
               ,[LastUp_Raw]
               ,[LastDown]
               ,[LastDown_Raw]
               ,[Device]
               ,[Device_Raw]
               ,[Group]
               ,[Group_Raw]
               ,[Probe]
               ,[Probe_Raw]
               ,[Group_Device]
               ,[Group_Device_Raw]
               ,[Acces]
               ,[Acces_Raw]
               ,[Dependency]
               ,[Dependency_Raw]
               ,[ProbeGroupDevice]
               ,[ProbeGroupDevice_Raw]
               ,[Status]
               ,[Status_Raw]
               ,[Message]
               ,[Message_Raw]
               ,[Priority]
               ,[Priority_Raw]
               ,[LastValue]
               ,[LastValue_Raw]
               ,[Fav]
               ,[Fav_Raw]
               ,[Schedule]
               ,[Schedule_Raw]
               ,[Comments]
               ,[Comments_Raw]
               ,[BaseType]
               ,[BaseType_Raw]
               ,[URL]
               ,[URL_Raw]
               ,[ParentID]
               ,[ParentID_Raw]
               ,[RealDevice]           
               )
            VALUES (" + `              
              $entry1.ID + "," + `
              $entry1.'ID(RAW)' + ",'" +
              $entry1.Type + "','" +
              $entry1.'Type(RAW)' + "','" +
              $object + "','" +
              $objectraw + "','" +
              $entry1.Markeringen + "','" +
              $entry1.'Markeringen(RAW)' + "','" +
              $entry1.'Actief/Gepauzeerd' + "'," +
              $entry1.'Actief/Gepauzeerd(RAW)' + ",'" +
              $entry1.'Uitvaltijd [%]' + "'," +
              $entry1.'Uitvaltijd [%](RAW)' + ",'" +
              $entry1.'Uitvaltijd [s]' + "'," +
              $entry1.'Uitvaltijd [s](RAW)' + ",'" +
              $entry1.'Fout gedurende' + "'," +
              $downforraw  + ",'" +
              $entry1.'Uptijd [%]' + "'," +
              $entry1.'Uptijd [%](RAW)' + ",'" +
              $entry1.'Uptiijd [s]' + "'," +
              $entry1.'Uptiijd [s](RAW)' + ",'" +
              $entry1.'Ok Gedurende' + "'," +
              $upforraw + ",'" +
              $entry1.'Ok/Uitvaltijd Dekking' + "'," +
              $entry1.'Ok/Uitvaltijd Dekking(RAW)' + ",'" +
              $entry1.'Geaccumuleerd Sinds' + "'," +
              $entry1.'Ok/Uitvaltijd Dekking(RAW)' + ",'" +
              $sensor + "','" +
              $sensorraw + "','" +
              $entry1.Interval + "'," +
              $entry1.'Interval(RAW)' + ",'" +
              $entry1.'Laatste Controle' + "'," +
              $lastcheckraw + ",'" +
              $entry1.'Laatste ok' + "'," +
              $lastupraw + ",'" +
              $entry1.'Laatste fout' + "'," +
              $lastdownraw + ",'" +
              $device + "','" +
              $deviceraw + "','" +
              $entry1.Groep + "','" +
              $entry1.'Groep(RAW)' + "','" +
              $entry1.Probe + "','" +
              $entry1.'Probe(RAW)' + "','" +
              $groupdevice + "','" +
              $groupdeviceraw + "','" +
              $entry1.Toegang + "','" +
              $entry1.'Toegang(RAW)' + "','" +
              $dependency + "','" +
              $dependencyraw + "','" +
              $entry1.'Probe Groep Apparaat' + "','" +
              $entry1.'Probe Groep Apparaat(RAW)' + "','" +
              $entry1.Status + "'," +
              $entry1.'Status(RAW)'  + ",'" +                $message + "','" +
              $messageraw + "'," + 
              $entry1.Prioriteit + "," +
              $entry1.'Prioriteit(RAW)' + ",'" +      
              $lastvalue + "'," +
              $lastvalueraw + ",'" +    
              $entry1.'Fav.' + "'," +
              $entry1.'Fav.(RAW)' + ",'" +  
              $entry1.'Schema' + "','" +
              $entry1.'Schema(RAW)' + "','" +
              $comments + "','" +
              $commentsraw + "','" +
              $entry1.'Basis Type' + "','" +
              $entry1.'Basis Type(RAW)' + "','" +  
              $entry1.'URL' + "'," + 
              $entry1.'URL(RAW)' + "," + 
              $entry1.'Bovenliggens object ID' + "," + 
              $entry1.'Bovenliggens object ID(RAW)' + ",'" + 
              $entry1.RealDevice +
              "')"
            invoke-sqlcmd -ServerInstance '.\sqlexpress' -Database "PRTG" `
                    -Query "$query" -ErrorAction Stop
            #Report "I" "Create sensor CSV"
            #remove-item "C:\Users\admaho\Documents\Powershell\PRTGOVZsensor.csv" -Force -ErrorAction SilentlyContinue 
            #
            #foreach ($entry1 in $SensorOBJ) {
            #    
            #    Export-Csv -InputObject $entry1 -Delimiter '~' -Force -Append -NoTypeInformation `
            #            -LiteralPath "C:\Users\admaho\Documents\Powershell\PRTGOVZsensor.csv"
            #}
            $t = Get-Date
           
        }
        Report "I" "$t *** Sensor query finished" $StatusObj $Tempfile
    }
    catch {
        $StatusObj.Scripterror = $true
        
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        $Dump = $_.Exception.ToString()
        write-warning "$ErrorMessage"
    }

}


if (!$StatusObj.Scripterror) {
    try {
        $t = Get-Date
        Report "I" "$t *** Truncate Channel table" $StatusObj $Tempfile

        $query = "TRUNCATE TABLE dbo.Channels" 
        invoke-sqlcmd -ServerInstance ".\sqlexpress" -Database "PRTG" `
                        -Query "$query" `
                        -ErrorAction Stop

        $t = Get-Date
        Report "I" "$t *** Reload Channel table" $StatusObj $Tempfile
        foreach ($entry1 in $SensorOBJ) {
            $currid = $entry1.id
            $uri = "https://192.168.178.143:9443/api/table.json?noraw=0&content=channels&columns=name,objid,minimum,maximum,condition,lastvalue&id=$currid"
            $uri = $uri + '&username=' + $user + '&password=' + $pass
            $nr = 0
            $ChannelJson = Invoke-RestMethod  -Uri $uri 
            foreach ($channel in $ChannelJson.channels ) {
                $Channelobj = $Channel
        
                foreach ($entry1 in $Channelobj) {
                    if ((!$entry1.active_raw) -or ($entry1.active_raw -eq "-")) {
                        $active_raw = "null"
                    }
                    else {
                        $active_raw = $entry1.active_raw
                    }
                    if ((!$entry1.lastvalue_raw) -or ($entry1.lastvalue_raw -eq "-") -or ($entry1.lastvalue_raw -eq "Geen gegevens")) {
                        $lastvalue_raw = "null"
                    }
                    else {
                        $lastvalue_raw = $entry1.lastvalue_raw
                    }
                    if ((!$entry1.minimum_raw) -or ($entry1.minimum_raw -eq "-") -or ($entry1.minimum_raw -eq "Geen gegevens")) {
                        $minimum_raw = "null"
                    }
                    else {
                        $minimum_raw = $entry1.minimum_raw
                    }
                    if ((!$entry1.maximum_raw) -or ($entry1.maximum_raw -eq "-") -or ($entry1.maximum_raw -eq "Geen gegevens")) {
                        $maximum_raw = "null"
                    }
                    else {
                        $maximum_raw = $entry1.maximum_raw
                    }             
              

                    $query = "INSERT INTO [dbo].[Channels]
                       ([SensorID]
                       ,[Name]
                       ,[Name_RAW]
                       ,[Number]
                       ,[ObjID]
                       ,[ObjID_Raw]
                       ,[Minimum]
                       ,[Minimum_Raw]
                       ,[Maximum]
                       ,[Maximum_Raw]
                       ,[Condition]
                       ,[Condition_RAW]
                       ,[LastValue]
                       ,[LastValue_Raw]
               
                       )
                    VALUES (" +               
                      $currid + ",'" + 
                      $entry1.Name + "','" +
                      $entry1.Name_raw + "'," +
                      $nr + "," +
                      $entry1.objid + ",'" +
                      $entry1.objid_raw + "','" +
                      $entry1.Minimum + "'," +
                      $Minimum_raw + ",'" +
                      $entry1.Maximum + "'," +
                      $Maximum_raw + "," +
                      $entry1.Condition + "," +
                      $entry1.Condition_raw + ",'" +
                      $entry1.Lastvalue + "'," +
                      $lastvalue_raw + 
                       ")"
                    invoke-sqlcmd -ServerInstance ".\sqlexpress" -Database "PRTG" `
                        -Query "$query" `
                        -Erroraction Stop

                    $nr = $nr + 1
                }  

            }

        }
   
        $t = Get-Date
        Report "I" "$t *** Channel queries finished" $StatusObj $Tempfile
    }
    catch {
        $StatusObj.Scripterror = $true
        
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        $Dump = $_.Exception.ToString()
        write-warning "$ErrorMessage"
    }

}

if (!$StatusObj.Scripterror) {
    try {
        $t = Get-Date
        Report "I" "$t *** Call API for devices" $StatusObj $Tempfile

        $DeviceCSV = $null
        $DeviceOBJ = $null
        $uri = 'https://192.168.178.143:9443/api/table.xml?content=devices&output=csvtable&columns=objid,type,name,tags,active,
        device,group,probe,grpdev,
        notifiesx,intervalx,access,dependency,probegroupdevice,
        status,message,priority,favorite,schedule,comments,basetype,baselink,parentid,host,location
        &count=50000' 
        $uri = $uri + '&username=' + $user + '&password=' + $pass

        $DeviceCSV = Invoke-RestMethod  -Uri $uri 


        # Hier kan je een selectie maken van de sensoren die je wilt hebben
        $DeviceOBJ = ConvertFrom-Csv -InputObject $DeviceCSV -Delimiter ',' 

        $t = Get-Date
        Report "I" "$t *** Add real device" $StatusObj $Tempfile
        foreach ($entry1 in $DeviceOBJ) {
            if ($entry1.Apparaat -eq $null) { 
                $realdev = "?"
            }
            else {
                $realsplit = $entry1.Apparaat.split("()")
                $reallast = $realsplit.Count - 2
                if ($reallast -ge 0) {
                    $realdev = $realsplit[$reallast]
                }
                else {
                    $realdev = $entry1.Apparaat
                }
            } 

            $entry1 | Add-Member -NotePropertyName RealDevice -NotePropertyValue $realdev
    
        }

        $t = Get-Date
        Report "I" "$t *** Truncate device table" $StatusObj $Tempfile

        $query = "TRUNCATE TABLE dbo.Devices" 
        invoke-sqlcmd -ServerInstance ".\sqlexpress" -Database "PRTG" `
                        -Query "$query" `
                        -ErrorAction Stop
        $t = Get-Date
        Report "I" "$t *** Reload device table" $StatusObj $Tempfile
        foreach ($entry1 in $DeviceOBJ) {
   
            $comments = $entry1.Notificaties.Replace("'", "''") 
            $commentsraw = $entry1.'Notificaties(RAW)'.Replace("'", "''") 
            if ($entry1.Bericht) {
                $message = $entry1.Bericht.Replace("'", "''")
            }
            else {
                $message = "" 
            } 
            $messageraw = $entry1.'Bericht(RAW)'.Replace("'", "''") 
            $device = $entry1.Apparaat.Replace("'", "''") 
            $deviceraw = $entry1.'Apparaat(RAW)'.Replace("'", "''") 
            if ($entry1.'Groep/Apparaat') {
                $groupdevice = $entry1.'Groep/Apparaat'.Replace("'", "''") 
            }
            else {
                $groupdevice = "" 
            }
            if ($entry1.'Groep/Apparaat(RAW') {
                $groupdeviceraw = $entry1.'Groep/Apparaat(RAW)'.Replace("'", "''") 
            }
            else {
                $groupdeviceraw = "" 
            }
            $dependency = $entry1.Afhankelijkheid.Replace("'", "''") 
            $dependencyraw = $entry1.'Afhankelijkheid(RAW)'.Replace("'", "''") 
            $object = $entry1.Object.Replace("'", "''") 
            $objectraw = $entry1.'Object(RAW)'.Replace("'", "''") 
   

            $query = "INSERT INTO [dbo].[Devices]
                   ([ID]
                   ,[ID_Raw]
                   ,[Type]
                   ,[Type_Raw]
                   ,[Object]
                   ,[Object_Raw]
                   ,[Tags]
                   ,[Tags_Raw]
                   ,[Active_Paused]
                   ,[Active_Paused_Raw]
                   ,[Device]
                   ,[Device_Raw]
                   ,[Group]
                   ,[Group_Raw]
                   ,[Probe]
                   ,[Probe_Raw]
                   ,[Group_Device]
                   ,[Group_Device_Raw]
                   ,[Notifications]
                   ,[Notifications_Raw]
                   ,[Interval]
                   ,[Interval_Raw]
                   ,[Access]
                   ,[Access_Raw]
                   ,[Dependency]
                   ,[Dependency_Raw]
                   ,[ProbeGroupDevice]
                   ,[ProbeGroupDevice_Raw]
                   ,[Status]
                   ,[Status_Raw]
                   ,[Message]
                   ,[Message_Raw]
                   ,[Priority]
                   ,[Priority_Raw]
                   ,[Fav]
                   ,[Fav_Raw]
                   ,[Schedule]
                   ,[Schedule_Raw]
                   ,[Comments]
                   ,[Comments_Raw]
                   ,[BaseType]
                   ,[BaseType_Raw]
                   ,[URL]
                   ,[URL_Raw]
                   ,[ParentID]
                   ,[ParentID_Raw]
                   ,[Host]
                   ,[Host_Raw]
                   ,[Location]
                   ,[Location_Raw]
                   ,[RealDevice]           
                   )
             VALUES (" + `              
                  $entry1.ID + "," + `
                  $entry1.'ID(RAW)' + ",'" +
                  $entry1.Type + "','" +
                  $entry1.'Type(RAW)' + "','" +
                  $object + "','" +
                  $objectraw + "','" +
                  $entry1.Markeringen + "','" +
                  $entry1.'Markeringen(RAW)' + "','" +
                  $entry1.'Actief/Gepauzeerd' + "'," +
                  $entry1.'Actief/Gepauzeerd(RAW)' + ",'" +
                  $device + "','" +
                  $deviceraw + "','" +
                  $entry1.Groep + "','" +
                  $entry1.'Groep(RAW)' + "','" +
                  $entry1.Probe + "','" +
                  $entry1.'Probe(RAW)' + "','" +
                  $groupdevice + "','" +
                  $groupdeviceraw + "','" +
                  $entry1.Notificaties + "','" +
                  $entry1.'Notificaties(RAW)' + "','" +
                  $entry1.Interval + "'," +
                  $entry1.'Interval(RAW)' + ",'" +
                  $entry1.Toegang + "','" +
                  $entry1.'Toegang(RAW)' + "','" +
                  $dependency + "','" +
                  $dependencyraw + "','" +
                  $entry1.'Probe Groep Apparaat' + "','" +
                  $entry1.'Probe Groep Apparaat(RAW)' + "','" +
                  $entry1.Status + "'," +
                  $entry1.'Status(RAW)'  + ",'" +                    $message + "','" +
                  $messageraw + "'," + 
                  $entry1.Prioriteit+ "," +
                  $entry1.'Prioriteit(RAW)' + ",'" +      
                  $entry1.'Fav.' + "'," +
                  $entry1.'Fav.(RAW)' + ",'" +  
                  $entry1.'Schema' + "','" +
                  $entry1.'Schema(RAW)' + "','" +
                  $comments + "','" +
                  $commentsraw + "','" +
                  $entry1.'Basis Type' + "','" +
                  $entry1.'Basis Type(RAW)' + "','" +  
                  $entry1.'URL' + "'," + 
                  $entry1.'URL(RAW)' + "," + 
                  $entry1.'Bovenliggens object ID' + "," + 
                  $entry1.'Bovenliggens object ID(RAW)' + ",'" + 
                  $entry1.Host + "','" +
                  $entry1.'Host(RAW)' + "','" +
                  $entry1.Plaats + "','" +
                  $entry1.'Plaats(RAW)' + "','" +
                  $entry1.RealDevice +
                  "')"
             invoke-sqlcmd -ServerInstance ".\sqlexpress" -Database "PRTG" `
                        -Query "$query" `
                        -Erroraction Stop
        }
        
        #Report "I" "Create device CSV"
        #
        #remove-item "C:\Users\admaho\Documents\Powershell\PRTGOVZdevice.csv" -Force -ErrorAction SilentlyContinue 
        #
        #foreach ($entry1 in $DeviceOBJ) {
        #    
        #    Export-Csv -InputObject $entry1 -Delimiter '~' -Force -Append -NoTypeInformation `
        #            -LiteralPath "C:\Users\admaho\Documents\Powershell\PRTGOVZdevice.csv"
        #}

        $t = Get-Date
        Report "I" "$t *** Device query finished" $StatusObj $Tempfile

    }
    catch {
            $StatusObj.Scripterror = $true
        
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            $Dump = $_.Exception.ToString()
            write-warning "$ErrorMessage"
    }

}
$m = & $ADHC_LockScript "Free" "PRTG" "$enqprocess" 10 "OBJECT"
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
        
if (($StatusObj.Scripterror) -and ($returncode -eq 99)) {
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
   
if (($StatusObj.Scriptaction) -and ($returncode -eq 99)) {
    Report "W" ">>> Script ended normally with action required" $StatusObj $Tempfile
    Report "N" " " $StatusObj $Tempfile
        
    $dt = Get-Date
    $jobline = $ADHC_Computer + "|" + $process + "|" + "6" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
    Set-Content $jobstatus $jobline
       
    $returncode = 8
}

if (($StatusObj.Scriptchange) -and ($returncode -eq 99)) {
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
        
    $deffile = $ADHC_OutputDirectory + $ADHC_PRTGoverviewDB.Directory + $ADHC_PRTGoverviewDB.Name 
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