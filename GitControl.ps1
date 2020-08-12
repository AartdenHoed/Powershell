$Version = " -- Version: 1.6"

# COMMON coding
$InformationPreference = "Continue"
$WarningPreference = "Continue"


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

# Init reporting file
$str = $ADHC_SourceControl.Split("/")
$dir = $ADHC_OutputDirectory + $str[0]
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$gitstatus = $ADHC_OutputDirectory + $ADHC_SourceControl

&{Write-Information $Scriptmsg} 6>&1 5>&1 4>&1 3>&1 2>&1 > $gitstatus

Set-Location -Path $ADHC_DevelopDir
$gitdirs = Get-ChildItem "*.git" -Recurse -Force
$ofile = $ADHC_OutputDirectory + $ADHC_SourceControl + "gitoutput.txt"

foreach ($gitentry in $gitdirs) {
    $dir = $gitentry.FullName
   
    $dir = $dir.replace(".git","")
    &{Write-Information ""} 6>&1 5>&1 4>&1 3>&1 2>&1 >> $gitstatus
    &{Write-Information "Directory $dir"} 6>&1 5>&1 4>&1 3>&1 2>&1 >> $gitstatus

    Set-Location $dir
    Write-Host ">>> $dir"
    
    &{git status} 6>&1 5>&1 4>&1 3>&1 2>&1 > $ofile
    $a = Get-Content $ofile
    $x = $a[1]
    Write-Host "    $x"
    if ($a[1] -eq "nothing to commit, working tree clean") {
        &{Write-Information "==> No uncommitted changes"} 6>&1 5>&1 4>&1 3>&1 2>&1 >> $gitstatus
    }
    else {
        &{Write-Warning "==> Uncommitted changes    ***"} 6>&1 5>&1 4>&1 3>&1 2>&1 >> $gitstatus
    }
    Remove-Item $ofile

    #&{git log ADHCentral/master..HEAD} 6>&1 5>&1 4>&1 3>&1 2>&1 > $ofile
    &{git push ADHCentral master --dry-run} 6>&1 5>&1 4>&1 3>&1 2>&1 > $ofile
    $a = Get-Content $ofile
    $x = $a[0]
    Write-Host "    $x"
    if ($a[0] -eq "git : Everything up-to-date")  {
        &{Write-Information "==> No unpushed commits"} 6>&1 5>&1 4>&1 3>&1 2>&1 >> $gitstatus
    }
    else {
        &{Write-Warning "==> Unpushed commits       ***"} 6>&1 5>&1 4>&1 3>&1 2>&1 >> $gitstatus
        
    }
    Remove-Item $ofile
}

