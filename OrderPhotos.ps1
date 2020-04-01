
CLS
Write-Warning "Dit script zet een datum prefix voor elke foto-bestandsnaam in de vorm 'yyyymmdd-hhmm-vv-'"
Write-Warning "Die prefix wordt gehaald uit de foto attribuut 'GENOMEN OP' indien aanwezig."Write-Warning "Indien niet aanwezig dan wordt het attribuut 'GEWIJZIGD OP' gebruikt."
Write-Warning "Er kan ook een correctie worden aagebracht op het timestamp 'GENOMEN OP'"
$InformationPreference  = "Continue"
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


#
# Select directory
#

[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null
Add-Type -AssemblyName System.Windows.Forms

$foldername = New-Object System.Windows.Forms.FolderBrowserDialog
$foldername.Description = "Select a folder"
$foldername.SelectedPath = "D:\Data\Sync Gedeeld\Vakanties"

if ($foldername.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true })) -eq "OK")
{
    $folder = $foldername.SelectedPath
}
else 
{
    $msg = "Cancelled by user..."
    Write-Warning $msg   
}
    
   

# Get all image files 

Set-Location "$folder"
$subdirs = Get-ChildItem -Directory -Recurse | Select-Object Fullname
$x = Get-Location
$Photodirs = @($x.Path)
foreach ($member in $subdirs) {
    $Photodirs += $member.Fullname
}


#  | Select-Object Name, Fullname, Extension | `
#            Where-Object { $_.Extension -eq '.JPG' -or $_.Extension -eq '.PNG' -or $_.Extension -eq '.MP4' -or $_.Extension -eq '.MOV'}

$metalist= @()
$t = Get-Date
Write-Information "$t - Start inlezen attributen" 
$nn = 0
foreach ($dir in $Photodirs) {   

    $t = Get-Date
    Write-Information "$t - Processing $dir" 
    
    $a = 0 
    $objShell = New-Object -ComObject Shell.Application 
    $objFolder = $objShell.namespace($dir) 
 
    foreach ($File in $objFolder.items()) 
    {  
        $nn = $nn + 1
        $FileMetaData = New-Object PSOBJECT
        for ($a ; $a  -le 266; $a++) 
        {  
            if($objFolder.getDetailsOf($File, $a)) 
            { 
                $hash += @{$($objFolder.getDetailsOf($objFolder.items, $a))  = 
                    $($objFolder.getDetailsOf($File, $a)) } 
            $FileMetaData | Add-Member $hash -force
            $hash.clear()  
            } #end if 
        } #end for  
        $a=0 
        $metalist += $FileMetaData
        # $FileMetaData 
    } #end foreach $file 
}
$t = Get-Date
Write-Information "$t - Attributen van $nn bestanden ingelezen"
$t = Get-Date
Write-Information "$t - Start renamen bestanden"
$nn = 0
foreach ($fotobestand in $metalist) {
    $nn = $nn + 1
    if ($fotobestand.Bestandsextensie -eq ".JPG" -or `
        $fotobestand.Bestandsextensie -eq ".PNG" -or `
        $fotobestand.Bestandsextensie -eq ".MOV" -or `
        $fotobestand.Bestandsextensie -eq ".MP4") {

        $naam = $fotobestand.Naam
        $pad = $fotobestand.'Pad naar map'
            
        if ($fotobestand.'Genomen op' -ne $null) {
            $timestamp = $fotobestand.'Genomen op'
            $verb = " Genomen op: " 
            
        }
        else {
            $timestamp = $fotobestand.'Gewijzigd op'
            $verb = " Gemaakt op: "
           
        }
        $cijfers = $timestamp.split("- :")

        $dag = $cijfers[0] -replace '[^0-9]', ''
        $idag = [convert]::ToInt32($dag, 10)
        $cdag = $idag.ToString("00")

        $maand = $cijfers[1] -replace '[^0-9]', ''
        $imaand = [convert]::ToInt32($maand, 10)
        $cmaand = $imaand.ToString("00")

        $jaar = $cijfers[2] -replace '[^0-9]', ''
        $ijaar = [convert]::ToInt32($jaar, 10)
        $cjaar = $ijaar.ToString("00")

        $uur = $cijfers[3] -replace '[^0-9]', ''
        $iuur = [convert]::ToInt32($uur, 10)
        # Correctie uren
        $uurcorrectie = -2
        $iuur = $iuur + $uurcorrectie 
        # Einde correctie
        
        $minuut = $cijfers[4] -replace '[^0-9]', ''
        $iminuut = [convert]::ToInt32($minuut, 10)
        # Correctie minuten
        $minuutcorrectie = +2
        $imnuut = $iminuut +$minuutcorrectie
        if ($minuut -ge 60) {
            $iuur = $iuur + 1
            $iminuut = $iminuut - 60
        }
        # Einde correctie

        $cuur = $iuur.ToString("00")
        $cminuut = $iminuut.ToString("00")

        $prefix = $cjaar + $cmaand + $cdag + "-" + $cuur + $cminuut + "-01-"
        # $msg = "Oude naam = $pad\$naam $verb $timestamp *** Nieuwe naam = $pad\$prefix$naam" 
        # Write-Information $msg
        
        $cstr = $prefix + "*"
        if (-not ($naam -like $cstr)) {
            Rename-Item "$pad\$naam"  "$pad\$prefix$naam" 
        }
        else {
            Write-Warning "$naam skipped: already renamed"
        }
    }
  
    
}
$t = Get-Date
Write-Information "$t - Ready: $nn Bestanden renamed"

