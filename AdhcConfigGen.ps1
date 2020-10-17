# Mass update of GIT config files

$Version = " -- Version: 3.1"

# COMMON coding
CLS

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
& "$LocalInitVar"

# END OF COMMON CODING

function Set_Value ([string]$istr) {
    if ($istr.Length -gt 6) {
        if ($istr.substring(0,6) -eq '$ADHC_'){ 
           $istr = Invoke-Expression($istr); 
        } 
    } 
    return $istr

}


$masterxml = [xml](Get-Content $ADHC_MasterXml)

$factorylist = $masterxml.ADHCmaster.ChildNodes
$version = $masterxml.ADHCmaster.Version
write-host " "
Write-Host "Master XML version = $version"
write-host " "

foreach ($factory in $factorylist) {
    
    $factroot = $factory.Root
    $factroot = Set_Value($factroot)
    
    $subdevdir = $factory.SubRoot
    Write-Host "Factory = $subdevdir"
   
    $nodes = $factory.ADHCinfo.Nodes
    $nodes = Set_Value($nodes)  
    write-host "Target nodes = $nodes"

    [xml]$xmldoc = New-Object System.Xml.XmlDocument
    $decl = $xmldoc.CreateXmlDeclaration('1.0','UTF-8',$null)
    [void]$xmldoc.AppendChild($decl)

    $adhcinfo = $xmldoc.CreateElement("ADHCinfo")
    $adhcinfo.SetAttribute("Version",$version)
    $adhcinfo.SetAttribute("Nodes", $nodes)
    $adhcinfo.SetAttribute("Factory", $factroot)
    $adhcinfo.SetAttribute("SubRoot", $subdevdir)
    

    $liblist = $factory.ADHCinfo.CHildNodes
    Write-Host "Libnames: "
    foreach ($lib in $liblist) {
        $Naam = $lib.Name        Write-Host "Naam =   $Naam"

        $root = $lib.Root
        $root = Set_Value($root)
        Write-Host "Root = $root"

        $subroot = $lib.SubRoot
        If ($subroot -eq "*") {
            $subroot = $subdevdir
        }
        Write-Host "Subroot = $subroot"

        $Process = $lib.Process
        Write-Host "Process = $Process"

        $Delay = $lib.Delay
        Write-Host "Delay = $Delay"
                
        $ModulesList = $lib.ChildNodes
        $cnt = $lib.ChildNodes.Count
        Write-Host "Aantal MODULES entries: $cnt"

        
        $comment = $false
        switch ($Naam.ToUpper().Trim()) {
            "STAGELIB" {
                $thischild = $xmldoc.CreateElement("StageLib")
            }
            "TARGET" { 
                $thischild = $xmldoc.CreateElement("Target") 
            }
            "DSL" { 
                $thischild = $xmldoc.CreateElement("DSL") 
            }
            "#COMMENT" {
                $txt = $lib.InnerText 
                $thischild = $xmldoc.CreateComment($txt) 
                $comment = $true
            }
            default {
                Write-Error "$Naam niet herkend"
                Exit 16
            } 
        }
        
            
        if (!$comment) {  
            $thischild.SetAttribute("Root",$root)
            $thischild.SetAttribute("SubRoot", $subroot)                      
            foreach ($modentry in $ModulesList) {
                $m = $xmldoc.CreateElement("Modules")

                $p = $modentry.Process
                if ($p) {
                    if ($p -eq "*") {
                        $mprocess = $Process
                }
                    else {
                        $mprocess = $p
                    }
                }
                else {
                    $mprocess = $Process
                }
                $m.SetAttribute("Process",$mprocess)

                $dly = $modentry.Delay
                if ($dly) {
                    $mdelay= $dly
                }
                else {
                    $mdelay = $Delay 
                }    
                $m.SetAttribute("Delay",$mdelay)

                $Include = $modentry.Include
                if (!$Include) {
                    $Include = "*ALL*"
                } 
                $Exclude = $modentry.Exclude
                if (!$Exclude) {
                    $Exclude = "*None*"
                } 

                $i = $xmldoc.CreateElement("Include")
                $i.InnerText = $Include
               
                $e = $xmldoc.CreateElement("Exclude")
                $e.InnerText = $Exclude

                [void]$m.AppendChild($i)
                [void]$m.AppendChild($e)
                
                [void]$thischild.AppendChild($m)
            }
        }

        [void]$adhcinfo.AppendChild($thischild)
    }
     
    [void]$xmldoc.AppendChild($adhcinfo)

    # Write xml to config dataset
    $outdir = $ADHC_DevelopDir + $subdevdir
    
    New-Item -ItemType Directory -Force -Path $outdir | Out-Null
    $fullname = $ADHC_StagingDir + $subdevdir + $ADHC_configfile
    $xmlDoc.Save($fullName)

    write-host " "
    
}

