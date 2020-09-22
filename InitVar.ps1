# Setting of all global variables named ADHC_<something>

$InformationPreference = "Continue"
$WarningPreference = "Continue"

$Version = " -- Version: 2.1.2"
$Node = " -- Node: " + $env:COMPUTERNAME
$d = Get-Date
$Datum = " -- Date: " + $d.ToShortDateString()
$Tijd = " -- Time: " + $d.ToShortTimeString()
$myname = $MyInvocation.MyCommand.Name
$Scriptmsg = "PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node
Write-Information $Scriptmsg 

Remove-Variable -Name "ADHC_InitVar" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_Initvar" -Value "$myname" -Option readonly -Scope global -Description "Name of INIT script" -force

$FullScriptName = $MyInvocation.MyCommand.Definition
$mypath = $FullScriptName.Replace($MyName, "")
Remove-Variable -Name "ADHC_PsPath" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_PsPath" -Value "$mypath" -Option readonly -Scope global -Description "Name of powershell path" -force

Remove-Variable -Name "ADHC_User" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_User" -Value "$env:USERNAME" -Option readonly -Scope global -Description "Current user" -force

Remove-Variable -Name "ADHC_Computer" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_Computer" -Value "$env:COMPUTERNAME" -Option readonly -Scope global -Description "Name of this computer" -force

$Hostlist = "ADHC","Laptop-AHMRDH","Holiday" 
Remove-Variable -Name "ADHC_Hostlist" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_Hostlist" -Value $Hostlist -Option readonly -Scope global -Description "List of known hosts" -force

$hoststring = ""
foreach ($h in $Hostlist) {
    $hoststring = $hoststring + "~" + $h + "~"
} 
$hoststring = $hoststring.Replace("~~", "," )
$hoststring = $hoststring.Replace("~", "" )

Remove-Variable -Name "ADHC_Hoststring" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_Hoststring" -Value $hoststring -Option readonly -Scope global -Description "List of known hosts (string)" -force


Remove-Variable -Name "ADHC_ConfigFile" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_ConfigFile" -Value "#Config.adhc" -Option readonly -Scope global -Description "ADHC config filename" -force

$dl = "Deploy/" + $ADHC_Computer + "_Deploy.log"
Remove-Variable -Name "ADHC_DeployLog" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_DeployLog" -Value "$dl" -Option readonly -Scope global -Description "Deployment log file" -force

$dt = "Deploy/" + $ADHC_Computer + "_DeployReport.txt"
Remove-Variable -Name "ADHC_DeployReport" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_DeployReport" -Value "$dt" -Option readonly -Scope global -Description "Deployment report file" -force

$cf = "Conflicts/" + $ADHC_Computer + "_Conflicts.txt"
Remove-Variable -Name "ADHC_ConflictRpt" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_ConflictRpt" -Value "$cf" -Option readonly -Scope global -Description "Conflict report file" -force

$gs = "SourceControl/" + $ADHC_Computer + "_GitStatus.txt"
Remove-Variable -Name "ADHC_SourceControl" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_SourceControl" -Value "$gs" -Option readonly -Scope global -Description "Status of GIT directories" -force

$pc = "ProductionCompare/"+ $ADHC_Computer + "_Compare.txt"
Remove-Variable -Name "ADHC_ProdCompare" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_ProdCompare" -Value "$pc" -Option readonly -Scope global -Description "Check correctness deployments" -force

$vx = "VariableXref/"+ $ADHC_Computer + "_VariableXref.txt"
Remove-Variable -Name "ADHC_VarXref" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_VarXref" -Value "$vx" -Option readonly -Scope global -Description "XREF between sources and variables" -force

Remove-Variable -Name "ADHC_JobStatus" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_Jobstatus" -Value "JobStatus/" -Option readonly -Scope global -Description "Jobs status directory" -force

Remove-Variable -Name "ADHC_PRTGlogs" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_PRTGlogs" -Value "PRTGsensorLogs/" -Option readonly -Scope global -Description "PRTG log directory" -force

$usr = $env:USERPROFILE + "/Documents/"
Remove-Variable -Name "ADHC_PSUdir" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_PSUdir" -Value "$usr" -Option readonly -Scope global -Description "Powershell production user directory" -force

$prof = $env:USERPROFILE -split '\\'

switch ($ADHC_Computer) { 
        
        "Ahmrdh-Netbook"{$OneDrive = "P:/" + $prof[2] + "/OneDrive/"} 
        "Holiday"       {$OneDrive = "D:/" + $prof[2] + "/OneDrive/"} 
        "ADHC"          {$OneDrive = "D:/AartenHetty" + "/OneDrive/"}
        default         {$OneDrive = "D:/" + $prof[2] + "/OneDrive/"} 
    }
Remove-Variable -Name "ADHC_OneDrive" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_OneDrive" -Value $OneDrive -Option readonly -Scope global -Description "Name of OneDrive share" -force

$output = $ADHC_OneDrive + "Output/"
Remove-Variable -Name "ADHC_OutputDirectory" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_OutputDirectory" -Value $output -Option readonly -Scope global -Description "Common root directory for output files" -force

$staging = $OneDrive + "ADHC StagingLibrary/"
Remove-Variable -Name "ADHC_StagingDir" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_StagingDir" -Value $staging -Option readonly -Scope global -Description "Staging root directory" -force

$devdir = $OneDrive + "ADHC Development/"
Remove-Variable -Name "ADHC_DevelopDir" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_DevelopDir" -Value $devdir -Option readonly -Scope global -Description "Development root directory" -force

Remove-Variable -Name "ADHC_DSLDir" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_DSLDir" -Value "D:\Software\DSL\" -Option readonly -Scope global -Description "DSL root directory" -force

Remove-Variable -Name "ADHC_ProdDir" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_ProdDir" -Value "C:\ADHC\" -Option readonly -Scope global -Description "Production root directory" -force

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

$master = $devdir + "ADHCmaster\ADHCmaster.xml"
Remove-Variable -Name "ADHC_MasterXml" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_MasterXml" -Value $master -Option readonly -Scope global -Description "Path to PYTHON arguments - ANALYZE" -force

Return
