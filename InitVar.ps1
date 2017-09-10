# Setting of all global variables named ADHC_<something>

$InformationPreference = "Continue"
$WarningPreference = "Continue"

$Version = " -- Version: 1.10"
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

$Hostlist = "ADHC","Zolder-II","Laptop-AHMRDH","Woonkamer","Ahmrdh-Netbook","Holiday" 
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
Set-Variable -Name "ADHC_PSdir" -Value "C:\ADHC\PowerShell\" -Option readonly -Scope global -Description "Powershell production directory" -force

$staging = $env:USERPROFILE + "\OneDrive\Staging Library\"
Remove-Variable -Name "ADHC_StagingDir" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_StagingDir" -Value $staging -Option readonly -Scope global -Description "Staging root directory" -force

Remove-Variable -Name "ADHC_ProdDir" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_ProdDir" -Value "C:\ADHC\" -Option readonly -Scope global -Description "Production directory" -force

$compare = $env:USERPROFILE + "\OneDrive\ProductionCompare\"
Remove-Variable -Name "ADHC_ProdCompareDir" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_ProdCompareDir" -Value $compare -Option readonly -Scope global -Description "Production compare directory" -force

$conflicts = $env:USERPROFILE + "\OneDrive\Conflicts\"
Remove-Variable -Name "ADHC_ConflictsDir" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_ConflictsDir" -Value $conflicts -Option readonly -Scope global -Description "Onedrive Conficts report directory" -force



$arg = 'name="' + $ADHC_User + '"'
$x =Get-WmiObject -Class win32_useraccount -filter "$arg"
Remove-Variable -Name "ADHC_SID" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_SID" -Value $x.SID -Option readonly -Scope global -Description "SID value for current user" -force
Remove-Variable -Name "ADHC_Caption" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_Caption" -Value $x.Caption -Option readonly -Scope global -Description "Caption value for current user" -force

switch ($ADHC_Computer)
    { 
        "ADHC"          {$StartTime = "2016-11-01T15:00:00"} 
        "Zolder-II"     {$StartTime = "2016-11-01T09:00:00"} 
        "Laptop_AHMRDH" {$StartTime = "2016-11-01T21:00:00"} 
        "Woonkamer"     {$StartTime = "2016-11-01T12:00:00"} 
        "Holiday"       {$StartTime = "2016-11-01T18:00:00"}
        default         {$StartTime = "2016-11-01T06:00:00"} 
    }
    
Remove-Variable -Name "ADHC_WmicAnalyze_StartTime" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_WmicAnalyze_StartTime" -Value $StartTime -Option readonly -Scope global -Description "Start time for WMIC analyze run" -force

switch ($ADHC_Computer)
    { 
        "ADHC"          {$PythonExec = "C:\Program Files (x86)\Python36-32\pythonw.exe"} 
        "Ahmrdh-Netbook"{$PythonExec = "C:\Program Files (x86)\Python36-32\pythonw.exe"}
        "Holiday"       {$PythonExec = "C:\Program Files (x86)\Python36-32\pythonw.exe"}
        "Zolder-II"     {$PythonExec = "C:\Program Files (x86)\Python36-32\pythonw.exe"}
        "Laptop_AHMRDH" {$PythonExec = "C:\Program Files (x86)\Python36-32\pythonw.exe"}
        "Woonkamer"     {$PythonExec = "C:\Program Files (x86)\Python36-32\pythonw.exe"} 
        default         {$PythonExec = "C:\Program Files (x86)\Python36-32\pythonw.exe"} 
    }
Remove-Variable -Name "ADHC_PythonExec" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_PythonExec" -Value $PythonExec -Option readonly -Scope global -Description "Path to PYTHON executable" -force

$usr = $env:USERPROFILE + "\Documents\WindowsPowerShell\"
$SourceTargetList = @([PSCustomObject]@{source="Sympa";target="C:\ADHC\Sympa\";type="Module"}, `
                        [PSCustomObject]@{source="Java";target="C:\ADHC\Java\";type="Module"}, `
                        [PSCustomObject]@{source="AdHC Site";target="C:\ADHC\AdHC Site\";type="Module"}, `
                        [PSCustomObject]@{source="Visual Basic";target="C:\ADHC\Visual Basic\";type="Module"}, `
                        [PSCustomObject]@{source="Powershell";target="C:\ADHC\Powershell\";type="Module"}, `
                        [PSCustomObject]@{source="ContactSync";target="C:\ADHC\ContactSync\";type="Module"}, `
                        [PSCustomObject]@{source="Windows Scheduler";target="C:\ADHC\Windows Scheduler\";type="Schedule"}, `
                        [PSCustomObject]@{source="PowershellProfile";target="$usr";type="Module"}) 
# write $SourceTargetList   
# write $SourceTargetList[0].source 
Remove-Variable -Name "ADHC_SourceTargetList" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_SourceTargetList" -Value $SourceTargetList -Option readonly -Scope global -Description "Source and target definition" -force 

Remove-Variable -Name "ADHC_DslLocation" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_DslLocation" -Value "D:\Software\DSL\"  -Option readonly -Scope global -Description "Location of DSL" -force 

Return
