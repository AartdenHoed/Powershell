cls
$MyOBJ = @()
$o =  [PSCustomObject] [ordered] @{uurnummer = 3;uurverbruik= 17}
$Myobj += $o
$o =  [PSCustomObject] [ordered] @{uurnummer = 1;uurverbruik= 4.64}
$Myobj += $o
$o =  [PSCustomObject] [ordered] @{uurnummer = 3;uurverbruik= 5.8}
$Myobj += $o
$o =  [PSCustomObject] [ordered] @{uurnummer = 2;uurverbruik= 8}
$Myobj += $o
$o =  [PSCustomObject] [ordered] @{uurnummer = 3;uurverbruik= 2.68}
$Myobj += $o

#$myobj

$listoflists = New-Object 'object[]' 24
$nextindex = New-Object 'object[]' 24

for ($i = 0; $i -lt 24; $i++) {
    $nextindex[$i] = 0
}
    
foreach ($entry in $MyObj) {
    $i = $entry.uurnummer - 1
    $j = $nextindex[$i]
    if ($j -eq 0 ) {
        $listoflists[$i] = @()
        $listoflists[$i] += $entry
    }
    else {        
        $listoflists[$i] += $entry
    }
    $nextindex[$i]++
    
}


$listofpercentiel = New-Object 'object[]' 24

#$listoflists.count 
$u = 1
foreach ($reflist in $listoflists) {
    
    $hulplist = @()
    foreach ($meting in $reflist) {
        if ($reflist.uurnummer -eq $u) {
            $hulplist += $meting.uurverbruik
        }
        
    }
    if ($hulplist.count -gt 0) {
        write-host "List"
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
        
        if ($u -eq 3) { 
        $perc00
        $perc20
        $perc40
        $perc60
        $perc80
        $perc100
        
        
        exit}

        
    }
    $u++
    
}

