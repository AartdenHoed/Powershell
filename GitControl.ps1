CLS

$InformationPreference = "Continue"
$WarningPreference = "Continue"

$Version = " -- Version: 1.4"
$Node = " -- Node: " + $env:COMPUTERNAME
$d = Get-Date
$Datum = " -- Date: " + $d.ToShortDateString()
$Tijd = " -- Time: " + $d.ToShortTimeString()
$Scriptmsg = "PowerShell script " + $MyInvocation.MyCommand.Name + $Version + $Datum + $Tijd +$Node

$FullScriptName = $MyInvocation.MyCommand.Definition
$ScriptName = $MyInvocation.MyCommand.Name
$ADHC_PsPath = $FullScriptName.Replace($ScriptName, "")
$ADHC_InitVar = $ADHC_PsPath + "InitVar.PS1"
& "$ADHC_InitVar"

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
    # $dir
    
    &{git status} 6>&1 5>&1 4>&1 3>&1 2>&1 > $ofile
    $a = Get-Content $ofile
    # $a[1]
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
    $a[0]
    if ($a[0] -eq "git : Everything up-to-date")  {
        &{Write-Information "==> No unpushed commits"} 6>&1 5>&1 4>&1 3>&1 2>&1 >> $gitstatus
    }
    else {
        &{Write-Warning "==> Unpushed commits       ***"} 6>&1 5>&1 4>&1 3>&1 2>&1 >> $gitstatus
        
    }
    Remove-Item $ofile
}

