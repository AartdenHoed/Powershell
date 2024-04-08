CLS
$Version = " -- Version: 1.2"

$StatusOBJ = [PSCustomObject] [ordered] @{Scripterror = $false;
                                          ScriptChange = $false;
                                          ScriptAction = $false;
                                          }

$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Continue"

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


try {
    $Node = " -- Node: " + $env:COMPUTERNAME
    $d = Get-Date
    $Datum = " -- Date: " + $d.ToString("dd-MM-yyyy")
    $Tijd = " -- Time: " + $d.ToString("HH:mm:ss")

    $myname = $MyInvocation.MyCommand.Name
    $enqprocess = $myname.ToUpper().Replace(".PS1","")
    $FullScriptName = $MyInvocation.MyCommand.Definition
    $mypath = $FullScriptName.Replace($MyName, "")

    $Scriptmsg = "*** STARTED *** " + $mypath + " -- PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node
    Write-Information $Scriptmsg 

    $LocalInitVar = $mypath + "InitVar.PS1"
    $InitObj = & "$LocalInitVar" "OBJECT"

    if ($Initobj.AbEnd) {
        # Write-Warning "YES"
        throw "INIT script $LocalInitVar Failed" 

    }
    # Init reporting file
    $dir = $ADHC_TempDirectory + $ADHC_DatabaseBackup.Directory
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $tempfile = $dir + $ADHC_DatabaseBackup.Name

    Set-Content $Tempfile $Scriptmsg -force

    foreach ($entry in $InitObj.MessageList){
        Report $entry.Level $entry.Message $StatusObj $Tempfile
    }
    
    # END OF COMMON CODING   

   
    $query = "SELECT name, database_id, create_date FROM sys.databases"

    $dbs = invoke-sqlcmd -ServerInstance '.\sqlexpress' -Database "Master" -Query "$query" -ErrorAction Stop

    foreach ($db in $dbs) {
        $dbname = $db.name 
        switch ($dbname) {
            "tempdb" {
                Report "I" "TempDb skipped for backup" $StatusObj $Tempfile
            };
            default { 
                Backup-SqlDatabase -ServerInstance '.\sqlexpress' -Database "$dbname" -Initialize -Checksum | Out-Null  
                Report "I" "SQL backup for $dbname completed"  $StatusObj $Tempfile
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
    
    Report "N" " " $StatusObj $Tempfile

    $returncode = 99

    if ($ENQfailed) {
        $msg = ">>> Script could not run"
        Report "E" $msg $StatusObj $Tempfile
        Report "N" " " $StatusObj $Tempfile
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "7" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        Add-Content $jobstatus "Failed item = $FailedItem"
        Add-Content $jobstatus "Errormessage = $ErrorMessage"
        Add-Content $jobstatus "Dump info = $dump"

        Report "E" "Failed item = $FailedItem" $StatusObj $Tempfile
        Report "E" "Errormessage = $ErrorMessage" $StatusObj $Tempfile
        Report "E" "Dump info = $dump" $StatusObj $Tempfile
        $returncode = 12       

    }
        
    if (($StatusObj.scripterror) -and ($returncode -eq 99)) {
        Report "E" ">>> Script ended abnormally" $StatusObj $Tempfile
        Report "N" " " $StatusObj $Tempfile
        
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "9" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        Add-Content $jobstatus "Failed item = $FailedItem"
        Add-Content $jobstatus "Errormessage = $ErrorMessage"
        Add-Content $jobstatus "Dump info = $dump"

        Report "E" "Failed item = $FailedItem" $StatusObj $Tempfile
        Report "E" "Errormessage = $ErrorMessage" $StatusObj $Tempfile
        Report "E" "Dump info = $dump" $StatusObj $Tempfile
        $returncode = 16        
    }
   
    if (($StatusObj.scriptaction) -and ($returncode -eq 99)) {
        Report "W" ">>> Script ended normally with action required" $StatusObj $Tempfile
        Report "N" " " $StatusObj $Tempfile
        
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "6" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode = 8
    }

    if (($StatusObj.scriptchange) -and ($returncode -eq 99)) {
        Report "C" ">>> Script ended normally with reported changes, but no action required" $StatusObj $Tempfile
        Report "N" " " $StatusObj $Tempfile
        
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "3" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode = 4
    }

    if ($returncode -eq 99) {
        Report "I" ">>> Script ended normally without reported changes, and no action required" $StatusObj $Tempfile
        Report "N" " " $StatusObj $Tempfile
   
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "0" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode = 0
    }
    
    try { # Free resource and copy temp file
        
        $deffile = $ADHC_OutputDirectory + $ADHC_DatabaseBackup.Directory + $ADHC_DatabaseBackup.Name 
        $CopMov = & $ADHC_CopyMoveScript $TempFile $deffile "MOVE" "REPLACE" $TempFile 
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        $Dump = $_.Exception.ToSTring()
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "9" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
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
        $Scriptmsg = "*** ENDED ***** " + $mypath + " -- PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node
        Report "N" $scriptmsg $StatusObj $deffile
        Report "N" " " $StatusObj $deffile 
        Write-Host $scriptmsg
        Exit $Returncode
        
    }  
   

}