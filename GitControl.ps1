CLS

$InformationPreference = "Continue"
$WarningPreference = "Continue"

$Version = " -- Version: 1.2"
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


Set-Location -Path $ADHC_DevelopDir
$gitdirs = Get-ChildItem "*.git" -Recurse
$ofile = $ADHC_SourceControl + "gitoutput.txt"

$gitstatus = $ADHC_SourceControl + "gitstatus.txt"
&{Write-Information $Scriptmsg} 6>&1 5>&1 4>&1 3>&1 2>&1 > $gitstatus


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

    &{git log ADHCentral/master..HEAD} 6>&1 5>&1 4>&1 3>&1 2>&1 > $ofile
    $a = Get-Content $ofile
    # $a
    if ([string]::IsNullOrEmpty($a)) {
        &{Write-Information "==> No unpushed commits"} 6>&1 5>&1 4>&1 3>&1 2>&1 >> $gitstatus
    }
    else {
        &{Write-Warning "==> Unpushed commits       ***"} 6>&1 5>&1 4>&1 3>&1 2>&1 >> $gitstatus
        
    }
    Remove-Item $ofile
}

