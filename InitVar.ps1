# Setting of all global variables named ADHC_<something>
param (
    [string]$Mode = "MSG"    
)
# JSON   - return JSON
# MSG    - write-host messages
# SILENT - suppress messages
# OBJECT - return messages in object

# $mode = "JSON"


$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Continue"
$scripterror = $false
$mode = $mode.ToUpper()
$msglist = @()


 
try {
    $Version = " -- Version: 10.1"
    $Node = " -- Node: " + $env:COMPUTERNAME
    $d = Get-Date
    $Datum = " -- Date: " + $d.ToString("dd-MM-yyyy")
    $Tijd = " -- Time: " + $d.ToString("HH:mm:ss")
    $myname = $MyInvocation.MyCommand.Name
    $FullScriptName = $MyInvocation.MyCommand.Definition
    $mypath = $FullScriptName.Replace($MyName, "")
    $Scriptmsg = "*** STARTED *** " + $mypath + " -- PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node

    switch ($mode) {
        "MSG" {Write-Information $Scriptmsg}
        "JSON" {
            $msgentry = [PSCustomObject] [ordered] @{Message = $scriptmsg;
                                                     Level = "I"}
            $msglist += $msgentry    
        }
        "SILENT" { }
        "OBJECT" { 
            $msgentry = [PSCustomObject] [ordered] @{Message = $scriptmsg;
                                                     Level = "I"}
            $msglist += $msgentry  }
        Default  { throw "$mode is an invalid value for MODE"}    
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
                "ADHC-2"     {&subst o: "c:\Data\Sync ADHC\OneDrive" } 
                "HOLIDAY"    {&subst o: "c:\Data\Sync ADHC\OneDrive" }
                default      {&subst o: "d:\Data\Sync ADHC\OneDrive"}

            }


        }
    }
    catch {$Scriptmsg = "SUBST command has failed"
        switch ($mode) {
            "MSG" {Write-Information $Scriptmsg}
            "SILENT" { }
            Default { 
                $msgentry = [PSCustomObject] [ordered] @{Message = $scriptmsg;
                                                         Level = "W"}
                $msglist += $msgentry  
                $scripterror = $true
            }   
        }
    }
    
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
        
    $holdir = $syncdrive + "Data\Sync Gedeeld\Vakanties"
    Remove-Variable -Name "ADHC_HolidayDir" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_HolidayDir" -Value $holdir -Option readonly -Scope global -Description "Vakantie directory" -force 
    
    $isodir = "L:\Sync Films\Vakanties"
    Remove-Variable -Name "ADHC_IsoDirectory" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_IsoDirectory" -Value $isodir -Option readonly -Scope global -Description "Vakantie ISO bestanden" -force      
    
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
        
    $bootdir = "PRTG\BootTime\"
    Remove-Variable -Name "ADHC_BootDir" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_BootDir" -Value "$bootdir" -Option readonly -Scope global -Description "Last BOOT time file directory" -force

    $boot = $bootdir + $ADHC_Computer + "_BootTime.txt"
    Remove-Variable -Name "ADHC_BootTime" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_BootTime" -Value "$boot" -Option readonly -Scope global -Description "Last BOOT time file" -force

    $drive = "PRTG\DriveInfo\" + $ADHC_Computer + "_DriveInfo.txt"
    Remove-Variable -Name "ADHC_DriveInfo" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_DriveInfo" -Value "$drive" -Option readonly -Scope global -Description "Drive info file" -force

    $outp = "PRTG\OutputCheck\" + "OutputCheck.txt"
    Remove-Variable -Name "ADHC_OutputCheck" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_OutputCheck" -Value "$outp" -Option readonly -Scope global -Description "Output check info file" -force

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
    
    $btdir = "BootTimeLog\"
    $btname = $ADHC_Computer + "_BootTimeLog.txt"
    $bt = [PSCustomObject] [ordered] @{Directory = $btdir;
                                       Name = $btname }
    Remove-Variable -Name "ADHC_BootTimeLog" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_BootTimeLog" -Value $bt -Option readonly -Scope global -Description "Boot time logfile" -force

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
    
    $movdir = "MovieIsoCheck\" 
    $movname = $ADHC_Computer + "_MovieIsoCheck.txt"
    $mov = [PSCustomObject] [ordered] @{Directory = $movdir;
                                       Name = $movname }
    Remove-Variable -Name "ADHC_MovieIsoCheck" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_MovieIsoCheck" -Value $mov -Option readonly -Scope global -Description "Check ISO movie files" -force

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

    switch ($ADHC_Computer)
        {         
            
            "ADHC-2"       {$WmicDbload = "Y"}
                   
            default        {$WmicDbload = "N"}
        }
    Remove-Variable -Name "ADHC_WmicDbload" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_WmicDbload" -Value $WmicDbload -Option readonly -Scope global -Description "Execute WMIC dbload on this machine?" -force

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
    $PythonArgDbload = '"' + $sympapgm + '" "--mode=Dbload" "--outputdir=' + $wmicdir + '"'

    Remove-Variable -Name "ADHC_WmicGenerations" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_WmicGenerations" -Value "12" -Option readonly -Scope global -Description "Number of WMIC output file generations to keep" -force
 
    Remove-Variable -Name "ADHC_PythonArgAnalyze" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_PythonArgAnalyze" -Value $PythonArgAnalyze -Option readonly -Scope global -Description "PYTHON arguments - ANALYZE" -force

    Remove-Variable -Name "ADHC_PythonArgDbload" -force -ErrorAction SilentlyContinue
    Set-Variable -Name "ADHC_PythonArgDbload" -Value $PythonArgDbload -Option readonly -Scope global -Description "PYTHON arguments - DBLOAD" -force
    
    # Return JSON if requested
    $d = Get-Date
    $Datum = " -- Date: " + $d.ToString("dd-MM-yyyy")
    $Tijd = " -- Time: " + $d.ToString("HH:mm:ss")
    $myname = $MyInvocation.MyCommand.Name
    $Scriptmsg = "*** ENDED ***** " + $mypath + " -- PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node
    switch ($mode) {
        "MSG" {Write-Information $Scriptmsg}
        "SILENT" { }
        Default { 
            $msgentry = [PSCustomObject] [ordered] @{Message = $scriptmsg;
                                                     Level = "I"}
            $msglist += $msgentry  }
           
    }
    
         

}
Catch {
    
    $Scriptmsg = "INITVAR.PS1 failed - fatal error:  " + $_.Exception.Message
    
    $scripterror = $true
    switch ($mode) {
        "MSG" {Write-Information $Scriptmsg}
        "SILENT" { }
        Default { 
            $msgentry = [PSCustomObject] [ordered] @{Message = $scriptmsg;
                                                     Level = "I"}
            $msglist += $msgentry  }
           
    }
    
}
$ReturnOBJ = [PSCustomObject] [ordered] @{AbEnd = $scripterror;
                                                  MessageList = $msglist;
                                                  ADHC_Computer = $ADHC_Computer;
                                                  ADHC_User = $ADHC_User;
                                                  ADHC_WmicGenerations = $ADHC_WmicGenerations
                                                  ADHC_WmicDirectory = $ADHC_WmicDirectory;
                                                  ADHC_WmicDbload = $ADHC_WmicDbload;
                                                  ADHC_OutputDirectory = $ADHC_OutputDirectory;
                                                  ADHC_WmicTempdir = $ADHC_WmicTempdir;
                                                  ADHC_Jobstatus = $ADHC_Jobstatus;
                                                  ADHC_CopyMoveScript = $ADHC_CopyMoveScript;
                                                  ADHC_LockScript = $ADHC_LockScript;}

switch ($mode) {
        
    "JSON" {
        $ReturnJSON = ConvertTo-JSON $ReturnOBJ 
        return $ReturnJSON 
    }
    Default { 
        return $Returnobj
    }
       
}