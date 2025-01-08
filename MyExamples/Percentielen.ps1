cls

$hulplist = @(18,7,5,100,40,60, 59, 45, 23, 8, 1, 50, 99, 111, 34, 22, 67, 95, 87, 63, 40, 13, 6, 63, 63, 55, 41)

$hulplist = $hulplist | Sort-Object 

$aantal = $hulplist.count

# $aantal

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

write-host "00% percentiel = $perc00"
write-host "20% percentiel = $perc20"
write-host "40% percentiel = $perc40"
write-host "60% percentiel = $perc60"
write-host "80% percentiel = $perc80"
write-host "100% percentiel = $perc100"
write-host " "

$testgetal= @(1,5,6,7,8,13,18,22,23,34,40,40,41,45,50,55,59,60,63,63,63,67,87,95,99,100,111,0)

foreach ($getal in $testgetal) {
    if ($getal -lt $perc00) {
        Write-host "Percentiel = &&-00 for $getal"
        continue
    }
    if ($getal -lt $perc20) {
        Write-host "Percentiel = 00-20 for $getal"
        continue
    }
    if ($getal -lt $perc40) {
        Write-host "Percentiel = 20-40 for $getal"
        continue
    }
    if ($getal -lt $perc60) {
        Write-host "Percentiel = 40-60 for $getal"
        continue
    }
    if ($getal -lt $perc80) {
        Write-host "Percentiel = 60-80 for $getal"
        continue
    }
    if ($getal -lt $perc100) {
        Write-host "Percentiel = 80-100 for $getal"
        continue
    }
    Write-host "Percentiel = 100-&& for $getal"
    
} 