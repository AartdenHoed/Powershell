CLS

$InformationPreference = "Continue"
$WarningPreference = "Continue"

$Version = " -- Version: 1.0"
$Node = " -- Node: " + $env:COMPUTERNAME
$d = Get-Date
$Datum = " -- Date: " + $d.ToShortDateString()
$Tijd = " -- Time: " + $d.ToShortTimeString()
$Scriptmsg = "PowerShell script " + $MyInvocation.MyCommand.Name + $Version + $Datum + $Tijd +$Node
Write-Information $Scriptmsg 

$DiskList = Get-ChildItem "C:\Users\AHMRDH\Documents\" -recurse -file | Select FullName,LastWriteTime,Length | Sort-Object FullName
$DiskList | Out-Gridview



$depth = 6
$curqual = @("~","~","~","~","~","~")
$curlength = @(0,0,0,0,0,0)

$qlist1 = [System.Collections.ArrayList]@()


foreach ($FileEntry in $DiskList) {      
   
    $qualifier = $FileEntry.FullName.Split("\")
    $nrofquals = $qualifier.Length
    # $qualifier
    
    
    $loopmax = [math]::min($depth-1, $nrofquals-2 ) 
    for ($i = $loopmax+1;$i -le $nrofquals-1; $i++) {
        # Write-Host "loop $i"
        $qualifier[$i] = " "           
    } 

    # $nrofquals
    # $qualifier[$nrofquals-1]  # is dataset name
    $dirchange = $false
    for ($i = 0;$i -le $loopmax; $i++) {
        if ($qualifier[$i] -ne $curqual[$i]) {
            $dirchange = $true
        } 
    }
    if ($dirchange) {
        for ($i = 0;$i -le $depth-1; $i++) {
            if ($curqual[$i] -eq " ") {
                $curlength[$i] = $null
            }
            else {
                $curlength[$i] = [math]::truncate($curlength[$i] / 1024)
            }
        } 
        if ($curqual[0] -ne "~") {
            $NewEntry = [PSCustomObject]  @{Q00 = $curqual[0]; L00 = [double]$curlength[0];  `
                                        Q01 = $curqual[1]; L01 = [double]$curlength[1];  `
                                        Q02 = $curqual[2]; L02 = [double]$curlength[2];  `
                                        Q03 = $curqual[3]; L03 = [double]$curlength[3];  `
                                        Q04 = $curqual[4]; L04 = [double]$curlength[4];  `
                                        Q05 = $curqual[5]; L05 = [double]$curlength[5]}
                                                           
            [void]$qlist1.Add($NewEntry)
        }
        for ($i = 0;$i -le $depth-1; $i++) {
            $curqual[$i] = $qualifier[$i]
            $curlength[$i] = 0
        } 
    }
          
    for ($i = 0;$i -le $loopmax; $i++) {
        $curlength[$i] = $curlength[$i] + $FileEntry.Length        
    }   
    

}

if ($curqual[0] -ne "~") {
    for ($i = 0;$i -le $depth-1; $i++) {
        if ($curqual[$i] -eq " ") {
            $curlength[$i] = $null
        }
        else {
            $curlength[$i] = [math]::truncate($curlength[$i] / 1024)
        }
    } 
    $NewEntry = [PSCustomObject]  @{Q00 = $curqual[0]; L00 = [double]$curlength[0];  `
                                        Q01 = $curqual[1]; L01 = [double]$curlength[1];  `
                                        Q02 = $curqual[2]; L02 = [double]$curlength[2];  `
                                        Q03 = $curqual[3]; L03 = [double]$curlength[3];  `
                                        Q04 = $curqual[4]; L04 = [double]$curlength[4];  `
                                        Q05 = $curqual[5]; L05 = [double]$curlength[5]}
                                                           
    [void]$qlist1.Add($NewEntry)
}

$qlist1 | Out-Gridview