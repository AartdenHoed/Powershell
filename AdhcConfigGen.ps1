# Mass update of GIT config files

$Version = " -- Version: 1.0"

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
    $devdir = $factory.Root
    $subdevdir = $factory.SubRoot
    $devdir = Set_Value($devdir) 
    Write-Host "Development directory = $devdir"
    Write-Host "Development subdirectory = $subdevdir"
   
    $nodes = $factory.ADHCinfo.Nodes
    $nodes = Set_Value($nodes) 
    

    [xml]$xmldoc = New-Object System.Xml.XmlDocument
    $decl = $xmldoc.CreateXmlDeclaration('1.0','UTF-8',$null)
    [void]$xmldoc.AppendChild($decl)

    $adhcinfo = $xmldoc.CreateElement("ADHCinfo")
    $adhcinfo.SetAttribute("Version",$version)
    $adhcinfo.SetAttribute("Nodes", $nodes)
    

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
        $modules = $lib.Modules
        switch ($Naam.ToUpper()) {
            "STAGELIB" {
                $build = $lib.Build
                Write-Host "Build = $build"
                $stagelib = $xmldoc.CreateElement("StageLib")
                $stagelib.SetAttribute("Root",$root)
                $stagelib.SetAttribute("SubRoot", $subroot)
                $stagelib.SetAttribute("Build", $build)

                $m = $xmldoc.CreateElement("Modules")
                $m.InnerText = $modules
                [void]$stagelib.AppendChild($m)
                [void]$adhcinfo.AppendChild($stagelib)

               
            }
            "TARGET" { 
                $deploy = $lib.Deploy
                Write-Host "Deploy = $deploy"
                $tdelay = $lib.Delay
                Write-Host "Delay = $tdelay"
                $target = $xmldoc.CreateElement("Target")
                $target.SetAttribute("Root",$root)
                $target.SetAttribute("SubRoot", $subroot)
                $target.SetAttribute("Deploy", $deploy)
                $target.SetAttribute("Delay", $tdelay)

                $m = $xmldoc.CreateElement("Modules")
                $m.InnerText = $modules
                [void]$target.AppendChild($m)
                [void]$adhcinfo.AppendChild($target)
            }
            "DSL" { 
                $ddelay = $lib.Delay
                Write-Host "Delay = $ddelay"
                $dsl = $xmldoc.CreateElement("DSL")
                $dsl.SetAttribute("Root",$root)
                $dsl.SetAttribute("SubRoot", $subroot)
                $dsl.SetAttribute("Delay", $ddelay)

                $m = $xmldoc.CreateElement("Modules")
                $m.InnerText = $modules
                [void]$dsl.AppendChild($m)
                [void]$adhcinfo.AppendChild($dsl)
            }
            default {
                Write-Error "$Naam niet herkend"
                Exit 16
            } 
        }

    } 
    [void]$xmldoc.AppendChild($adhcinfo)

    # Write xml to config dataset
    $outdir = $devdir + $subdevdir
    
    New-Item -ItemType Directory -Force -Path $outdir | Out-Null
    $fullname = $devdir + $subdevdir + $ADHC_configfile
    $xmlDoc.Save($fullName)



    
     write-host " "
    


}

