## WMIC /output: " + envir.wmictempname + " product get Name,Vendor,Version,InstallLocation,InstallDate"

$a = WMIC  product get Name,Vendor,Version,InstallLocation,InstallDate

$a[0]    ## is eerste regel , met de titels
$a[1]    ## lege regel
$a[2]    ## regel