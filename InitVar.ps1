# Setting of all global variables named ADHC_<something>

$InformationPreference = "Continue"
$WarningPreference = "Continue"

$Version = " -- Version: 1.28"
$Node = " -- Node: " + $env:COMPUTERNAME
$d = Get-Date
$Datum = " -- Date: " + $d.ToShortDateString()
$Tijd = " -- Time: " + $d.ToShortTimeString()
$Scriptmsg = "PowerShell script " + $MyInvocation.MyCommand.Name + $Version + $Datum + $Tijd +$Node
Write-Information $Scriptmsg 

Remove-Variable -Name "ADHC_User" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_User" -Value "$env:USERNAME" -Option readonly -Scope global -Description "Current user" -force

Remove-Variable -Name "ADHC_Computer" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_Computer" -Value "$env:COMPUTERNAME" -Option readonly -Scope global -Description "Name of this computer" -force

$Hostlist = "ADHC","Laptop-AHMRDH","Holiday" 
Remove-Variable -Name "ADHC_Hostlist" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_Hostlist" -Value $Hostlist -Option readonly -Scope global -Description "List of known hosts" -force

$TrustedHosts = ""
$i = 1
foreach ($myHost in $ADHC_Hostlist) {
    if ($I -eq 1) {
        $TrustedHosts = $TrustedHosts + $myHost
    }
    else { 
        $TrustedHosts = $TrustedHosts + "," + $myHost
    }
    $i = $i + 1
}
# write $ADHC_TrustedHosts
Remove-Variable -Name "ADHC_TrustedHosts" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_TrustedHosts" -Value $TrustedHosts -Option readonly -Scope global -Description "Trusted host list" -force

Remove-Variable -Name "ADHC_PSdir" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_PSdir" -Value "C:/ADHC/PowerShell/" -Option readonly -Scope global -Description "Powershell production directory" -force

$usr = $env:USERPROFILE + "/Documents/WindowsPowerShell/"
Remove-Variable -Name "ADHC_PSUdir" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_PSUdir" -Value "$usr" -Option readonly -Scope global -Description "Powershell production user directory" -force

Remove-Variable -Name "ADHC_SympaPgm" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_SympaPgm" -Value "C:/ADHC/Sympa/WMIC 3.pyw" -Option readonly -Scope global -Description "Python production SYMPA source" -force

$prof = $env:USERPROFILE -split '\\'

switch ($ADHC_Computer) { 
        
        "Ahmrdh-Netbook"{$OneDrive = "P:/" + $prof[2] + "/OneDrive/"} 
        "Holiday"       {$OneDrive = "D:/" + $prof[2] + "/OneDrive/"} 
        
        default         {$OneDrive = "D:/" + $prof[2] + "/OneDrive/"} 
    }
Remove-Variable -Name "ADHC_OneDrive" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_OneDrive" -Value $OneDrive -Option readonly -Scope global -Description "Name of OneDrive share" -force

$staging = $OneDrive + "Staging Library/"
Remove-Variable -Name "ADHC_StagingDir" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_StagingDir" -Value $staging -Option readonly -Scope global -Description "Staging root directory" -force

$devdir = $OneDrive + "ADHC Dev/"
Remove-Variable -Name "ADHC_DevelopDir" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_DevelopDir" -Value $devdir -Option readonly -Scope global -Description "Development root directory" -force

Remove-Variable -Name "ADHC_ProdDir" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_ProdDir" -Value "C:/ADHC/" -Option readonly -Scope global -Description "Production directory" -force

$compare = $OneDrive + "ProductionCompare/"
Remove-Variable -Name "ADHC_ProdCompareDir" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_ProdCompareDir" -Value $compare -Option readonly -Scope global -Description "Production compare directory" -force

$sctl = $OneDrive + "SourceControl/"
Remove-Variable -Name "ADHC_SourceControl" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_SourceControl" -Value $sctl -Option readonly -Scope global -Description "Source Control directory" -force

$diskspace = $OneDrive + "DiskSpace/"
Remove-Variable -Name "ADHC_DiskSpace" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_DiskSpace" -Value $diskspace -Option readonly -Scope global -Description "Disk space report directory" -force

$haveibeenpwned = $OneDrive + "HaveIBeenPwned/"
Remove-Variable -Name "ADHC_HaveIBeenPwned" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_HaveIBeenPwned" -Value $haveibeenpwned -Option readonly -Scope global -Description "HaveIBeenPwned HTML output directory" -force

$conflicts = $OneDrive + "Conflicts/"
Remove-Variable -Name "ADHC_ConflictsDir" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_ConflictsDir" -Value $conflicts -Option readonly -Scope global -Description "Onedrive Conficts report directory" -force

$wmicdir = $OneDrive + "WmicFiles/"
Remove-Variable -Name "ADHC_WmicDir" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_WmicDir" -Value $wmicdir -Option readonly -Scope global -Description "Wmic files directory" -force

$arg = 'name="' + $ADHC_User + '"'
$x =Get-WmiObject -Class win32_useraccount -filter "$arg"
Remove-Variable -Name "ADHC_SID" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_SID" -Value $x.SID -Option readonly -Scope global -Description "SID value for current user" -force

Remove-Variable -Name "ADHC_Caption" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_Caption" -Value $x.Caption -Option readonly -Scope global -Description "Caption value for current user" -force

switch ($ADHC_Computer)
    { 
        "ADHC"          {$StartTime = "2016-11-01T15:00:00"} 
       
        "Laptop_AHMRDH" {$StartTime = "2016-11-01T21:00:00"} 
        "empty slot"    {$StartTime = "2016-11-01T12:00:00"} 
        "Holiday"       {$StartTime = "2016-11-01T18:00:00"}
        default         {$StartTime = "2016-11-01T06:00:00"} 
    }
    
Remove-Variable -Name "ADHC_WmicAnalyze_StartTime" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_WmicAnalyze_StartTime" -Value $StartTime -Option readonly -Scope global -Description "Start time for WMIC analyze run" -force

switch ($ADHC_Computer)
    { 
        
        "Ahmrdh-Netbook"{$PythonExec = "C:/Program Files/Python36-32/pythonw.exe"}
        "Holiday"       {$PythonExec = "D:/Program Files/Python38/pythonw.exe"}
       
        default         {$PythonExec = "C:/Program Files/Python38/pythonw.exe"} 
    }
Remove-Variable -Name "ADHC_PythonExec" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_PythonExec" -Value $PythonExec -Option readonly -Scope global -Description "Path to PYTHON executable" -force

$PythonArgCreate = '"' + $ADHC_Sympapgm + '" "--mode=Create" "--outputdir=' + $ADHC_WmicDir + '"'
 
Remove-Variable -Name "ADHC_PythonArgCreate" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_PythonArgCreate" -Value $PythonArgCreate -Option readonly -Scope global -Description "Path to PYTHON arguments - CREATE" -force

$PythonArgAnalyze = '"' + $ADHC_Sympapgm + '" "--mode=Analyze" "--outputdir=' + $ADHC_WmicDir + '"'
 
Remove-Variable -Name "ADHC_PythonArgAnalyze" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_PythonArgAnalyze" -Value $PythonArgAnalyze -Option readonly -Scope global -Description "Path to PYTHON arguments - ANALYZE" -force



$SourceTargetList = @([PSCustomObject]@{source="Sympa";target="C:/ADHC/Sympa/";type="Module"}, `
                        [PSCustomObject]@{source="Java";target="C:/ADHC/Java/";type="Module"}, `
                        [PSCustomObject]@{source="AdHC Site";target="C:/ADHC/AdHC Site/";type="Module"}, `
                        [PSCustomObject]@{source="Visual Basic";target="C:/ADHC/Visual Basic/";type="Module"}, `
                        [PSCustomObject]@{source="Powershell";target="C:/ADHC/Powershell/";type="Module"}, `
                        [PSCustomObject]@{source="ContactSync";target="C:/ADHC/ContactSync/";type="Module"}, `
                        [PSCustomObject]@{source="Windows Scheduler";target="C:/ADHC/Windows Scheduler/";type="Schedule"}, `
                        [PSCustomObject]@{source="WindowsPowerShell";target="$ADHC_PSUdir";type="Module"}) 
# write $SourceTargetList   
# write $SourceTargetList[0].source 
Remove-Variable -Name "ADHC_SourceTargetList" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_SourceTargetList" -Value $SourceTargetList -Option readonly -Scope global -Description "Source and target definition" -force 

Remove-Variable -Name "ADHC_DslLocation" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_DslLocation" -Value "D:/Software/DSL/"  -Option readonly -Scope global -Description "Location of DSL" -force 

Return
