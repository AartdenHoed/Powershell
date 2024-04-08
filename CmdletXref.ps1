$Version = " -- Version: 1.1"

# COMMON coding
CLS

$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Continue"

$StatusOBJ = [PSCustomObject] [ordered] @{Scripterror = $false;
                                          ScriptChange = $false;
                                          ScriptAction = $false;
                                          }

function Report ([string]$level, [string]$line, [object]$Obj, [string]$file ) {
    switch ($level) {
        ("N") {$rptline = $line}
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
      

# END OF COMMON CODING   

    # Init reporting file
    
    $dir = $ADHC_TempDirectory + $ADHC_CmdletXref.Directory
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $Tempfile = $dir + $ADHC_CmdletXref.NAme
    Set-Content $Tempfile $Scriptmsg -force

    foreach ($entry in $InitObj.MessageList){
        Report $entry.Level $entry.Message $StatusObj $Tempfile
    }

    $Cmdletlist = Get-Command | Where-Object {$_.Name -like "*-*"} 
    $Cmdletcount = $Cmdletlist.Count

    $filelist = Get-ChildItem $ADHC_Stagingdir -Recurse -File | Select-Object Name,Fullname,Extension
    $Totaal = $fileList.count
    $n = 0
    $percentiel = [math]::floor($totaal / 10)
    $part = $percentiel

    $FileCount = 0
    $Skipped = 0
    $Scanned = 0

    $Resultlist = @()

    $ToMatch = @(".PS1")

    foreach ($sourcefile in $filelist) {
    
        Write-host $sourcefile.FullName
    
        $Filecount = $Filecount + 1
    
        $n = $n + 1;

        if ($n -eq $part) {
            $percentage = [math]::round($n * 100 / $totaal)
            Write-host "Processing $n van $totaal ($percentage %)"
            $part = $part + $percentiel
        }  
        
        if (!($ToMatch -contains $sourcefile.Extension.ToUpper())) {
            $Skipped += 1
            continue
        }
        else {
            $scanned += 1
        }       
               
        $lines = (Get-Content $sourcefile.FullName) 
    
                 
        foreach ($cmdlet in $Cmdletlist) {
            $nrofhits = 0  
            $ctype = $cmdlet.CommandType
            foreach ($line in $lines) {
                $matchme = $cmdlet.Name.ToUpper().Replace("\","\\")
                if ($line.ToUpper() -match $matchme) {
                    $nrofhits = $nrofhits + 1                
                }
            
            }
            if ($nrofhits -gt 0 ) {
                $fname = $sourcefile.FullName
                
                # Write-Host "$matchme found in $fname"
                $TargetObject = [PSCustomObject] [ordered]  @{Sourcefile = $fname; Searchstring = $matchme ; NrofHits = $nrofhits ; CMDtype = $ctype}  
                                                                          
                $Resultlist += $TargetObject
            }
        }        
    }
    
    Report "N"  " " $StatusObj $Tempfile
    Report "I"   "In scope were $FileCount files (of which $Scanned scanned and $skipped skipped) with $cmdletcount search strings" $StatusObj $Tempfile

    $Sorted = $Resultlist | Sort-Object -Property Searchstring,SourceFile  

    $curname = "@#$"
    Report "N"  " " $StatusObj $Tempfile
    $rptline = " === Cross reference between PowerShell cmdlets and sources in $ADHC_Stagingdir === "
    Report "N"  $rptline $StatusObj $Tempfile

    foreach ($hit in $Sorted) {
        $cmdname = $hit.Searchstring
        if ($cmdname -ne $curname) {
            Report "N"  " " $StatusObj $Tempfile
            $rptline = $cmdname.Padright(32," ") + "hits = " + $hit.nrofhits.ToString().Padright(8," ") +  $hit.Sourcefile.PadRight(100," ") + "Command Type = '"+ $hit.CMDtype + "'"
            Report "N"  $rptline $StatusObj $Tempfile
            $curname = $cmdname
        }
        else {
            $rptline = " ".Padright(32," ") + "hits = " + $hit.nrofhits.ToString().Padright(8," ") +  $hit.Sourcefile.PadRight(100," ") 
            Report "N"  $rptline $StatusObj $Tempfile
        }
     

    } 

    # report Cmdlets that are not being used
    Report "N"  " " $StatusObj $Tempfile
    $rptline = " === Powershell cmdlets that are not being referenced in any source in $ADHC_Stagingdir === "
    Report "N"  $rptline $StatusObj $Tempfile

    $written = $false

    foreach ($cmdlet in $Cmdletlist) {
        $cmdname = $cmdlet.Name.ToUpper()

        $foundit = $false
        foreach ($s in $sorted) {
            if ($cmdname-eq $s.Searchstring) {
                $foundit = $true
            }
        }
        if (!$foundit) {
            $rptline = " >>> $cmdname"
            Report "N"  $rptline $StatusObj $Tempfile
            # write-warning "$cmdname not referenced in any source"
            $written = $true
        }
    
    
    }
    if (!$written) { 
        $rptline = " >>> N O N E"
        Report "N"  $rptline $StatusObj $Tempfile
    } 
    else {
        # nothing
    }

}
catch {
    $StatusObj.Scripterror = $true
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
        
    if (($StatusObj.Scripterror) -and ($returncode -eq 99)) {
        $msg = ">>> Script ended abnormally"
        Report "N"  $msg $StatusObj $Tempfile
        Report "N"  " " $StatusObj $Tempfile
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "9" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        Add-Content $jobstatus "Failed item = $FailedItem"
        Add-Content $jobstatus "Errormessage = $ErrorMessage"
        Add-Content $jobstatus "Dump info = $dump"

        Report "E" "Failed item = $FailedItem" $StatusObj $Tempfile
        Report "E" "Errormessage = $ErrorMessage" $StatusObj $Tempfile
        Report "E" "Dump info = $dump" $StatusObj $Tempfile
        $returncode =  16        
    }
   
    if (($StatusObj.Scriptaction) -and ($returncode -eq 99)) {
        $msg = ">>> Script ended normally with action required"
        Report "W"  $msg $StatusObj $Tempfile
        Report "N"  " " $StatusObj $Tempfile
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "6" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode =  8
    }

    if (($StatusObj.Scriptchange) -and ($returncode -eq 99)) {
        $msg = ">>> Script ended normally with reported changes, but no action required"
        Report "C"  $msg $StatusObj $Tempfile
        Report "N"  " " $StatusObj $Tempfile
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "3" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode =  4
    }

    if ($returncode -eq 99) {

        $msg = ">>> Script ended normally without reported changes, and no action required"
        Report "I"  $msg $StatusObj $Tempfile
        Report "N"  " " $StatusObj $Tempfile
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "0" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode = 0
    }

    $d = Get-Date
    $Datum = " -- Date: " + $d.ToString("dd-MM-yyyy")
    $Tijd = " -- Time: " + $d.ToString("HH:mm:ss")
    $Scriptmsg = "*** ENDED ***** " + $mypath + " -- PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node
    Report "N" $scriptmsg $StatusObj $Tempfile
    Report "N" " " $StatusObj $Tempfile

    try { # Free resource and copy temp file        
        
        $deffile = $ADHC_OutputDirectory + $ADHC_CmdletXref.Directory + $ADHC_CmdletXref.Name 
        $Copmov = & $ADHC_CopyMoveScript $TempFile $deffile "MOVE" "REPLACE" $TempFile 
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
        Write-Information $Scriptmsg
        Add-Content $deffile $scriptmsg
        Exit $Returncode
        
    }  
   

} 
