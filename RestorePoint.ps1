$ScriptVersion = " -- Version: 1.2"
# COMMON coding
CLS
$StatusOBJ = [PSCustomObject] [ordered] @{Scripterror = $false;
                                          ScriptChange = $false;
                                          ScriptAction = $false;
                                          }
$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"
$myhost = $ADHC_Computer.ToUpper()

function Report ([string]$level, [string]$line, [object]$Obj, [string]$file ) {
    switch ($level) {
        ("N") {$rptline = $line}
        ("H") {
            $rptline = "-------->".Padright(10," ") + $line
        }
        ("I") {
            $rptline = "Info    *".Padright(10," ") + $line
        }
        ("A") {
            $rptline = "Caution *".Padright(10," ") + $line
        }
        ("B") {
            $rptline = "        *".Padright(10," ") + $line
        }
        ("C") {
            $rptline = "Change  *".Padright(10," ") + $line
            $obj.scriptchange = $true
        }
        ("W") {
            $rptline = "Warning *".Padright(10," ") + $line
            $obj.scriptaction = $true
        }
        ("E") {
            $rptline = "Error   *".Padright(10," ") + $line
            $obj.scripterror = $true
        }
        ("G") {
            $rptline = "GIT:    *".Padright(10," ") + $line
        }
        default {
            $rptline = "Error   *".Padright(10," ") + "Messagelevel $level is not valid"
            $Obj.Scripterror = $true
        }
    }
    Add-Content $file $rptline

}

function Running-Elevated
{
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object System.Security.Principal.WindowsPrincipal($id)

    if ($p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) { 
        $adm = $true 
    }      
    else { 
        $adm = $false 
    }
    $MyAuth = [PSCustomObject] [ordered] @{ID = $id;
                                           Principal = $p; 
                                           Administrator = $adm}
    return $MyAuth 
 } 


try {
    $Node = " -- Node: " + $env:COMPUTERNAME
    $d = Get-Date
    $Datum = " -- Date: " + $d.ToString("dd-MM-yyyy")
    $Tijd = " -- Time: " + $d.ToString("HH:mm:ss")

    $myname = $MyInvocation.MyCommand.Name
    $FullScriptName = $MyInvocation.MyCommand.Definition
    $mypath = $FullScriptName.Replace($MyName, "")

    $Scriptmsg = "*** STARTED *** " + $mypath + " -- PowerShell script " + $MyName + $ScriptVersion + $Datum + $Tijd +$Node
    Write-Information $Scriptmsg 

    $LocalInitVar = $mypath + "InitVar.PS1"
    $InitObj = & "$LocalInitVar" "OBJECT"

    if ($Initobj.AbEnd) {
        # Write-Warning "YES"
        throw "INIT script $LocalInitVar Failed"

    }

       
# END OF COMMON CODING  

    # Init reporting file
    
    $dir = $ADHC_TempDirectory + $ADHC_RestorePoint.Directory
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $Tempfile = $dir + $ADHC_RestorePoint.Name
    Set-Content $Tempfile $Scriptmsg -force

    foreach ($entry in $InitObj.MessageList){
        Report $entry.Level $entry.Message $StatusObj $Tempfile
    } 

    $el = Running-Elevated

    $u = $el.id.Name
    $ia = $el.Principal.Identity.IsAuthenticated
    
    if (-not($el.Administrator)) {
        $record =  "*** Script NOT running as administrator (Current user is $u (IsAuthenticated = $ia))"
        Report "E" $record $StatusObj $Tempfile         
    }
    else {
        $record =  "*** Script running as administrator (Current user is $u (IsAuthenticated = $ia))"
        Report "I" $record $StatusObj $Tempfile 
    } 

    
    if (!$StatusObj.scripterror) {
        # Get restart point info (must be run with admin rights

        $record =  "Get list of Restore Points"
        Report "I" $record $StatusObj $Tempfile 

        $crp = Get-ComputerRestorePoint

        # Out-GridView -InputObject $a

         # Init PRTG info file if not existent
        $timestamp = Get-Date 
        $str = $ADHC_RestorePointInfo.Split("\")
        $dir = $ADHC_OutputDirectory + $str[0] + "\" + $str[1]
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        $RestorePointInfoFile = $ADHC_OutputDirectory + $ADHC_RestorePointInfo.Replace($ADHC_Computer, $myHost)
        $dr = Test-Path $RestorePointInfoFile
        if (!$dr) { 
            $r = $timestamp.ToString("dd-MM-yyyy hh:mm:ss") + "|nodescription|noeventtype|0"       
            Set-Content $RestorePointInfoFile $r -force
       
        }

        # Update info file (will be read by prtg sensor)

        $cnt = $crp.Count

        if (!$cnt) {
            $lastentry = $crp
            $RP_count = 0
            $realtime = [System.Management.ManagementDateTimeConverter]::ToDateTime($lastentry.CreationTime)             
    
            $r = $realtime.ToString("dd-MM-yyyy hh:mm:ss") + "|" + $lastentry.Description + "|" + $lastentry.EventType + "|" + $RP_count 
            Set-Content $RestorePointInfoFile $r -force
        }
        else {
            $RP_count = $cnt

            if ($RP_count -eq 0) {
                
                $r = "01-01-2000 00:00:00" + "|NotFound|NotFound|" + $RP_count 
                Set-Content $RestorePointInfoFile $r -force
            } 
            else {

                $lastentry = $crp[$cnt-1] 
        
                $realtime = [System.Management.ManagementDateTimeConverter]::ToDateTime($lastentry.CreationTime)             
    
                $r = $realtime.ToString("dd-MM-yyyy hh:mm:ss") + "|" + $lastentry.Description + "|" + $lastentry.EventType + "|" + $RP_count 
                Set-Content $RestorePointInfoFile $r -force
            }
        }
    }

}

catch {
    $StatusObj.scripterror = $true
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    $Dump = $_.Exception.ToString()
}
finally {
    # Init jobstatus file
    $dir = $ADHC_OutputDirectory + $ADHC_Jobstatus
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $p = $myname.Split(".")
    $process = $p[0]
    $jobstatus = $ADHC_OutputDirectory + $ADHC_Jobstatus + $ADHC_Computer + "_" + $Process + ".jst" 
    
    Report "N"  " " $StatusObj $Tempfile
    $returncode = 99
        
    if (($StatusObj.scripterror) -and ($returncode -eq 99)) {
        $msg = ">>> Script ended abnormally"
        Report "N"  $msg $StatusObj $Tempfile
        Report "N"  " " $StatusObj $Tempfile
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "9" + "|" + $ScriptVersion + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        Add-Content $jobstatus "Failed item = $FailedItem"
        Add-Content $jobstatus "Errormessage = $ErrorMessage"
        Add-Content $jobstatus "Dump info = $dump"

        Report "E" "Failed item = $FailedItem" $StatusObj $Tempfile
        Report "E" "Errormessage = $ErrorMessage" $StatusObj $Tempfile
        Report "E" "Dump info = $dump" $StatusObj $Tempfile
        $returncode =  16        
    }
   
    if (($StatusObj.scriptaction) -and ($returncode -eq 99)) {
        $msg = ">>> Script ended normally with action required"
        Report "W"  $msg $StatusObj $Tempfile
        Report "N"  " " $StatusObj $Tempfile
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "6" + "|" + $ScriptVersion + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode =  8
    }

    if (($StatusObj.scriptchange) -and ($returncode -eq 99)) {
        $msg = ">>> Script ended normally with reported changes, but no action required"
        Report "C"  $msg $StatusObj $Tempfile
        Report "N"  " " $StatusObj $Tempfile
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "3" + "|" + $ScriptVersion + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode =  4
    }

    if ($returncode -eq 99) {

        $msg = ">>> Script ended normally without reported changes, and no action required"
        Report "I"  $msg $StatusObj $Tempfile
        Report "N"  " " $StatusObj $Tempfile
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "0" + "|" + $ScriptVersion + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode = 0
    }

    try { # Free resource and copy temp file        
        
        $deffile = $ADHC_OutputDirectory + $ADHC_RestorePoint.Directory + $ADHC_RestorePoint.Name 
        $CopMov = & $ADHC_CopyMoveScript $TempFile $deffile "MOVE" "REPLACE" $TempFile 
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        $Dump = $_.Exception.ToSTring()
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "9" + "|" + $ScriptVersion + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
        Add-Content $jobstatus "Failed item = $FailedItem"
        Add-Content $jobstatus "Errormessage = $ErrorMessage"
        Add-Content $jobstatus "Dump info = $Dump"
        $Returncode = 16       

    }
    Finally {
        $d = Get-Date
        $Datum = " -- Date: " + $d.ToString("dd-MM-yyyy")
        $Tijd = " -- Time: " + $d.ToString("HH:mm:ss") 
        $Scriptmsg = "*** ENDED ***** " + $mypath + " -- PowerShell script " + $MyName + $ScriptVersion + $Datum + $Tijd +$Node
        Report "N" $scriptmsg $StatusObj $deffile
        Report "N" " " $StatusObj $deffile
        Write-Host $scriptmsg
        Exit $Returncode
        
    }  
   

} 
