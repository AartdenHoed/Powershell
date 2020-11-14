# Lock/unlock a global resource
param (
    [string]$Parm1 = "xxx", 
    [string]$Parm2 = "yyy",
    [string]$Parm3 = "zzz"
)

#TestValues####################################
#$Action = "LOCK"
#$ENQNAME = "WMIC"
#$PROCESS = "Ikkuh"
#$waittime = 15
#$Mode = "Json"
#TestValues####################################

$msg = "Parm1 = $parm1 --- Parm2 = $parm2 --- Parm3 = $parm3"

# Write-Output $msg

# throw "haha"

$ReturnOBJ = [PSCustomObject] [ordered] @{ADHC_Computer = "Iets";
                                          Message = $msg;
                                          OK = $true}
    
$ReturnJSON = ConvertTo-JSON $ReturnOBJ     
        
return $ReturnJSON


