function Get-FileMetaData {

 
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Alias(‘FullName’, ‘PSPath’)]
        [string[]]$Path
    )
 
    begin {
        $oShell = New-Object -ComObject Shell.Application
    }
 
    process {
        $Path | ForEach-Object {
 
            if (Test-Path -Path $_ -PathType Leaf) {
 
                $FileItem = Get-Item -Path $_
 
                $oFolder = $oShell.Namespace($FileItem.DirectoryName)
                $oItem = $oFolder.ParseName($FileItem.Name)
 
                $props = @{}
 
                0..287 | ForEach-Object {
                    $ExtPropName = $oFolder.GetDetailsOf($oFolder.Items, $_)
                    $ExtValName = $oFolder.GetDetailsOf($oItem, $_)
               
                    if (-not $props.ContainsKey($ExtPropName) -and  ($ExtPropName -ne "")) {
                       $props.Add($ExtPropName, $ExtValName)
                    } 
                }
                New-Object PSObject -Property $props
            }
        }
    }
 
    end {
        $oShell = $null
    }
}




$InformationPreference = "Continue"
$WarningPreference = "Continue"

$Version = " -- Version: 1.7"
$Node = " -- Node: " + $env:COMPUTERNAME
$d = Get-Date
$Datum = " -- Date: " + $d.ToShortDateString()
$Tijd = " -- Time: " + $d.ToShortTimeString()
$Scriptmsg = "PowerShell script " + $MyInvocation.MyCommand.Name + $Version + $Datum + $Tijd +$Node
Write-Information $Scriptmsg 

[void][System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.RootFolder = "MyComputer"
    $foldername.SelectedPath = "D:\Data\Sync Gedeeld\Vakanties\"
    

    if ($foldername.ShowDialog() -eq "OK")
    {
        $folder = $foldername.SelectedPath
    }



$FileList = Get-ChildItem $folder -recurse   | Select-Object FullName
#$FileList | Out-Gridview



$outputlist = New-Object System.Collections.ArrayList


foreach ($image in $Filelist) {
    $a = Get-ItemProperty -Path $image.FullName
    $image.FullName
    #$a
    $b = $image.FullName | Get-FileMetaData
    #$b
    if ($b.Cameramodel -eq "DMC-TZ60") {

        $listitem = New-Object PSObject
        Add-Member -InputObject $listitem -MemberType NoteProperty -Name FullName -Value $image.FullName
        #$format = "d-M-yyyy HH:mm"
        #$str = $b.'Genomen op'.Trim()
        #$str1 = $str -replace '\s',' '        

        #$translate = [DateTime]::ParseExact($str1, $format, $null)
        $cijferstring = $b.'Genomen op'.Trim()
        $stringlengte = $cijferstring.length
        [string[]]$cijferreeks = @("","","","","") 
        $reeksindex = -1
        $digitcurrent = $false
        $getal = ""
        
        for ($i=0; $i -lt $stringlengte; $i++) {
            $char = $cijferstring.Substring($i,1)
            # write-host "Char = " + $char
            if ("$char" -match '^\d$') {
                if ($digitcurrent) {
                    $getal = "$getal{0}" -f "$char"
                }
                else {
                    $getal = $char
                    $digitcurrent = $true                
                }
            }
            else {
                if ($digitcurrent) {
                    $reeksindex = $reeksindex + 1
                    $cijferreeks[$reeksindex] = $getal
                    $digitcurrent = $false
                    
                }
            }        
        }
        if ($digitcurrent) {
            $cijferreeks[$reeksindex+1] = $getal
        }
        
        $dag = $cijferreeks[0]
        $maand = $cijferreeks[1]
        $jaar = $cijferreeks[2]
        $uur = $cijferreeks[3]
        $minuut = $cijferreeks[4]

        $Genomen_OUD = Get-Date -Year $jaar -Month $maand -Day $dag -Hour $uur -Minute $minuut
        Add-Member -InputObject $listitem -MemberType NoteProperty -Name Genomen_OUD -Value $Genomen_OUD

        $Genomen_NIEUW = (Get-Date -Date $Genomen_OUD).AddHours(-1).AddMinutes(-13)
        Add-Member -InputObject $listitem -MemberType NoteProperty -Name Genomen_NIEUW -Value $Genomen_NIEUW

        [void]$outputlist.Add($listitem)
    }

   
}
$outputlist | Out-GridView
$outputlist |  Out-file "D:\Data\Sync Gedeeld\Vakanties\2017-3 Portugal\FotoTijden.txt"

