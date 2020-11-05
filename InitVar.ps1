# Setting of all global variables named ADHC_<something>
param (
    [string]$JSON = "NO"    
)
# $JSON = 'YES'


$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"

if ($ADHC_InitSuccessfull) {
    Write-Host "Double"
    return
}

class InitVarException : System.Exception  { 
    InitVarException( [string]$message) : base($message) {

    }

    InitVarException() {

    }
}

$MyError = [InitVarException]::new("INITVAR.PS1 failed - fatal error")
Remove-Variable -Name "ADHC_InitSuccesfull" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_InitSuccessfull" -Value $true -Option readonly -Scope global -Description "INITVAR Succesfull or not" -force
Remove-Variable -Name "ADHC_InitError" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_InitError" -Value $MyError -Option readonly -Scope global -Description "INITVAR user error" -force
    

try {
    $Version = " -- Version: 5.0"
    $Node = " -- Node: " + $env:COMPUTERNAME
    $d = Get-Date
    $Datum = " -- Date: " + $d.ToShortDateString()
    $Tijd = " -- Time: " + $d.ToShortTimeString()
    $myname = $MyInvocation.MyCommand.Name
    $Scriptmsg = "PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node
    if ($JSON.ToUpper() -ne "YES") {
        Write-Information $Scriptmsg 
    }

    # GENERAL

    Remove-Variable -Name "ADHC_InitVar" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_Initvar" -Value "$myname" -Option readonly -Scope global -Description "Name of INIT script" -force

    Remove-Variable -Name "ADHC_ConfigFile" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_ConfigFile" -Value "#Config.adhc" -Option readonly -Scope global -Description "ADHC config filename" -force

    Remove-Variable -Name "ADHC_User" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_User" -Value "$env:USERNAME" -Option readonly -Scope global -Description "Current user" -force

    

    Remove-Variable -Name "ADHC_Computer" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_Computer" -Value "$env:COMPUTERNAME" -Option readonly -Scope global -Description "Name of this computer" -force

    $Hostlist = "ADHC","Laptop-AHMRDH","Holiday" 
    Remove-Variable -Name "ADHC_Hostlist" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_Hostlist" -Value $Hostlist -Option readonly -Scope global -Description "List of known hosts" -force

    # $a = 0/0 # Test abend

    $hoststring = ""
    foreach ($h in $Hostlist) {
        $hoststring = $hoststring + "~" + $h + "~"
    } 
    $hoststring = $hoststring.Replace("~~", "," )
    $hoststring = $hoststring.Replace("~", "" )

    Remove-Variable -Name "ADHC_Hoststring" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_Hoststring" -Value $hoststring -Option readonly -Scope global -Description "List of known hosts (string)" -force

    # ONEDRIVE
    
    $prof = $env:USERPROFILE -split '\\'

    switch ($ADHC_Computer) { 
        
            "Ahmrdh-Netbook"{$OneDrive = "P:\" + $prof[2] + "\OneDrive\"} 
            "Holiday"       {$OneDrive = "D:\" + $prof[2] + "\OneDrive\"} 
            "ADHC"          {$OneDrive = "D:\AartenHetty" + "\OneDrive\"}
            default         {$OneDrive = "D:\" + $prof[2] + "\OneDrive\"} 
        }
    Remove-Variable -Name "ADHC_OneDrive" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_OneDrive" -Value $OneDrive -Option readonly -Scope global -Description "Name of OneDrive share" -force    

    $remdir = $OneDrive + "ADHC RemoteRepository\"
    Remove-Variable -Name "ADHC_RemoteDir" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_RemoteDir" -Value $remdir -Option readonly -Scope global -Description "Remote repository root directory" -force

    $devdir = $OneDrive + "ADHC Development\"
    Remove-Variable -Name "ADHC_DevelopDir" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_DevelopDir" -Value $devdir -Option readonly -Scope global -Description "Development root directory" -force

    # POWERSHELL PATHs 

    $usr = $env:USERPROFILE + "\Documents\"
    Remove-Variable -Name "ADHC_PSUdir" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_PSUdir" -Value "$usr" -Option readonly -Scope global -Description "Powershell production user directory" -force

    $FullScriptName = $MyInvocation.MyCommand.Definition
    $mypath = $FullScriptName.Replace($MyName, "")
    Remove-Variable -Name "ADHC_PsPath" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_PsPath" -Value "$mypath" -Option readonly -Scope global -Description "Name of powershell path" -force

    $ls = $mypath + "Globallock.ps1"
    Remove-Variable -Name "ADHC_LockScript" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_LockScript" -Value "$ls" -Option readonly -Scope global -Description "Name of Global Lock script" -force

    # OUTPUT FILES
    
    $output = $ADHC_OneDrive + "ADHC Output\"
    Remove-Variable -Name "ADHC_OutputDirectory" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_OutputDirectory" -Value $output -Option readonly -Scope global -Description "Common root directory for output files" -force
    
    $boot = "BootTime\" + $ADHC_Computer + "_BootTime.txt"
    Remove-Variable -Name "ADHC_BootTime" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_BootTime" -Value "$boot" -Option readonly -Scope global -Description "Last BOOT time file" -force
    
    $ng = "BuildDeployCheck\"+ $ADHC_Computer + "_BuildDeployCheck.txt"
    Remove-Variable -Name "ADHC_BuildDeployCheck" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_BuildDeployCheck" -Value "$ng" -Option readonly -Scope global -Description "Check correctness deployments" -force
    
    $cf = "Conflicts\" + $ADHC_Computer + "_Conflicts.txt"
    Remove-Variable -Name "ADHC_ConflictRpt" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_ConflictRpt" -Value "$cf" -Option readonly -Scope global -Description "Conflict report file" -force

    $encoder = new-object System.Text.UTF8Encoding
    $bytes = $encoder.Getbytes('nZr4u7w!z%C*F-JaNdRgUkXp2s5v8y/A')
    $secfile = $output + "PRTG\SaveString.txt"
    $sec = Get-Content $secfile
    $SecureString = ConvertTo-SecureString $sec -Key $bytes
    $Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList "ADHCode", $Securestring 
    Remove-Variable -Name "ADHC_Credentials" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_Credentials" -Value $Credentials -Option readonly -Scope global -Description "Credentials" -force

    $dl = "Deploy\" +  "#Overall_Deploy.log"
    Remove-Variable -Name "ADHC_DeployLog" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_DeployLog" -Value "$dl" -Option readonly -Scope global -Description "Deployment log file" -force

    $dt = "Deploy\" + $ADHC_Computer + "_DeployReport.txt"
    Remove-Variable -Name "ADHC_DeployReport" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_DeployReport" -Value "$dt" -Option readonly -Scope global -Description "Deployment report file" -force

    $gpa = "GitPushAll\" + $ADHC_Computer + "_GitPushAll.txt"
    Remove-Variable -Name "ADHC_GitPushAll" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_GitPushAll" -Value "$gpa" -Option readonly -Scope global -Description "GIT 'Push All' execution" -force

    $pu = "GitPushAll\" + "#Overall_Push.log"
    Remove-Variable -Name "ADHC_PushLog" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_PushLog" -Value "$pu" -Option readonly -Scope global -Description "Push log file" -force
    
    $lock = $output + "GlobalLock\"
    Remove-Variable -Name "ADHC_LockDir" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_LockDir" -Value $lock -Option readonly -Scope global -Description "Directory for Global Locks" -force
    
    $gs = "SourceControl\" + $ADHC_Computer + "_GitStatus.txt"
    Remove-Variable -Name "ADHC_SourceControl" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_SourceControl" -Value "$gs" -Option readonly -Scope global -Description "Status of GIT directories" -force
    
    Remove-Variable -Name "ADHC_JobStatus" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_Jobstatus" -Value "JobStatus\" -Option readonly -Scope global -Description "Jobs status directory" -force
    
    Remove-Variable -Name "ADHC_PRTGlogs" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_PRTGlogs" -Value "PRTGsensorLogs\" -Option readonly -Scope global -Description "PRTG log directory" -force

    $vx = "VariableXref\"+ $ADHC_Computer + "_VariableXref.txt"
    Remove-Variable -Name "ADHC_VarXref" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_VarXref" -Value "$vx" -Option readonly -Scope global -Description "XREF between sources and variables" -force

    # STAGING DIRECTORY
   
    $staging = $OneDrive + "ADHC StagingLibrary\"
    Remove-Variable -Name "ADHC_StagingDir" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_StagingDir" -Value $staging -Option readonly -Scope global -Description "Staging root directory" -force

    $master = $staging + "ADHCmaster\ADHCmaster.xml"
    Remove-Variable -Name "ADHC_MasterXml" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_MasterXml" -Value $master -Option readonly -Scope global -Description "Path to PYTHON arguments - ANALYZE" -force

    # DSL directory   

    Remove-Variable -Name "ADHC_DSLDir" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_DSLDir" -Value "D:\Software\DSL\" -Option readonly -Scope global -Description "DSL root directory" -force

    #PRODUCTION DIRECTORY
    
    Remove-Variable -Name "ADHC_ProdDir" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_ProdDir" -Value "C:\ADHC\" -Option readonly -Scope global -Description "Production root directory" -force

    # WINDOWS SCHEDULER XML
    
    $arg = 'name="' + $ADHC_User + '"'
    $x =Get-WmiObject -Class win32_useraccount -filter "$arg"
    Remove-Variable -Name "ADHC_SID" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_SID" -Value $x.SID -Option readonly -Scope global -Description "SID value for current user" -force

    Remove-Variable -Name "ADHC_Caption" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_Caption" -Value $x.Caption -Option readonly -Scope global -Description "Caption value for current user" -force

    # PYTHON (WMIC pgm)

    switch ($ADHC_Computer)
        {         
            "Ahmrdh-Netbook"{$PythonExec = "C:\Program Files\Python36-32\pythonw.exe"}
            "Holiday"       {$PythonExec = "D:\Program Files\Python38\pythonw.exe"}
       
            default         {$PythonExec = "C:\Program Files\Python38\pythonw.exe"} 
        }
    Remove-Variable -Name "ADHC_PythonExec" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_PythonExec" -Value $PythonExec -Option readonly -Scope global -Description "Path to PYTHON executable" -force

    $wmicdir = ($output + "WmicFiles\").Replace('\','\\')
    $wmicdir2 = $wmicdir.Replace("\\","/")
    $sympapgm = "C:\AdHC\WmicPgm\WMIC 3.PYW"

    $PythonArgCreate = '"' + $sympapgm + '" "--mode=Create" "--outputdir=' + $wmicdir + '"'
 
    Remove-Variable -Name "ADHC_WmicDirectory" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_WmicDirectory" -Value $wmicdir2 -Option readonly -Scope global -Description "Wmic OUTPUT directory" -force

    Remove-Variable -Name "ADHC_PythonArgCreate" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_PythonArgCreate" -Value $PythonArgCreate -Option readonly -Scope global -Description "PYTHON arguments - CREATE" -force

    $PythonArgAnalyze = '"' + $sympapgm + '" "--mode=Analyze" "--outputdir=' + $wmicdir + '"'

    Remove-Variable -Name "ADHC_WmicGenerations" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_WmicGenerations" -Value "12" -Option readonly -Scope global -Description "Number of WMIC output file generations to keep" -force
 
    Remove-Variable -Name "ADHC_PythonArgAnalyze" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_PythonArgAnalyze" -Value $PythonArgAnalyze -Option readonly -Scope global -Description "PYTHON arguments - ANALYZE" -force
    
    # Return JSON if requested

    if ($JSON.ToUpper() -eq  "YES" ) {
         $ReturnOBJ = [PSCustomObject] [ordered] @{ADHC_Computer = $ADHC_Computer;
                                                  ADHC_User = $ADHC_User;
                                                  ADHC_WmicGenerations = $ADHC_WmicGenerations
                                                  ADHC_WmicDirectory = $ADHC_WmicDirectory;
                                                  ADHC_OutputDirectory = $ADHC_OutputDirectory;
                                                  ADHC_Jobstatus = $ADHC_Jobstatus}
    
        $ReturnJSON = ConvertTo-JSON $ReturnOBJ     
        write-output $ReturnJSON 
        return 
    
    }
    else {
        return 
   
    }
}
Catch {
    Remove-Variable -Name "ADHC_InitSuccesfull" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_InitSuccessfull" -Value $false -Option readonly -Scope global -Description "INITVAR Succesfull or not" -force

    
}