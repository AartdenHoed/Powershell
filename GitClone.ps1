# Get all local working repos

#Total RE_INIT
#rm -rf .git
#git init
#git add .
#git commit -m 'Re-initialize repository without old history.'


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
       
    
    Write-Host " "
    Write-Host "======================================================================================="
    Write-Host "Source location   = $sourceLocation"

    $targetlocation = $sourcelocation.ToUpper().Replace("ADHC DEVELOPMENT","ADHC RemoteRepository").Replace('\',"/") 
    #New-Item -ItemType Directory -Force -Path  $targetlocation | Out-Null
    if (Test-Path $targetlocation) {
        $note = " exits"
    }
    else {
        $note = " *** NOT FOUND ***"
        throw "$targetlocation NOT FOUND"
    }
    Write-Host "Target location   = $targetLocation $note" 
    
    $quals = $sourcelocation.SPlit("\")
    $c = $quals.count - 1
    $gitname = $quals[$c]
     
    $gitlocation = "git@github.com:AartdenHoed/" + $gitname 
    Set-Location $sourcelocation

    #####################################################################################################
    
    #Write-host "git remote rm ADHCentral"
    #& git remote rm ADHCentral

    Write-Host "git remote rm GITHUB"
    & git remote rm GITHUB

    #Write-Host "git clone --bare . $targetlocation" 
    #& git clone --bare . "$targetlocation"

    #Write-Host "git remote add ADHCentral $targetlocation"
    #& git remote add ADHCentral "$targetlocation"

    Write-Host "git remote add GITHUB $gitlocation"
    & git remote add GITHUB "$gitlocation"

    #Write-Host "git config core.sshCommand C:/Windows/System32/OpenSSH/ssh.exe"
    #& git config core.sshCommand C:/Windows/System32/OpenSSH/ssh.exe

    #####################################################################################################

    Write-Host "======================================================================================="
 
}


$Scriptmsg = "*** ENDED ***** " + $mypath + " -- PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node
Write-Host " "
Write-Information $Scriptmsg 
