# Get all local working repos
cls
$ErrorActionPreference = "Continue"
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
$repolist = Get-ChildItem $ADHC_DevelopDir -Directory | Select-Object Name, Fullname
foreach ($sourcerepo in $repolist) {
    $sourcelocation = $sourcerepo.FullName    
    $targetlocation = $sourcelocation.ToUpper().Replace("ADHC DEVELOPMENT","ADHC RemoteRepository") 
    Write-Host " "
    Write-Host "======================================================================================="
    Write-Host "Source location   = $sourceLocation"
   

    Set-Location $sourcelocation
    & git clone . "$targetlocation"
    & git remote rm ADHCentral
    & git remote add ADHCentral "$targetlocation"
    Write-Host "---------------------------------------------------------------------------------------"
    if (Test-Path $targetlocation) {
        $note = " exits"
    }
    else {
        $note = " *** NOT FOUND ***"
        throw "$targetlocation NOT FOUND"
    }
    Write-Host "Target location   = $targetLocation $note"

    

    Set-Location $targetlocation
    $quals = $targetlocation.SPlit("\")
    $c = $quals.count - 1
    $gitname = $quals[$c].Replace(".GIT","")     
     
    $gitlocation = "git@github.com:AartdenHoed/" + $gitname

    Write-Host "Git location      = $gitlocation"

    &git remote add GITHUB "$gitlocation"
    &git config core.sshCommand C:/Windows/System32/OpenSSH/ssh.exe


    Write-Host "======================================================================================="


       
}


$Scriptmsg = "*** ENDED ***** " + $mypath + " -- PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node
Write-Host " "
Write-Information $Scriptmsg 
