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
    $Version = " -- Version: 9.4"
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

    $Hostlist = "Hoesto","Holiday","ADHC-2" 
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
    try {
        If (!(Test-Path O:)) {
            &subst o: /d
            switch ($ADHC_Computer)
            {         
                "HOESTO"     {&subst o: "d:\Data\Sync ADHC\OneDrive" } 
                "ADHC-2"     {&subst o: "c:\Data\Sync ADHC\OneDrive" } 
                default      {}

            }


        }
    }
    catch {Write-Warning "Subst fails"}
    
    $prof = $env:USERPROFILE -split '\\'

    switch ($ADHC_Computer)
        {         
            "xxxx"     {$OneDrive = "O:\"}
            default    {$OneDrive = "O:\"}

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

    $usr = "C:\ADHC_User\Documents\"
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
    switch ($ADHC_Computer)
        {         
            "ADHC-2"          {$syncdrive = "C:\"}
            default           {$syncdrive = "D:\"}

        }
    $outlookinput = $syncdrive + "Data\Sync Gedeeld\Agenda & Mail\Outlook back-up\OUTLOOK.CSV"
    Remove-Variable -Name "ADHC_OutlookInput" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_OutlookInput" -Value $outlookinput -Option readonly -Scope global -Description "Input CSV with iCloud contacts" -force

    $thisdate = Get-Date -Format "yyyyMMdd"
    $outlookoutput = $syncdrive + "Data\Sync Gedeeld\Agenda & Mail\Outlook back-up\Upload XML " + $thisdate + ".xml"
    Remove-Variable -Name "ADHC_Outlookoutput" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_Outlookoutput" -Value $outlookoutput -Option readonly -Scope global -Description "output XML with contacts for Fritz!Box" -force
        
    switch ($ADHC_Computer)
        {         
            "ADHC-2"          {$temp = "C:\ADHC_Home\ADHC_Temp\"}
            default           {$temp = "D:\ADHC_Home\ADHC_Temp\"}

        }
    
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

    $vpn = "PRTG\VpnInfo\" + $ADHC_Computer + "_VpnInfo.txt"
    Remove-Variable -Name "ADHC_VpnInfo" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_VpnInfo" -Value "$vpn" -Option readonly -Scope global -Description "VPN info file" -force

    $cput = "PRTG\CpuTemperature\" + $ADHC_Computer + "_CpuTemperature.txt"
    Remove-Variable -Name "ADHC_CpuTempInfo" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_CpuTempInfo" -Value "$cput" -Option readonly -Scope global -Description "CPU temperature info file" -force
    
    $lcdir = "LocalCpuTemperature\"
    $lcname = $ADHC_Computer + "_LocalCpuTemperature.txt"
    $lc = [PSCustomObject] [ordered] @{Directory = $lcdir;
                                       Name = $lcname }
    Remove-Variable -Name "ADHC_LocalCpuTemperature" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_LocalCpuTemperature" -Value $lc -Option readonly -Scope global -Description "Local CPU temperature" -force

    $ngdir = "DeployCheck\"
    $ngname = $ADHC_Computer + "_DeployCheck.txt"
    $ng = [PSCustomObject] [ordered] @{Directory = $ngdir;
                                       Name = $ngname }
    Remove-Variable -Name "ADHC_DeployCheck" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_DeployCheck" -Value $ng -Option readonly -Scope global -Description "Check correctness deployments" -force

    $ipcdir = "IpScan\"
    $ipcname = $ADHC_Computer + "_IpScan.txt"
    $ipc = [PSCustomObject] [ordered] @{Directory = $ipcdir;
                                       Name = $ipcname }
    Remove-Variable -Name "ADHC_IpScan" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_IpScan" -Value $ipc -Option readonly -Scope global -Description "Scan of home IP addresses" -force
    
    $ipcldir = "IpScan\"
    $ipclname = $ADHC_Computer + "_IpScan.log"
    $ipcl = [PSCustomObject] [ordered] @{Directory = $ipcldir;
                                       Name = $ipclname }
    Remove-Variable -Name "ADHC_IpScanLog" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_IpScanLog" -Value $ipcl -Option readonly -Scope global -Description "Scan of home IP addresses" -force
    
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

    $prtcdir = "PRTGoverviewDB\"
    $prtcname = $ADHC_Computer + "_PrtgDbCheck.txt"
    $prtc = [PSCustomObject] [ordered] @{Directory = $prtcdir;
                                       Name = $prtcname }
    Remove-Variable -Name "ADHC_PrtgDbCheck" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_PrtgDbCheck" -Value $prtc -Option readonly -Scope global -Description "Put PRTG overview in database" -force

    $sqlbdir = "DatabaseBackup\"
    $sqlbname = $ADHC_Computer + "_DatabaseBackup.txt"
    $sqlb = [PSCustomObject] [ordered] @{Directory = $sqlbdir;
                                       Name = $sqlbname }
    Remove-Variable -Name "ADHC_DatabaseBackup" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_DatabaseBackup" -Value $sqlb -Option readonly -Scope global -Description "SQL database backup" -force

    $sxdir = "SourceXref\"
    $sxname = $ADHC_Computer + "_SourceXref.txt"
    $sx = [PSCustomObject] [ordered] @{Directory = $sxdir;
                                       Name = $sxname }
    Remove-Variable -Name "ADHC_SourceXref" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_SourceXref" -Value $sx -Option readonly -Scope global -Description "XREF between sources" -force

    $cldir = "CmdletXref\"
    $clname = $ADHC_Computer + "_CmdletXref.txt"
    $cl = [PSCustomObject] [ordered] @{Directory = $cldir;
                                       Name = $clname }
    Remove-Variable -Name "ADHC_CmdletXref" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_CmdletXref" -Value $cl -Option readonly -Scope global -Description "XREF between cmdlets and sources" -force

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
    Set-Variable -Name "ADHC_MasterXml" -Value $master -Option readonly -Scope global -Description "Path to ADHC master XML" -force

    # DSL directory 
     switch ($ADHC_Computer)
        {         
            "ADHC-2"          {$dsl = "O:\DSL\"}
            default           {$dsl = "O:\DSL\"}

        }  

    Remove-Variable -Name "ADHC_DSLDir" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_DSLDir" -Value $dsl -Option readonly -Scope global -Description "DSL root directory" -force

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
            
            "Holiday"       {$PythonExec = "D:\Program Files\Python\pythonw.exe"}
                   
            default         {$PythonExec = "C:\Program Files\Python\pythonw.exe"} 
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