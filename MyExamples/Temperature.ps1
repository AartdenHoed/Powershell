
    $t = Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace "root/wmi"
    

    foreach ($x in $t)
    {
        Write-Host " "
        $inst = $x.InstanceName
        Write-Host $Inst
        if (!($inst -like "*TZ0*")) {
            Write-Host "Skipped .... "
            continue
        }
        
        $temp = $x.CurrentTemperature
        $crit = $x.CriticalTripPoint
        $pass = $x.PassiveTripPoint

        $currentTempKelvin = $temp / 10
        $currentTempCelsius = $currentTempKelvin - 273.15

        $currentTempFahrenheit = (9/5) * $currentTempCelsius + 32

        $returntemp = $currentTempCelsius.ToString() + " C" 

        Write-Host ("Current = " + $returntemp)

        $currentTempKelvin = $pass / 10
        $currentTempCelsius = $currentTempKelvin - 273.15

        $currentTempFahrenheit = (9/5) * $currentTempCelsius + 32

        $returntemp = $currentTempCelsius.ToString() + " C" 

        Write-Host ("Passive TripPoint = " + $returntemp)

        $currentTempKelvin = $crit / 10
        $currentTempCelsius = $currentTempKelvin - 273.15

        $currentTempFahrenheit = (9/5) * $currentTempCelsius + 32

        $returntemp = $currentTempCelsius.ToString() + " C" 

        Write-Host ("Critical TripPoint = " + $returntemp)

        $c = $x.ActiveTripPointCount   
        Write-host ("Active TripPoint Count = " + $c) 
        $a = $x.ActiveTripPoint
        # Write-host $a

        $i = 0

        foreach ($tr in $x.ActiveTripPoint) {
            if ($i -ge $c) {
                break
            }
            # $tr
            $Kelvin = $tr / 10
            # $Kelvin
            $Celsius = $Kelvin - 273.15
            # $Celsius
            
            write-host ("Trip Point Temperature : " + $Celsius.ToString())
            $i += 1

        }
   }
   