﻿# Rename photos so they can easily be sorted by date
$Version = " -- Version: 1.5"
CLS
Write-Warning "Dit script zet een datum prefix voor elke foto-bestandsnaam in de vorm 'yyyymmdd-hhmm-vv-'"
Write-Warning "Die prefix wordt gehaald uit de foto attribuut 'GENOMEN OP' indien aanwezig."Write-Warning "Indien niet aanwezig dan wordt het attribuut 'GEWIJZIGD OP' gebruikt."
Write-Warning "Er kan ook een correctie worden aagebracht op het timestamp 'GENOMEN OP'"

# COMMON coding

$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"

$Node = " -- Node: " + $env:COMPUTERNAME
$d = Get-Date
$Datum = " -- Date: " + $d.ToShortDateString()
$Tijd = " -- Time: " + $d.ToShortTimeString()

$myname = $MyInvocation.MyCommand.Name
$FullScriptName = $MyInvocation.MyCommand.Definition
$mypath = $FullScriptName.Replace($MyName, "")

$Scriptmsg = "Directory " + $mypath + " -- PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node
Write-Information $Scriptmsg 

$LocalInitVar = $mypath + "InitVar.PS1"
$InitObj = & "$LocalInitVar" "MSG"

if ($Initobj.Abend) {
    # Write-Warning "YES"
    throw "INIT script $LocalInitVar Failed"

}

# END OF COMMON CODING


#
# Select directory
#

[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null
Add-Type -AssemblyName System.Windows.Forms

$foldername = New-Object System.Windows.Forms.FolderBrowserDialog
$foldername.Description = "Select a folder"
$foldername.SelectedPath = $ADHC_HolidayDir

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
$tot = 0
$media = 0

foreach ($dir in $Photodirs) {   

    $t = Get-Date
    Write-Information "$t - Processing $dir" 
    
    $a = 0 
    $objShell = New-Object -ComObject Shell.Application 
    $objFolder = $objShell.namespace($dir) 
 
    foreach ($File in $objFolder.items()) 
    {  
        $tot = $tot + 1
        $myext = $File.Type.Substring(0,3).ToUpper()
        
        if (!(($myext -eq "JPG") -or ($myext -eq "PNG") -or ($myext -eq "MP4") -or ($myext -eq "MOV"))) {            
            # SKIP files that are not JPG-PNG-MP4-MOV
            continue
        } 
                
        $media = $media + 1
        $FileMetaData = New-Object PSOBJECT
        for ($a ; $a  -le 266; $a++) 
        {  
            if($objFolder.getDetailsOf($File, $a)) 
            { 
                $hash += @{$($objFolder.getDetailsOf($objFolder.items, $a))  = 
                    $($objFolder.getDetailsOf($File, $a)) } 
            $FileMetaData | Add-Member $hash -force
            #$hash
            $hash.clear()  
            } #end if 
        } #end for  

        $a=0 

        $p = $File.Path.Replace($File.Name, '') + "\"
        $hash = @{"ThisPath" = $p}
        $FileMetaData | Add-Member $hash -force
        $hash.clear()

        $metalist += $FileMetaData
        # $FileMetaData 
    } #end foreach $file 
}
$t = Get-Date
Write-Information "$t - Attributen van $tot bestanden ingelezen"
$t = Get-Date
Write-Information "$t - Start renamen bestanden"
$nn = 0
$cc = 0
$nc = 0
$ns = 0
foreach ($fotobestand in $metalist) {       
    

    $naam = $fotobestand.Naam
    $pad = $fotobestand.ThisPath
    
    if ($fotobestand.Cameramodel) {
        $cameramodel = $fotobestand.Cameramodel.Trim()
    }
    else {
        $Cameramodel = "Onbekend"
    }
        
            
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
    $minuut = $cijfers[4] -replace '[^0-9]', ''
    $iminuut = [convert]::ToInt32($minuut, 10)

    # Filter hier op naam of iets anders voor de foto's die WEL een tijd correctie moeten krijgen
    if ($naam -like "*"){  
    
        $timecorrection = $false      
            
        switch ($Cameramodel.Trim()) {
            "iets" {
                $timecorrection = $true
                # Correctie uren ============================================================================================
                $uurcorrectie = -1
                $iuur = $iuur + $uurcorrectie 
                # Einde correctie ===========================================================================================
                    
                # Correctie minuten =========================================================================================
                $minuutcorrectie = 0
                $iminuut = $iminuut +$minuutcorrectie
                if ($iminuut -ge 60) {
                    $iuur = $iuur + 1
                    $iminuut = $iminuut - 60
                }
                if ($iminuut -lt 0) {
                    $iuur = $iuur - 1
                    $iminuut = $iminuut + 60
                }
                # Einde correctie ===========================================================================================
                
            }
            "DMC-TZ80"  {
                                
            }
            "iPhone XR" {
                
            } 
            "Onbekend" {
                
                
            }   
            default {
                               
            }   

        }          
            
    }

    $cuur = $iuur.ToString("00")
    $cminuut = $iminuut.ToString("00")

    $prefix = $cjaar + $cmaand + $cdag + "-" + $cuur + $cminuut + "-01-"
    # $msg = "Oude naam = $pad\$naam $verb $timestamp *** Nieuwe naam = $pad\$prefix$naam" 
    # Write-Information $msg
        
    $cstr = $prefix + "*"
    if (-not ($naam -like $cstr)) {
        # Write-Host "$pad\$naam ==> $pad\$prefix$naam"
        Rename-Item "$pad\$naam"  "$pad\$prefix$naam" 
        $nn = $nn + 1
        if ($timecorrection) {
            $cc = $cc + 1
        }
        else {
            $nc = $nc + 1
        }       
    }
    else {
        Write-Warning "$naam skipped: already renamed"
        $ns = $ns + 1
    }
}

$t = Get-Date
Write-Information "$t - Ready: $tot files found, of which $media were media files, $ns files skipped, $nn Media files renamed, $cc with time correction, $nc without timecorrection"

