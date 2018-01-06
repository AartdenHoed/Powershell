$InformationPreference = "Continue"
$WarningPreference = "Continue"

$Version = " -- Version: 1.1"
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

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$InputFile = $ADHC_HaveIBeenPwned + "haveibeenpwned.txt"
$emaillist = Get-Content $inputfile

$pawnlist = New-Object System.Collections.ArrayList

foreach ($record in $emaillist) { 
    $mailaddress = $record.Trim()    
    
    try {
        Start-Sleep -s 2
        $em = Invoke-RestMethod -Method Get -uri "https://haveibeenpwned.com/api/v2/breachedaccount/$mailaddress" -ErrorAction SilentlyContinue
        
        foreach ($entry in $em) {
            $DataClasses =[system.String]::Join(", ", $entry.DataClasses)
            $AddedDate = Get-Date $entry.AddedDate -format dd-MMM-yyyy
            $AddedDate = "<nobr>"+ $AddedDate + "</nobr>"
            $BreachDate = Get-Date $entry.Breachdate -format dd-MMM-yyyy 
            $BreachDate = "<nobr>"+ $BreachDate + "</nobr>"
            $Domain = "<nobr>"+ $entry.Domain + "</nobr>"

            $showem = new-object psobject
            
            $showem | Add-Member -MemberType NoteProperty -Name "DataClasses" -Value "$DataClasses"
            $showem | Add-Member -MemberType NoteProperty -Name "AddedDate" -Value "$AddedDate"
            $showem | Add-Member -MemberType NoteProperty -Name "BreachDate" -Value "$BreachDate"
            $showem | Add-Member -MemberType NoteProperty -Name "Title" -Value $entry.Title
            $showem | Add-Member -MemberType NoteProperty -Name "Domain" -Value "$Domain"
            $showem | Add-Member -MemberType NoteProperty -Name "IsSensitive" -Value $entry.IsSensitive
            $showem | Add-Member -MemberType NoteProperty -Name "Description" -Value $entry.Description
            $showem | Add-Member -MemberType NoteProperty -Name "Mail Adres" -Value "<nobr>$mailaddress</nobr>"
            $showem | Add-Member -MemberType NoteProperty -Name "ReturnCode" -Value "Attention"

            $pawnlist += $showem
            Write-Warning "==> $mailaddress Possibly compromised!!!"
            Clear-Variable showem

            
        }
        
            
    }
    catch {
        $showem = new-object psobject
        
        if ($_.Exception.Response.StatusCode.value__ -eq "404") {
            $RC = "OK"
            $showem | Add-Member -MemberType NoteProperty -Name "Title" -Value "<nobr>** No Breaches Found **</nobr>"
            Write-Information "No breaches found for $mailaddress"
        }
        else {
            $RC = $_.Exception.Response.StatusCode.value__ 
            $showem | Add-Member -MemberType NoteProperty -Name "Title" -Value "<nobr> *** ERROR *** $_.Exception.Response.StatusDescription</nobr>"
            Write-Error "ERROR in script for $mailaddress"
        }
        
            
        $showem | Add-Member -MemberType NoteProperty -Name "DataClasses" -Value ""
        $showem | Add-Member -MemberType NoteProperty -Name "AddedDate" -Value ""
        $showem | Add-Member -MemberType NoteProperty -Name "BreachDate" -Value ""
        
        $showem | Add-Member -MemberType NoteProperty -Name "Domain" -Value ""
        $showem | Add-Member -MemberType NoteProperty -Name "IsSensitive" -Value ""
        $showem | Add-Member -MemberType NoteProperty -Name "Description" -Value ""
        $showem | Add-Member -MemberType NoteProperty -Name "Mail Adres" -Value "<nobr>$mailaddress</nobr>"
        $showem | Add-Member -MemberType NoteProperty -Name "ReturnCode" -Value "$RC"

        $pawnlist += $showem        
        
        Clear-Variable showem
    }


    try {
        Start-Sleep -s 2
        $em1 = Invoke-RestMethod -Method Get -uri "https://haveibeenpwned.com/api/v2/pasteaccount/$mailaddress" -ErrorAction SilentlyContinue
        
        foreach ($entry in $em1) {
            $DataClasses = "Paste with id " + $Entry.ID           
           
            $BreachDate = Get-Date $entry.Date -format dd-MMM-yyyy 
            $BreachDate = "<nobr>"+ $BreachDate + "</nobr>"

            $Domain = "<nobr>"+ $entry.Source + "</nobr>"

            $showem = new-object psobject
            
            $showem | Add-Member -MemberType NoteProperty -Name "DataClasses" -Value "$DataClasses"
            $showem | Add-Member -MemberType NoteProperty -Name "AddedDate" -Value ""
            $showem | Add-Member -MemberType NoteProperty -Name "BreachDate" -Value "$BreachDate"
            $showem | Add-Member -MemberType NoteProperty -Name "Title" -Value "Mail address found in paste"
            $showem | Add-Member -MemberType NoteProperty -Name "Domain" -Value "$Domain"
            $showem | Add-Member -MemberType NoteProperty -Name "IsSensitive" -Value ""
            $showem | Add-Member -MemberType NoteProperty -Name "Description" -Value $entry.Title
            $showem | Add-Member -MemberType NoteProperty -Name "Mail Adres" -Value "<nobr>$mailaddress</nobr>"
            $showem | Add-Member -MemberType NoteProperty -Name "ReturnCode" -Value "Attention"

            $pawnlist += $showem
            Write-Warning "==> $mailaddress Possibly compromised!!!"
            Clear-Variable showem

            
        }
        
            
    }
    catch {
        $showem = new-object psobject
        
        if ($_.Exception.Response.StatusCode.value__ -eq "404") {
            $RC = "OK"
            $showem | Add-Member -MemberType NoteProperty -Name "Title" -Value "<nobr>** No Pastes Found **</nobr>"
            Write-Information "No pastes found for $mailaddress"
        }
        else {
            $RC = $_.Exception.Response.StatusCode.value__ 
            $showem | Add-Member -MemberType NoteProperty -Name "Title" -Value "<nobr> *** ERROR *** $_.Exception.Response.StatusDescription</nobr>"
            Write-Error "ERROR in script for $mailaddress"
        }
        
            
        $showem | Add-Member -MemberType NoteProperty -Name "DataClasses" -Value ""
        $showem | Add-Member -MemberType NoteProperty -Name "AddedDate" -Value ""
        $showem | Add-Member -MemberType NoteProperty -Name "BreachDate" -Value ""
        
        $showem | Add-Member -MemberType NoteProperty -Name "Domain" -Value ""
        $showem | Add-Member -MemberType NoteProperty -Name "IsSensitive" -Value ""
        $showem | Add-Member -MemberType NoteProperty -Name "Description" -Value ""
        $showem | Add-Member -MemberType NoteProperty -Name "Mail Adres" -Value "<nobr>$mailaddress</nobr>"
        $showem | Add-Member -MemberType NoteProperty -Name "ReturnCode" -Value "$RC"

        $pawnlist += $showem        
        
        Clear-Variable showem
    }

    
    

}


#$pawnlist | Out-GridView
$a = "<style>"
$a = $a + "BODY{background-color:peachpuff;}"
$a = $a + 'TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse; }'
$a = $a + "TH{border-width: 2px;border-style: solid;border-color: black; padding: 5px;}"
$a = $a + "TD{border-width: 2px;border-style: solid;border-color: black; padding: 5px;}"
$a = $a + "</style>"

$b = "<H1>Haveibeenpwned Overzicht</H2><H3>$scriptmsg</H3>"

$htmlfile = $ADHC_HaveIBeenPwned +  "HaveIBeenPwned.html"

$pawnlist | Select-Object 'Mail Adres',ReturnCode,Title,Domain,BreachDate,AddedDate,Dataclasses,IsSensitive,Description| `
    ConvertTo-HTML -head $a -body $b -title $b `
        | Out-File "$htmlfile"

$convert = Get-Content "$htmlfile"
$convert = $convert.Replace('&lt;',"<")
$convert = $convert.Replace('&gt;',">")
$convert = $convert.Replace('&quot;','"')

$convert | Set-Content "$htmlfile"


Invoke-Item "$htmlfile"