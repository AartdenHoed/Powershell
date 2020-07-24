#Captures ARP Table then Displays ALL IPs that match the local computers IP Address
CLS
#Set the file you wish for the data to Output to
$myfile = "D:\AartenHetty\OneDrive\ArpA\Test.txt"

#Captures the devices IP Scheme and break it down, remove the Last Octet from the string
#This section is only used IF you are trying to filter the ARP by the local network the device is on.
$ComputerName = $env:computername
$OrgSettings = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $ComputerName -EA Stop | ? { $_.IPEnabled }
$myip = $OrgSettings.IPAddress[0]

$ip = (([ipaddress] $myip).GetAddressBytes()[0..2] -join ".") + "."
$ip = $ip.TrimEnd(".")
Write-Warning "Executing on IP $myip, looking for ip-addresses in range $ip"

#Searches the ARP table for IPs that match the scheme and parses out the data into an Array (It removed the Devices IP from the list.)

$macarray = @()
$arpa = (arp -a) 
foreach ($line in $arpa) {
    # Write-Warning "Line: $line"
    $words =  $line.TrimStart() -split '\s+'
    $thisIP = $words[0].Trim()
    if ($thisIP -match $ip) {
        $thisMac = $words[1] 
        
        Write-Warning "Handling IP address $thisIP with MacAddress $thisMac"
        $obj = [PSCustomObject] [ordered]  @{IP = $thisIP; MAC = $thisMac}
        
        if (!($obj.MAC -eq "---" -or $obj.MAC -eq "Address" -or $obj.MAC -eq $null -or $obj.MAC -eq "ff-ff-ff-ff-ff-ff")) {
            $macarray += $obj
        }
       
    }
   
}
            
#Outputting the IP Addresses captured.
remove-item $myfile -Force -ErrorAction SilentlyContinue 
foreach ($entry in $macarray) {
    
    Export-Csv -InputObject $entry -Delimiter '~' -Force -Append `
            -LiteralPath $myfile -NoTypeInformation
}

$macarray | Out-GridView    

