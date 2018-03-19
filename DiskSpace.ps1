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

$FullScriptName = $MyInvocation.MyCommand.Definition
$ScriptName = $MyInvocation.MyCommand.Name
$ADHC_PsPath = $FullScriptName.Replace($ScriptName, "")
$ADHC_InitVar = $ADHC_PsPath + "InitVar.PS1"
& "$ADHC_InitVar"

$DiskList = Get-ChildItem "C:\Users\AHMRDH" -recurse -force -file | Select FullName,LastWriteTime,Length | Sort-Object FullName
# $DiskList = Get-ChildItem "c:\" -recurse -file | Select FullName,LastWriteTime,Length | Sort-Object FullName
# $DiskList | Out-Gridview


$depth = 7
$curqual = @("~","~","~","~","~","~","~")
$curlength = @(0,0,0,0,0,0,0)

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
                $curlength[$i] = [math]::round($curlength[$i] / (1024*1024),9)
            }
        } 
        if ($curqual[0] -ne "~") {
            $NewEntry = [PSCustomObject]  @{Q00 = $curqual[0]; L00 = [double]$curlength[0];  `
                                        Q01 = $curqual[1]; L01 = [double]$curlength[1];  `
                                        Q02 = $curqual[2]; L02 = [double]$curlength[2];  `
                                        Q03 = $curqual[3]; L03 = [double]$curlength[3];  `
                                        Q04 = $curqual[4]; L04 = [double]$curlength[4];  `
                                        Q05 = $curqual[5]; L05 = [double]$curlength[5];  `
                                        Q06 = $curqual[6]; L06 = [double]$curlength[6]}
                                                           
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
            $curlength[$i] = [math]::round($curlength[$i] / (1024*1024), 9)
        }
    } 
    $NewEntry = [PSCustomObject]  @{Q00 = $curqual[0]; L00 = [double]$curlength[0];  `
                                        Q01 = $curqual[1]; L01 = [double]$curlength[1];  `
                                        Q02 = $curqual[2]; L02 = [double]$curlength[2];  `
                                        Q03 = $curqual[3]; L03 = [double]$curlength[3];  `
                                        Q04 = $curqual[4]; L04 = [double]$curlength[4];  `
                                        Q05 = $curqual[5]; L05 = [double]$curlength[5];  `
                                        Q06 = $curqual[6]; L06 = [double]$curlength[6]}
                                                           
    [void]$qlist1.Add($NewEntry)
}


$qlist1 | Out-Gridview
$qlist2 = $qlist1

$curlen0 = 0
$curlen1 = 0
$curlen2 = 0
$curlen3 = 0
$curlen4 = 0
$curlen5 = 0
$curlen6 = 0
$curq0 = "~"
$curq1 = "~"
$curq2 = "~"
$curq3 = "~"
$curq4 = "~"
$curq5 = "~"
$curq6 = "~"

$curpos = 0
$pos00 = 0
$pos01 = 0
$pos02 = 0
$pos03 = 0
$pos04 = 0
$pos05 = 0
$pos06 = 0


foreach ($resultrow in $qlist2) {
    if ($resultrow.Q00 -ne $curq0 ) {
        $h = $curlen0
        $curlen0 = $resultrow.L00
        $qlist2[$pos00].L00 = $h
        $pos00 = $curpos
        $curq0 = $resultrow.Q00
    }
    else {
        $curlen0 = $curlen0 + $resultrow.L00
        $resultrow.L00 = $null
    }
    if ($resultrow.Q01 -ne $curq1 ) {
        $h = $curlen1
        $curlen1 = $resultrow.L01
        $qlist2[$pos01].L01 = $h
        $pos01 = $curpos        
        $curq1 = $resultrow.Q01
    }
    else {
        $curlen1 = $curlen1 + $resultrow.L01
        $resultrow.L01 = $null
    }
    if ($resultrow.Q02 -ne $curq2 ) {
        $h = $curlen2
        $curlen2 = $resultrow.L02
        $qlist2[$pos02].L02 = $h
        $pos02 = $curpos        
        $curq2 = $resultrow.Q02
    }
    else {
        $curlen2 = $curlen2 + $resultrow.L02
        $resultrow.L02 = $null
    }
    if ($resultrow.Q03 -ne $curq3 ) {
        $h = $curlen3
        $curlen3 = $resultrow.L03
        $qlist2[$pos03].L03 = $h
        $pos03 = $curpos        
        $curq3 = $resultrow.Q03
    }
    else {
        $curlen3 = $curlen3 + $resultrow.L03
        $resultrow.L03 = $null
    }
    if ($resultrow.Q04 -ne $curq4 ) {
        $h = $curlen4
        $curlen4 = $resultrow.L04
        $qlist2[$pos04].L04 = $h
        $pos04 = $curpos        
        $curq4 = $resultrow.Q04
    }
    else {
        $curlen4 = $curlen4 + $resultrow.L04
        $resultrow.L04 = $null
    }
    if ($resultrow.Q05 -ne $curq5 ) {
        $h = $curlen5
        $curlen5 = $resultrow.L05
        $qlist2[$pos05].L05 = $h
        $pos05 = $curpos        
        $curq5 = $resultrow.Q05
    }
    else {
        $curlen5 = $curlen5 + $resultrow.L05
        $resultrow.L05 = $null
    }
    if ($resultrow.Q06 -ne $curq6 ) {
        $h = $curlen6
        $curlen6 = $resultrow.L06
        $qlist2[$pos06].L06 = $h
        $pos06 = $curpos        
        $curq6 = $resultrow.Q06
    }
    else {
        $curlen6 = $curlen6 + $resultrow.L06
        $resultrow.L06 = $null
    }

    $curpos = $curpos + 1
}
$qlist2[$pos00].L00 = $curlen0
$qlist2[$pos01].L01 = $curlen1
$qlist2[$pos02].L02 = $curlen2
$qlist2[$pos03].L03 = $curlen3
$qlist2[$pos04].L04 = $curlen4
$qlist2[$pos05].L05 = $curlen5
$qlist2[$pos06].L06 = $curlen6

$qlist2 | Out-Gridview


$outfile = $ADHC_DiskSpace  + $ADHC_Computer + "_Diskspace.csv"
Remove-Item $outfile -force
foreach ($resultrow in $qlist2) {
    Export-Csv  -InputObject $resultrow    $outfile -force -append

}