$Version = " -- Version: 1.0"

# COMMON coding
CLS

# init flags
$global:scripterror = $false
$global:scriptaction = $false
$global:scriptchange = $false

$global:recordslogged = $false

$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"



# =============================
function WriteXmlToScreen ([xml]$xml)
{
    # Function to write XML to log for PRTG
    $StringWriter = New-Object System.IO.StringWriter;
    $XmlWriter = New-Object System.Xml.XmlTextWriter $StringWriter;
    $XmlWriter.Formatting = "indented";
    $xmlWriter.QuoteChar = '"'
    $xml.WriteTo($XmlWriter);
    $XmlWriter.Flush();
    $StringWriter.Flush();
    # Write-Host $StringWriter.ToString();
    # Set-Content $ofile $StringWriter.ToString()
    $StringWriter.ToString() | Out-File -Encoding "UTF8" $ofile
    Write-Host "XML file $ofile created succesfully"
}
# =============================

try {
    $Node = " -- Node: " + $env:COMPUTERNAME
    $d = Get-Date
    $Datum = " -- Date: " + $d.ToString("dd-MM-yyyy")
    $Tijd = " -- Time: " + $d.ToString("HH:mm:ss")

    $myname = $MyInvocation.MyCommand.Name
    $enqprocess = $myname.ToUpper().Replace(".PS1","")
    $FullScriptName = $MyInvocation.MyCommand.Definition
    $mypath = $FullScriptName.Replace($MyName, "")

    $Scriptmsg = "*** STARTED *** " + $mypath + " -- PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node
    Write-Information $Scriptmsg 

    $LocalInitVar = $mypath + "InitVar.PS1"
    & "$LocalInitVar"

    if (!$ADHC_InitSuccessfull) {
        # Write-Warning "YES"
        throw $ADHC_InitError
    }
   
    # END OF COMMON CODING   

    $ContactFile = $ADHC_OutlookInput

    $ofile = $ADHC_OutlookOutput

    $ContactCSV = Get-Content $ContactFile

    $ContactOBJ = ConvertFrom-Csv -InputObject $ContactCSV -Delimiter ',' 

    $AantalContacten = $ContactOBJ.Count
    Write-Host "Totaal aantal contacten in input = $AantalContacten"


    [xml]$xmldoc = New-Object System.Xml.XmlDocument
    $decl = $xmldoc.CreateXmlDeclaration('1.0','UTF-8',$null)

    [void]$xmldoc.AppendChild($decl)

    $Phonebooks = $xmldoc.CreateElement('phonebooks')

    $Phonebook = $xmldoc.CreateElement('phonebook')

    $Phonebook.SetAttribute('name','iCloud Contacts')


    $AantalMetNummer = 0
    $AantalZonderNummer = 0
    foreach ($entry in $ContactOBJ) {
        if ($entry.'Hoofdtelefoon bedrijf' -or $entry.'Telefoon op werk' -or $entry.'Mobiele telefoon' -or $entry.'Telefoon thuis') {
            $AantalMetNummer += 1
            $Contact = $xmldoc.CreateElement('contact')
            [void]$Phonebook.Appendchild($contact)

            $category = $xmldoc.CreateElement('category') 
            $category.InnerText = "0"
            [void]$contact.Appendchild($category)

            $person = $xmldoc.CreateElement('person') 
            [void]$contact.Appendchild($person)

            $realName = $xmldoc.CreateElement('realName') 

            if ($entry.Achternaam -and $entry.Voornaam) {
                $Namestring = $entry.Achternaam + ", " + $entry.Voornaam
            } 
            else {
                if ($entry.Achternaam) {
                    $Namestring = $entry.Achternaam
                }
                if ($entry.Voornaam) {
                    $Namestring = $entry.Voornaam
                }
            }
            if ($entry.'Middelste naam') {
                $Namestring = $Namestring + " " + $entry.'Middelste naam' 
            }
            if ($entry.Bedrijf) {
                $Namestring = $Namestring + " (" + $entry.Bedrijf + ")" 
            }
            $realName.InnerText = $Namestring
            [void]$person.Appendchild($realName)

            $nrofids = 0
            $currentid = -1
            $priority = 1
            $telephony = $xmldoc.CreateElement('telephony')
        
            if ($entry.'Hoofdtelefoon bedrijf') {
                $currentid += 1
                $nrofids += 1
                $numberB = $xmldoc.CreateElement('number') 
            
                $numberB.SetAttribute('id',"$currentid")
            
                $numberB.SetAttribute('prio',"$priority")
                if ($priority -eq 1) {
                    # first number has prio = 1
                    $priority = 0
                }
            
                $numberB.SetAttribute('type',"work")

                $numberB.InnerText = $entry.'Hoofdtelefoon bedrijf'
                [void]$telephony.AppendChild($numberB)
            }
            if ($entry.'Telefoon thuis') {
                $currentid += 1
                $nrofids += 1
                $numberH = $xmldoc.CreateElement('number') 
            
                $numberH.SetAttribute('id',"$currentid")
            
                $numberH.SetAttribute('prio',"$priority")
                if ($priority -eq 1) {
                    # first number has prio = 1
                    $priority = 0
                }
            
                $numberH.SetAttribute('type',"home")

                $numberH.InnerText = $entry.'Telefoon thuis'
                [void]$telephony.AppendChild($numberH)
            }
            if ($entry.'Mobiele telefoon') {
                $currentid += 1
                $nrofids += 1
                $numberM = $xmldoc.CreateElement('number') 
            
                $numberM.SetAttribute('id',"$currentid")
            
                $numberM.SetAttribute('prio',"$priority")
                if ($priority -eq 1) {
                    # first number has prio = 1
                    $priority = 0
                }
            
                $numberM.SetAttribute('type',"mobile")

                $numberM.InnerText = $entry.'Mobiele telefoon'
                [void]$telephony.AppendChild($numberM)
            }
            if ($entry.'Telefoon op werk') {
                $currentid += 1
                $nrofids += 1
                $numberW = $xmldoc.CreateElement('number') 
            
                $numberW.SetAttribute('id',"$currentid")
            
                $numberW.SetAttribute('prio',"$priority")
                if ($priority -eq 1) {
                    # first number has prio = 1
                    $priority = 0
                }
            
                $numberW.SetAttribute('type',"work")

                $numberW.InnerText = $entry.'Telefoon op werk'
                [void]$telephony.AppendChild($numberW)
            }

            [void]$telephony.SetAttribute('nid',"$nrofids")
            [void]$contact.Appendchild($telephony)

            $services = $xmldoc.CreateElement('services')

            if ($entry.'E-mailadres') {          
                
                $services.SetAttribute('nid','1')
                $email = $xmldoc.CreateElement("email")
                $email.SetAttribute("id","0")
                $email.SetAttribute("classifier","private")

                $email.InnerText = $entry.'E-mailadres'
                [void]$services.AppendChild($email)            

            } 
            [void]$contact.AppendChild($services)

            $setup = $xmldoc.CreateElement('setup')
            [void]$contact.AppendChild($setup)

            $mod_time = $xmldoc.CreateElement('mod_time')
            $mod_time.InnerText = "1500000010"
            [void]$contact.AppendChild($mod_time)

            $uniqueid = $xmldoc.CreateElement('uniqueid')
            $uniqueid.InnerText = "1"
            [void]$contact.AppendChild($uniqueid)




        }
        else {
            $AantalZonderNummer += 1
        }
    }

    [void]$Phonebooks.Appendchild($phonebook)
    [void]$xmldoc.Appendchild($Phonebooks)

    Write-Host "Totaal aantal contacten met telefoonnummer = $AantalMetNummer"
    Write-Host "Totaal aantal contacten zonder telefoonnummer = $AantalZonderNummer"

    WriteXmlToScreen $xmldoc
}

catch {
    write-warning "Catch"
    $global:scripterror = $true
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    $Dump = $_.Exception.ToString()
}
finally {
    if ($global:scripterror) {
        Write-Host ">>> Script ended abnormally"
               
        Write-Host $jobstatus "Failed item = $FailedItem"
        Write-Host $jobstatus "Errormessage = $ErrorMessage"
        Write-Host $jobstatus "Dump info = $dump"
    }
    else {
        $Scriptmsg = "*** ENDED *** " + $mypath + " -- PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node
        Write-Information $Scriptmsg 

    }
}