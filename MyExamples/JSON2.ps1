param (
    [string]$Mode = "JSON") 

write-host "Mode = " $mode
   

$MessageList = @()


 $msgentry = [PSCustomObject] [ordered] @{Level = "I";
                                             Message = "Boodschap 1"}
 $MessageList += $msgentry

 
 $msgentry = [PSCustomObject] [ordered] @{Level = "A";
                                             Message = "Boodschap 2"}
 $MessageList += $msgentry

 
 $msgentry = [PSCustomObject] [ordered] @{Level = "W";
                                             Message = "Boodschap 3"}
 $MessageList += $msgentry



if ($Mode.ToUpper() -eq  "JSON" ) {
       
    $ReturnJSON = ConvertTo-JSON $MessageList     
     
    return $ReturnJSON 
}
else {
    
    Return $MessageList   
}