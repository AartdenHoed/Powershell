# Setting of all global variables named ADHC_<something>
param (
    [string]$JSON = "NO"    
)
# $JSON = 'YES'


$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"

class InitVarException : System.Exception  { 
    InitVarException( [string]$message) : base($message) {

    }

    InitVarException() {

    }
}

Remove-Variable -Name "ADHC_InitSuccesfull" -force -ErrorAction SilentlyContinue
Set-Variable -Name "ADHC_InitSuccessfull" -Value $true -Option readonly -Scope global -Description "INITVAR Succesfull or not" -force
 
try {
    $Version = " -- Version: 7.2"
    $Node = " -- Node: " + $env:COMPUTERNAME
    $d = Get-Date
    $Datum = " -- Date: " + $d.ToString("dd-MM-yyyy")
    $Tijd = " -- Time: " + $d.ToString("HH:mm:ss")
    $myname = $MyInvocation.MyCommand.Name
    $FullScriptName = $MyInvocation.MyCommand.Definition
    $mypath = $FullScriptName.Replace($MyName, "")
    $Scriptmsg = "*** STARTED *** " + $mypath + " -- PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node
    if (($JSON.ToUpper() -ne "YES") -and ($JSON.ToUpper() -ne "SILENT")) {
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

    $Hostlist = "ADHC","Hoesto","Holiday" 
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

    $OneDrive = "D:\ADHC_Home\OneDrive\"
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

    Remove-Variable -Name "ADHC_PsPath" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_PsPath" -Value "$mypath" -Option readonly -Scope global -Description "Name of powershell path" -force

    $cm = $mypath + "CopyMove.ps1"
    Remove-Variable -Name "ADHC_CopyMoveScript" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_CopyMOveScript" -Value "$cm" -Option readonly -Scope global -Description "Name of Copy/Move script" -force
    
    $ls = $mypath + "Globallock.ps1"
    Remove-Variable -Name "ADHC_LockScript" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_LockScript" -Value "$ls" -Option readonly -Scope global -Description "Name of Global Lock script" -force
    
    $ni = $mypath + "IpNodeInfo.ps1"
    Remove-Variable -Name "ADHC_NodeInfoScript" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_NodeInfoScript" -Value "$ni" -Option readonly -Scope global -Description "Name of IpNodeInfok script" -force

    # OUTPUT FILES
    $temp = "D:\ADHC_Home\ADHC_Temp\"
    Remove-Variable -Name "ADHC_TempDirectory" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_TempDirectory" -Value $temp -Option readonly -Scope global -Description "Common root directory for temp files" -force
    
    $output = $ADHC_OneDrive + "ADHC Output\"
    Remove-Variable -Name "ADHC_OutputDirectory" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_OutputDirectory" -Value $output -Option readonly -Scope global -Description "Common root directory for output files" -force
    
    $boot = "PRTG\BootTime\" + $ADHC_Computer + "_BootTime.txt"
    Remove-Variable -Name "ADHC_BootTime" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_BootTime" -Value "$boot" -Option readonly -Scope global -Description "Last BOOT time file" -force

    $drive = "PRTG\DriveInfo\" + $ADHC_Computer + "_DriveInfo.txt"
    Remove-Variable -Name "ADHC_DriveInfo" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_DriveInfo" -Value "$drive" -Option readonly -Scope global -Description "Drive info file" -force
    
    $ngdir = "DeployCheck\"
    $ngname = $ADHC_Computer + "_DeployCheck.txt"
    $ng = [PSCustomObject] [ordered] @{Directory = $ngdir;
                                       Name = $ngname }
    Remove-Variable -Name "ADHC_DeployCheck" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_DeployCheck" -Value $ng -Option readonly -Scope global -Description "Check correctness deployments" -force
    
    $cfdir = "OneDriveCheck\" 
    $cfname = $ADHC_Computer + "_OneDriveCheck.txt"
    $cf = [PSCustomObject] [ordered] @{Directory = $cfdir;
                                       Name = $cfname }
    Remove-Variable -Name "ADHC_OneDriveCheck" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_OneDriveCheck" -Value $cf -Option readonly -Scope global -Description "Conflict report file attributes" -force

    $sodir = "OneDriveSync\" 
    $soname = $ADHC_Computer + "_OneDriveSync.txt"
    $so = [PSCustomObject] [ordered] @{Directory = $sodir;
                                       Name = $soname }
    Remove-Variable -Name "ADHC_OneDriveSync" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_OneDriveSync" -Value $so -Option readonly -Scope global -Description "Force OneDrive synchronisation" -force

    $encoder = new-object System.Text.UTF8Encoding
    $regx = Get-ItemProperty -path HKLM:\SOFTWARE\ADHC | Select-Object -ExpandProperty "SecurityString"
    # Write-Host "String = $regx"
    $bytes = $encoder.Getbytes($regx)
    $secfile = $output + "PRTG\Security\SaveString.txt"
    $sec = Get-Content $secfile
    $SecureString = ConvertTo-SecureString $sec -Key $bytes
    $Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList "ADHCode", $Securestring 
    Remove-Variable -Name "ADHC_Credentials" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_Credentials" -Value $Credentials -Option readonly -Scope global -Description "Credentials" -force

    $dldir = "DeployExec\" 
    $dlname =  "#Overall_Deploy.log"
    $dl = [PSCustomObject] [ordered] @{Directory = $dldir;
                                       Name = $dlname }
    Remove-Variable -Name "ADHC_DeployLog" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_DeployLog" -Value $dl -Option readonly -Scope global -Description "Deployment log file" -force

    $dtdir = "DeployExec\" 
    $dtname = $ADHC_Computer + "_DeployReport.txt"
    $dt = [PSCustomObject] [ordered] @{Directory = $dtdir;
                                       Name = $dtname }
    Remove-Variable -Name "ADHC_DeployExec" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_DeployExec" -Value $dt -Option readonly -Scope global -Description "Deployment report file" -force

    $gpadir = "GitPushAll\" 
    $gpaname = $ADHC_Computer + "_GitPushAll.txt"
    $gpa = [PSCustomObject] [ordered] @{Directory = $gpadir;
                                       Name = $gpaname }
    Remove-Variable -Name "ADHC_GitPushAll" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_GitPushAll" -Value $gpa -Option readonly -Scope global -Description "GIT 'Push All' execution" -force

    $pudir = "GitPushAll\" 
    $puname = "#Overall_Push.log"
    $pu = [PSCustomObject] [ordered] @{Directory = $pudir;
                                       Name = $puname }
    Remove-Variable -Name "ADHC_GitPushLog" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_GitPushLog" -Value $pu -Option readonly -Scope global -Description "Push log file" -force
    
    $lock = $output + "GlobalLock\"
    Remove-Variable -Name "ADHC_LockDir" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_LockDir" -Value $lock -Option readonly -Scope global -Description "Directory for Global Locks" -force
    
    $gsdir = "GitCheck\" 
    $gsname = $ADHC_Computer + "_GitCheck.txt"
    $gs = [PSCustomObject] [ordered] @{Directory = $gsdir;
                                       Name = $gsname }
    Remove-Variable -Name "ADHC_GitCheck" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_GitCheck" -Value $gs -Option readonly -Scope global -Description "Status of GIT directories" -force
    
    Remove-Variable -Name "ADHC_JobStatus" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_Jobstatus" -Value "PRTG\JobStatus\" -Option readonly -Scope global -Description "Jobs status directory" -force
    
    Remove-Variable -Name "ADHC_PRTGlogs" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_PRTGlogs" -Value "PRTG\SensorLogs\" -Option readonly -Scope global -Description "PRTG log directory" -force

    $prtgdir = "PRTGoverviewDB\"
    $prtgname = $ADHC_Computer + "_PRTGoverviewDB.txt"
    $prtg = [PSCustomObject] [ordered] @{Directory = $prtgdir;
                                       Name = $prtgname }
    Remove-Variable -Name "ADHC_PRTGoverviewDB" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_PRTGoverviewDB" -Value $prtg -Option readonly -Scope global -Description "Put PRTG overview in database" -force

    $vxdir = "VariableXref\"
    $vxname = $ADHC_Computer + "_VariableXref.txt"
    $vx = [PSCustomObject] [ordered] @{Directory = $vxdir;
                                       Name = $vxname }
    Remove-Variable -Name "ADHC_VariableXref" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_VariableXref" -Value $vx -Option readonly -Scope global -Description "XREF between sources and variables" -force

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

    $xmldate = Get-Date
    $xmlymd = $xmldate.ToString("yyyy-MM-dd")
    $xmlhms = $xmldate.ToString("HH:mm:ss")
    $xmlstr = $xmlymd + "T" + $xmlhms + ".0000000" 
    Remove-Variable -Name "ADHC_XmlTimestamp" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_XmlTimestamp" -Value $xmlstr -Option readonly -Scope global -Description "Creation timestamp XML" -force

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
    $wmictemp = ($temp + "WmicFiles\").Replace('\','\\')
    $wmictemp2 = $wmictemp.Replace("\\","/")
    $sympapgm = "C:\AdHC\WmicPgm\WMIC 3.PYW"

    $PythonArgCreate = '"' + $sympapgm + '" "--mode=Create" "--outputdir=' + $wmicdir + '"'
 
    Remove-Variable -Name "ADHC_WmicDirectory" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_WmicDirectory" -Value $wmicdir2 -Option readonly -Scope global -Description "Wmic OUTPUT directory" -force

    Remove-Variable -Name "ADHC_WmicTempdir" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_WmicTempdir" -Value $wmictemp2 -Option readonly -Scope global -Description "Wmic TEMP OUTPUT directory" -force

    Remove-Variable -Name "ADHC_PythonArgCreate" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_PythonArgCreate" -Value $PythonArgCreate -Option readonly -Scope global -Description "PYTHON arguments - CREATE" -force

    $PythonArgAnalyze = '"' + $sympapgm + '" "--mode=Analyze" "--outputdir=' + $wmicdir + '"'

    Remove-Variable -Name "ADHC_WmicGenerations" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_WmicGenerations" -Value "12" -Option readonly -Scope global -Description "Number of WMIC output file generations to keep" -force
 
    Remove-Variable -Name "ADHC_PythonArgAnalyze" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_PythonArgAnalyze" -Value $PythonArgAnalyze -Option readonly -Scope global -Description "PYTHON arguments - ANALYZE" -force
    
    # Return JSON if requested
    $d = Get-Date
    $Datum = " -- Date: " + $d.ToString("dd-MM-yyyy")
    $Tijd = " -- Time: " + $d.ToString("HH:mm:ss")
    $myname = $MyInvocation.MyCommand.Name
    $Scriptmsg = "*** ENDED ***** " + $mypath + " -- PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node
    if (($JSON.ToUpper() -ne "YES") -and ($JSON.ToUpper() -ne "SILENT")) {
        Write-Information $Scriptmsg 
    }

    if ($JSON.ToUpper() -eq  "YES" ) {
         $ReturnOBJ = [PSCustomObject] [ordered] @{ADHC_Computer = $ADHC_Computer;
                                                  ADHC_User = $ADHC_User;
                                                  ADHC_WmicGenerations = $ADHC_WmicGenerations
                                                  ADHC_WmicDirectory = $ADHC_WmicDirectory;
                                                  ADHC_OutputDirectory = $ADHC_OutputDirectory;
                                                  ADHC_WmicTempdir = $ADHC_WmicTempdir;
                                                  ADHC_Jobstatus = $ADHC_Jobstatus;
                                                  ADHC_CopyMoveScript = $ADHC_CopyMoveScript;
                                                  ADHC_LockScript = $ADHC_LockScript}
    
        $ReturnJSON = ConvertTo-JSON $ReturnOBJ 
        return $ReturnJSON
    
    }
    else {
        return 
   
    }
}
Catch {
    Remove-Variable -Name "ADHC_InitSuccesfull" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_InitSuccessfull" -Value $false -Option readonly -Scope global -Description "INITVAR Succesfull or not" -force
    $em = "INITVAR.PS1 failed - fatal error:  " + $_.Exception.Message
    $MyError = [InitVarException]::new($em)
    Remove-Variable -Name "ADHC_InitError" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_InitError" -Value $MyError -Option readonly -Scope global -Description "INITVAR user error" -force
    
}