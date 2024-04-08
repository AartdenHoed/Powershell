

$LocalInitVar = "C:\ADHC\Powershell\Initvar.ps1"
& "$LocalInitVar" "SILENT"



        # copy tempfile to definitive file if it has been created (host invokable)
        
$ifile = "C:\Users\ADHC\DOwnloads\Testbestand.txt"
$ofile = "C:\users\ADHC\DOwnloads\Ziemaar.txt"

        
$cm = & $ADHC_CopyMoveScript $ifile $ofile "COPY" "REPLACE" "JSON"  

        
 
$x = COnvertFrom-Json $cm

foreach ($entry in $x) {
    write-host $entry.level  " - "   $entry.message
}