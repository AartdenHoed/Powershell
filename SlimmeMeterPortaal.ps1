$Version = " -- Version: 1.3.2"

# COMMON coding
CLS
$StatusOBJ = [PSCustomObject] [ordered] @{Scripterror = $false;
                                          ScriptChange = $false;
                                          ScriptAction = $false;
                                          }

$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"
Function Get_Percentiel ($Uurverbruik, $Percentielreeks) {

    if ($Uurverbruik -lt $Percentielreeks.perc00) {
        return "Zeer laag"
    }
    if ($Uurverbruik -lt $Percentielreeks.perc20) {
        return "Laag"
    }
    if ($Uurverbruik -lt $Percentielreeks.perc40) {
       return "Verlaagd"
    }
    if ($Uurverbruik -le $Percentielreeks.perc60) {
        return "Normaal"
    }
    if ($Uurverbruik -le $Percentielreeks.perc80) {
        return "Verhoogd"
    }
    if ($Uurverbruik -le $Percentielreeks.perc100) {
        return "Hoog"
    }
    return "Zeer hoog"
    
} 


Function Report ($MyObj,$Reference) {
    #$reference.Percentielen[0]
    #exit
    # Write report
    Write-Host "REPORT"
    $reportarray = New-Object 'object[,]' 16,26
               
    $reportarray[0,0] = "Uur"
    $reportarray[1,0] = " "
    for ($u = 1;  $u -lt 25; $u++) {
        $reportarray[0,$u] = $u.ToString()
        $reportarray[1,$u] = " "
    }
    $reportarray[0,25] = "Dagtotaal"
    $reportarray[1,25] = " "

    $mt = $MyObj.MeterType
    $regel = 0
    $kolom = 0
    $g = Get-Date
    $curmonth = $g.Month
    $curday = $g.Day
    $curyear = $g.year
    $upper = 24
    $lower = 0
    foreach ($entry in $MyObj.Verbruikslijst) {
        if (($entry.Datumtijd.Month -ne $curmonth) -or
            ($entry.Datumtijd.Day -ne $curday) -or
            ($entry.Datumtijd.Year -ne $curyear)) {

            if ($upper -ne 24) {
                # Last day was not complete
                #$lower
                #$upper
                $datumstr = $datum.ToString("yyyy-MM-dd HH:mm")
                Write-Warning "Ontbrekende gegevens na uur $uurdigit ($mt) onder datum $datumstr"
                $regel = $regel + 1
                for ($z = $lower; $z -lt 24; $z++) {
                    $reportarray[$kolom,$regel] =  "n/a"
                   
                    $x = $kolom + 1        
                    $reportarray[$x,$regel] = "---"
                    $regel = $regel + 1
                }
            }

            $curmonth = $entry.Datumtijd.Month
            $curday = $entry.Datumtijd.Day
            $curyear = $entry.Datumtijd.Year

            if ($kolom -ge 2) {
                $reportarray[$kolom,25] = "{0:N2}" -f $dagverbruik
                $w = $kolom + 1
                $reportarray[$w,25] = Get_Percentiel $dagverbruik $Reference.Percentielen[24]
                $dagverbruik = 0     

            } 
              
            $kolom = $kolom + 2
            $regel = 0
            $reportarray[$kolom,$regel] = $entry.Datumtijd.ToString('yyyy-MM-dd')
            $x = $kolom + 1
            $reportarray[$x,$regel] = "hoog/laag"
        }

        $regel = $regel + 1  

        $uurtxt = $reportarray[0,$regel]
        $uurdigit = [Convert]::ToInt32($uurtxt)
        if ($uurdigit -eq 24) {
            $uurdigit = 23
            $lower = 24
        }
        else {
            $lower = $uurdigit
        }
        
        $datum = $entry.Datumtijd
        $uurwaarneming = $datum.Hour
        if ($datum.Minute -ne 59) {
            $upper = $uurwaarneming
        }
        else {
            $upper = 24
        }

        if ($upper -gt $lower) {
            $datumstr = $datum.ToString("yyyy-MM-dd HH:mm")
            Write-Warning "In regel met uur $uurdigit ($mt) komt een waarneming met uur $uurwaarneming, onder datum $datumstr"
            
            for ($z = $lower; $z -lt $upper; $z++) {
                $reportarray[$kolom,$regel] =  "n/a"
                $regel = $regel + 1
            }
        }
        
        $reportarray[$kolom,$regel] =  "{0:N2}" -f $entry.Uurverbruik 
        $dagverbruik = $dagverbruik + $entry.Uurverbruik
        $p = $uurwaarneming - 1
        $x = $kolom + 1        
        $reportarray[$x,$regel] = Get_Percentiel $entry.Uurverbruik $Reference.Percentielen[$p]

                 
    }
    if ($upper -ne 24) {
        # Last day was not complete
        #$lower
        #$upper
        $datumstr = $datum.ToString("yyyy-MM-dd HH:mm")
        Write-Warning "Ontbrekende gegevens na uur $uurdigit ($mt) onder datum $datumstr"
        $regel = $regel + 1
        for ($z = $lower; $z -lt 24; $z++) {
            $reportarray[$kolom,$regel] =  "n/a"
                   
            $x = $kolom + 1        
            $reportarray[$x,$regel] = "---"
            $regel = $regel + 1
        }
    }

    $reportarray[$kolom,25] = "{0:N2}" -f $dagverbruik
    $w = $kolom + 1
    $reportarray[$w,25] = Get_Percentiel $dagverbruik $Reference.Percentielen[24]
    $dagverbruik = 0     

    $reportobject = @()
    for ($r = 0;  $r -lt 26; $r++) {
        $regelobject = [PSCustomObject] [ordered] @{c0 = $reportarray[0,$r];
                                                    p0 = $reportarray[1,$r];
                                                    c1 = $reportarray[2,$r];
                                                    p1 = $reportarray[3,$r];
                                                    c2 = $reportarray[4,$r];
                                                    p2 = $reportarray[5,$r];
                                                    c3 = $reportarray[6,$r];
                                                    p3 = $reportarray[7,$r];
                                                    c4 = $reportarray[8,$r];
                                                    p4 = $reportarray[9,$r];
                                                    c5 = $reportarray[10,$r];
                                                    p5 = $reportarray[11,$r];
                                                    c6 = $reportarray[12,$r];
                                                    p6 = $reportarray[13,$r];
                                                    c7 = $reportarray[14,$r];
                                                    p7 = $reportarray[15,$r]}
        $reportobject += $regelobject
    }

            
    $reportobject | out-gridview -Title $mt
}
#### einde functie REPORT



Function Fill($MyObj) {
    # Create reference data
    Write-Host "FILL"
    
    $listofref_usages = New-Object 'object[]' 25
    $listofref_percentielen = New-Object 'object[]' 25
    $nextindex = New-Object 'object[]' 25
    

    for ($i = 0; $i -lt 25; $i++) {
        $nextindex[$i] = 0
    }
    
    $dagverbruik = 0
    $curyear = 0
    $curmonth = 0
    $curday = 0
    $init = $true
    foreach ($entry in $MyObj) {
        if ($init) {
            $curyear = $entry.Datumtijd.Year
            $curmonth = $entry.Datumtijd.Month
            $curday = $entry.Datumtijd.Day
            $init = $false
        }
    # Plaats elke meting in de lijst van het betreffende uur 
        $i = $entry.uurnummer - 1
        $j = $nextindex[$i]
        if ($j -eq 0 ) {
            $listofref_usages[$i] = @()
            $listofref_usages[$i] += $entry
        }
        else {        
            $listofref_usages[$i] += $entry
        }
        $nextindex[$i]++

        $dagverbruik = $dagverbruik + $entry.uurverbruik 
        if (($curyear -ne $entry.Datumtijd.Year) -or 
            ($curmonth -ne $entry.Datumtijd.Month) -or 
            ($curday -ne $entry.Datumtijd.Day)) {
            
            $p = 24
            $q = $nextindex[$p]
            $mydate = $entry.datumtijd.AddMinutes(-61)
            $totalentry = [PSCustomObject] [ordered] @{Datumtijd = $mydate;
                                                        Uurverbruik = $dagverbruik;
                                                        Uurnummer = 25;
                                                        Aantalmetingen = 24                                                              
                                                        }
            if ($q -eq 0 ) {
                $listofref_usages[$p] = @()
                $listofref_usages[$p] += $totalentry
            }
            else {        
                $listofref_usages[$p] += $totalentry
            }
            $nextindex[$p]++
            $dagverbruik = 0
            $curyear = $entry.Datumtijd.Year
            $curmonth = $entry.Datumtijd.Month
            $curday = $entry.Datumtijd.Day
        }
    }
    $p = 24
    $q = $nextindex[$p]
    $mydate = $entry.datumtijd.AddMinutes(-61)
    $totalentry = [PSCustomObject] [ordered] @{Datumtijd = $mydate;
                                                    Uurverbruik = $dagverbruik;
                                                    Uurnummer = 25;
                                                    Aantalmetingen = 24                                                              
                                                    }
    if ($q -eq 0 ) {
        $listofref_usages[$p] = @()
        $listofref_usages[$p] += $totalentry
    }
    else {        
        $listofref_usages[$p] += $totalentry
    }
      

    #$listofref_usages.count 
    $u = 1
    foreach ($reflist in $listofref_usages) {
    
        $hulplist = @()
        if (($reflist.uurnummer -eq $u) -or ($reflist.uurnummer -eq 25))  {
            $hulplist += $reflist.uurverbruik        
        }
        if ($hulplist.count -gt 0) {
                         
            $hulplist = $hulplist | Sort-Object 
            $aantal = $hulplist.count

            Write-host "$aantal waarnemingen in uurlijst $u"
            
            $perc00 = $hulplist[0]
            
            $p20dec = 20*($aantal-1)/100 
            if ($p20dec -lt 0) {$p20dec = 0}
            if ($p20dec -gt $aantal - 1) {$p20dec = $aantal -1}
            $p20down = [math]::truncate($p20dec)
            $p20up = $p20down + 1
            $perc20 = $hulplist[$p20down] + (($hulplist[$p20up] - $hulplist[$p20down]) * (0.5)) 
           
            $p40dec = 40*($aantal-1)/100 
            if ($p40dec -lt 0) {$p40dec = 0}
            if ($p40dec -gt $aantal - 1) {$p40dec = $aantal -1}
            $p40down = [math]::truncate($p40dec)
            $p40up = $p40down + 1        
            $perc40 = $hulplist[$p40down] + (($hulplist[$p40up] - $hulplist[$p40down]) * (0.5)) 
            
            $p60dec = 60*($aantal-1)/100 
            if ($p60dec -lt 0) {$p60dec = 0}
            if ($p60dec -gt $aantal - 1) {$p60dec = $aantal -1}
            $p60down = [math]::truncate($p60dec)
            $p60up = $p60down + 1        
            $perc60 = $hulplist[$p60down] + (($hulplist[$p60up] - $hulplist[$p60down]) * (0.5)) 
            
            $p80dec = 80*($aantal-1)/100 
            if ($p80dec -lt 0) {$p80dec = 0}
            if ($p80dec -gt $aantal - 1) {$p80dec = $aantal -1}
            $p80down = [math]::truncate($p80dec)
            $p80up = $p80down + 1        
            $perc80 = $hulplist[$p80down] + (($hulplist[$p80up] - $hulplist[$p80down]) * (0.5)) 
            
            $perc100 = $hulplist[$count-1]
            
            $percentiel = [PSCustomObject] [ordered] @{Perc00 = $perc00;
                                                       Perc20 = $perc20;
                                                       Perc40 = $perc40;
                                                       Perc60 = $perc60;
                                                       Perc80 = $perc80;
                                                       Perc100 = $perc100}
            $i = $u - 1
            $listofref_percentielen[$i] = $percentiel
        
        }
        $u++
    
    }
    $returnobj = [PSCustomObject] [ordered] @{Usagelist = $listofref_usages;
                                            Percentielen = $listofref_percentielen}
    Return $returnobj
}
#### einde functie FILL

Function Metingen ($MyObject, $Metertype) {
    # Read measure data into object (reference objects en report objects are handled likewise
    Write-Host "METINGEN"
    $ref = @()
    $verbruiksom = 0
    switch ($Metertype) {
        # create reference lists        
        "gas" {                               
            $uurverbruik = 0 
            $aantalmetingen = 0
            $uurnumber = 1
            foreach ($meting in $MyObject.usages) {
                # sommeer verbruik per uur
                $datumtijd = [datetime]::parseexact($meting.time.Substring(0,19),'dd-MM-yyyy HH:mm:ss',$null)  
                $uurverbruik = $uurverbruik + [Convert]::ToInt32($meting.delivery.Replace(",","").Replace(".",""))/100  
                $uurverbruik =  [math]::Round($uurverbruik,2)             
                $aantalmetingen += 1
                # op uurovergang: sla dit uur op in object, en start nieuw uur, 
                if (($datumtijd.Hour -eq 0) -and ($datumtijd.Minute -eq 0)) {
                    $datumtijd = $datumtijd.AddSeconds(-1)
                    $uurnumber = 24
                }
                if ((($datumtijd.Hour -ge $uurnumber) -and ($datumtijd.Minute -eq 0)) -or ($uurnumber -eq 24)) {
                    if ($datumtijd.Hour -gt $uurnumber) {
                        $skip = $datumtijd.Hour - $uurnumber
                        Write-Warning "$metertype $datumtijd : Skipped $skip hours"
                        $uurnumber = $datumtijd.Hour
                    }
                            
                    $uurtotaal = [PSCustomObject] [ordered] @{Datumtijd = $datumtijd;
                                                                Uurverbruik = $uurverbruik;
                                                                Uurnummer = $uurnumber;
                                                                Aantalmetingen = $aantalmetingen                                                              
                                                                }
                    $ref += $uurtotaal
                    $verbruiksom = $verbruiksom + $uurverbruik
                            
                    $uurnumber += 1                                              
                    if ($uurnumber -ge 24) {
                        $uurnumber = 1
                    }
                    $aantalmetingen = 0
                    $uurverbruik = 0
                    if ($aantalmetingen -gt 1) {
                        Write-Warning "$metertype $datumtijd : Aantal metingen per uur is $aantalmetingen in plaats van 1"
                    # exit
                    }
                }
                        
            }
            if ($uurnumber -ne 1) {
                $skip = 24 - $uurnumber
                Write-Warning "$metertype $datumtijd : metingen aan het einde van de dag ontbreken vanaf $uurnumber uur"
                $uurnumber = 1
            }
        } 
            
        "elektriciteit" {
            
            $uurverbruik = 0 
            $aantalmetingen = 0
            $uurnumber = 1
            foreach ($meting in $MyObject.usages) {
                # sommeer verbruik per uur
                $datumtijd = [datetime]::parseexact($meting.time.Substring(0,19),'dd-MM-yyyy HH:mm:ss',$null) 

                if ($meting.delivery_high -eq $null) {$d_high = "0"}
                else {$d_high = $meting.delivery_high}
                if ($meting.delivery_low -eq $null) {$d_low = "0"} 
                else {$d_low = $meting.delivery_low}  

                $uurverbruik = $uurverbruik + [Convert]::ToInt32($d_high.Replace(",","").Replace(".",""))/100 + ` 
                                                [Convert]::ToInt32($d_low.Replace(",","").Replace(".",""))/100
                $uurverbruik =  [math]::Round($uurverbruik,2)             
                $aantalmetingen += 1
                # op uurovergang: sla dit uur op in object, en start nieuw uur, 
                if (($datumtijd.Hour -eq 0) -and ($datumtijd.Minute -eq 0)) {
                    $datumtijd = $datumtijd.AddSeconds(-1)
                    $uurnumber = 24
                }
                if ((($datumtijd.Hour -ge $uurnumber) -and ($datumtijd.Minute -eq 0)) -or ($uurnumber -eq 24)) {
                    if ($datumtijd.Hour -gt $uurnumber) {
                        $skip = $datumtijd.Hour - $uurnumber
                        Write-Warning "$metertype $datumtijd : Skipped $skip hours"
                        $uurnumber = $datumtijd.Hour
                    }
                            
                    $uurtotaal = [PSCustomObject] [ordered] @{Datumtijd = $datumtijd;
                                                                    Uurverbruik = $uurverbruik;
                                                                    Uurnummer = $uurnumber;
                                                                    Aantalmetingen = $aantalmetingen                                                              
                                                                    }
                    $ref += $uurtotaal
                    $verbruiksom = $verbruiksom + $uurverbruik
                    $uurnumber += 1                                              
                    if ($uurnumber -ge 24) {
                        $uurnumber = 1
                    }
                       
                    $aantalmetingen = 0
                    $uurverbruik = 0

                    if ($aantalmetingen -gt 4) {
                        Write-Warning "$metertype $datumtijd : Aantal metingen per uur is $aantalmetingen in plaats van 4"
                    # exit
                    }
                }                        
            } 
            if ($uurnumber -ne 1) {
                $skip = 24 - $uurnumber
                Write-Warning "$metertype $datumtijd : metingen aan het einde van de dag ontbreken vanaf $uurnumber uur"
                $uurnumber = 1
            }
        }
    } 
    $result = [PSCustomObject] [ordered] @{Lastmeting = $meting;
                                           Glist = $ref
                                           Verbruiksom = $verbruiksom}
    return $result  
}
#### einde functie METINGEN

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


### START main code #####################################################################################

# krijg de meter gegevens

$apikey = $ADHC_SMPapikey
$H = @{'API-Key'="$apikey"}

$A = Invoke-WebRequest -Uri https://app.slimmemeterportal.nl/userapi/v1/connections -Method Get `
               -ContentType "application/json" `
               -H $H 
$obj1 = convertFrom-Json($A.Content)

# per meter (gas + elektriciteit) de uurgegevens + referentiegegevens per meter ophalen van de afgelopen week

$stroomreference = @()
$gasreference = @()    

foreach ($entry in $obj1) {

    # create reference object (last 5 year, the 20 days around current date) 
    $curdate = Get-Date
    $curmonth = $curdate.Month
    $curday = $curdate.Day
    $meterID = $entry.meter_identifier
    $meterType = $entry.connection_type
    #Get-Date
    
     
    write-host "Build reference lists: $meterType"

    for ($ryear = -5; $ryear -lt 0; $ryear++) {
        
        for ($rday = -10; $rday -lt 10; $rday++) {
            $refdate = $curdate.AddDays($rday).AddYears($ryear)
            $strdate = $refdate.ToString("dd-MM-yyyy")
            $strdate
            #$strdate = "14-01-2024"
            #$meterid = "871689290200620802"
            $url = "https://app.slimmemeterportal.nl/userapi/v1/connections/" + $meterID + "/usage/" + $strdate
                       
            try {
                $R = Invoke-WebRequest -Uri $url -Method Get `
                       -ContentType "application/json" `
                       -H $H
                $obj3 = convertFrom-Json($R.Content)  
            } 
            catch {
                Write-Warning "URL $url failed"
                continue
            }         
            
            switch ($metertype) {
                # create reference lists
                "gas" {
                    $ZZZ = Metingen $obj3 $metertype 
                    $gasreference += $ZZZ.Glist                                      
                } 
            
                "elektriciteit" {
                    $ZZZ = Metingen $obj3 $metertype 
                    $stroomreference += $ZZZ.Glist                    
                }                   
                default {
                    Write-Error "$metertype is een onbekend meter type"
                    exit
                }
            }
        }
    }

    # Get-Date

    # create usage object (last weeks' usage)
    write-host "Build usage lists $meterType"

    $firstpass = $true
    $aantaldagen = 0

    for ($d = -7;  $d -lt 0; $d++) {
        $aantaldagen += 1
        $cdate = (Get-Date).AddDays($d) 
        $strdate = $cdate.ToString("dd-MM-yyyy")
        $strdate
        $url = "https://app.slimmemeterportal.nl/userapi/v1/connections/" + $meterID + "/usage/" + $strdate        

        try {
            $B = Invoke-WebRequest -Uri $url -Method Get `
                -ContentType "application/json" `
                -H $H
            $obj2 = convertFrom-Json($B.Content)
            if ($obj2.usages.count -eq 0) {
                throw "No usages found for date " + $strdate
            }
        } 
        catch {
            Write-Warning "URL $url failed"
            continue
        }         

        # $obj2.meter_identifier

        if ($firstpass) {
            # get start figures
            $firstpass = $false
            $totaalverbruiksom = 0
            $uurnumber = 1

            switch ($metertype) {
                "gas" {    
                    $gasverbruik = @()                    
                    $startstand = ([Convert]::ToInt32($obj2.usages[0].delivery_reading.Replace(",","").Replace(".","")) `
                                 - [Convert]::ToInt32($obj2.usages[0].delivery.Replace(",","").Replace(".","")))/100
                }
                "elektriciteit" {
                    $stroomverbruik = @()   
                    if ($obj2.usages[0].delivery_high -eq $null) {$d_high = "0"}
                    else {$d_high = $obj2.usages[0].delivery_high}
                    if ($obj2.usages[0].delivery_low -eq $null) {$d_low = "0"} 
                    else {$d_low = $obj2.usages[0].delivery_low} 
                                   
                    $startstand = ([Convert]::ToInt32($obj2.usages[0].delivery_reading_combined.Replace(",","").Replace(".","")) `
                                 - [Convert]::ToInt32($d_high.Replace(",","").Replace(".","")) `
                                 - [Convert]::ToInt32($d_low.Replace(",","").Replace(".","")))/100
                }
                default {
                    Write-Error "$metertype is een onbekend meter type" 
                    exit                   
                }  
            } 
            $startstand =  [math]::Round($startstand,2)
            $startmoment = [datetime]::parseexact($obj2.usages[0].time.Substring(0,19),'dd-MM-yyyy HH:mm:ss',$null)       

        }        
    
        switch ($metertype) {
            # get usage lists
            "gas" {
                $ZZZ = Metingen $obj2 $metertype 
                $gasverbruik += $ZZZ.Glist
                $lastmeting = $ZZZ.Lastmeting 
                $totaalverbruiksom = $totaalverbruiksom + $ZZZ.verbruiksom
                
            }
            "elektriciteit" {
                $ZZZ = Metingen $obj2 $metertype  
                $stroomverbruik += $ZZZ.Glist
                $lastmeting = $ZZZ.Lastmeting   
                $totaalverbruiksom = $totaalverbruiksom + $ZZZ.verbruiksom             
            }
            default {
                Write-Error "$metertype is een onbekend meter type"
                exit
            }
        }
    }
    switch ($metertype) {
        # get end figures and create usage object including usage lists
        "gas" { 
            $eindstand = [Convert]::ToInt32($lastmeting.delivery_reading.Replace(",","").Replace(".",""))/100
            $eindstand =  [math]::Round($eindstand,2)
            $totaalverbruikdelta = [math]::Round($eindstand - $startstand,2)
            $eindmoment = [datetime]::parseexact($lastmeting.time.Substring(0,19),'dd-MM-yyyy HH:mm:ss',$null)
            if (($eindmoment.Hour -eq 0) -and ($eindmoment.Minute -eq 0)) {
                $eindmoment = $eindmoment.AddSeconds(-1)
            }
            $Gasobject = [PSCustomObject] [ordered] @{MeterID = $meterID;
                                                        MeterType = $meterType;
                                                        Aantaldagen = $aantaldagen
                                                        Starttijd = $startmoment;
                                                        Startstand = $startstand;
                                                        Eindtijd = $eindmoment;     
                                                        Eindstand = $eindstand;
                                                        Totaalverbruikdelta = $totaalverbruikdelta;
                                                        Totaalverbruiksom = $totaalverbruiksom;
                                                        Verbruikslijst = $gasverbruik
                                                        }
            # $Gasobject
            # $Gasobject.Verbruikslijst | Format-Table           

         }
        "elektriciteit" {
            $eindstand = [Convert]::ToInt32($lastmeting.delivery_reading_combined.Replace(",","").Replace(".",""))/100
            $eindstand =  [math]::Round($eindstand,2)
            $totaalverbruikdelta = [math]::Round($eindstand - $startstand,2)
            $eindmoment = [datetime]::parseexact($lastmeting.time.Substring(0,19),'dd-MM-yyyy HH:mm:ss',$null)
            if (($eindmoment.Hour -eq 0) -and ($eindmoment.Minute -eq 0)) {
                $eindmoment = $eindmoment.AddSeconds(-1)
            }
            $Stroomobject = [PSCustomObject] [ordered] @{MeterID = $meterID;
                                                        MeterType = $meterType;
                                                        AantalDagen = $aantaldagen;
                                                        Starttijd = $startmoment;
                                                        Startstand = $startstand;
                                                        Eindtijd = $eindmoment;     
                                                        Eindstand = $eindstand;
                                                        Totaalverbruikdelta = $totaalverbruikdelta;
                                                        Totaalverbruiksom = $totaalverbruiksom;
                                                        Verbruikslijst = $stroomverbruik
                                                        }
            # $Stroomobject
            # $Stroomobject.Verbruikslijst | Format-Table    
        }
        default {
            Write-Error "$metertype is een onbekend meter type"
            exit
        }
    } 
    
}

$reflist_Stroom = Fill($stroomreference)
Report $Stroomobject $reflist_Stroom
$reflist_Gas = Fill($gasreference)
Report $Gasobject $reflist_Gas



