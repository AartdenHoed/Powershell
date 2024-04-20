$Version = " -- Version: 1.1.1"

# COMMON coding
CLS

$StatusOBJ = [PSCustomObject] [ordered] @{Scripterror = $false;
                                          ScriptChange = $false;
                                          ScriptAction = $false;
                                          }

$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"

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
    
    $dir = $ADHC_TempDirectory + $ADHC_SourceXref.Directory
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $Tempfile = $dir + $ADHC_SourceXref.NAme
    Set-Content $Tempfile $Scriptmsg -force

    foreach ($entry in $InitObj.MessageList){
        Report $entry.Level $entry.Message $StatusObj $Tempfile
    }

    $filelist = Get-ChildItem $ADHC_Stagingdir -Recurse -File | Select-Object Name,Fullname,Extension
    
    $searchlist = $filelist 
    $Sortedsearch = $searchlist | Sort-Object -Property Name,FullName  

    $Totaal = $fileList.count
    $n = 0
    $percentiel = [math]::floor($totaal / 10)
    $part = $percentiel

    $FileCount = 0
    $Skipped = 0
    $Scanned = 0
    $arguments = 0  

    $Resultlist = @()

    $ToMatch = @(".DLL",".PNG",".JPG",".PDB",".JS",".CSS",".MAP",".TARGETS",".ASAX",".MD",".EXE")

    foreach ($sourcefile in $filelist) {

        # Write-host $sourcefile.FullName
            
        $Filecount = $Filecount + 1
        $n = $n + 1;
        if ($n -eq $part) {
            $percentage = [math]::round($n * 100 / $totaal)
            Write-host "Processing $n van $totaal ($percentage %)"
            $part = $part + $percentiel
        }     

        if ($ToMatch -contains $sourcefile.Extension.ToUpper()) {
            $Skipped += 1
            continue
        }
        else {
            $scanned += 1
        }

        $fname = $sourcefile.FullName         
        $lines = (Get-Content $sourcefile.FullName)     
        
        $cursort = "&aaa^%"
        $nrofhits = 0 
          
               
        foreach ($searchfile in $sortedsearch) {
            
            if ($searchfile.Name.ToUpper() -ne $cursort) {
                if ($nrofhits -gt 0 ) {               
                
                    # Write-Host "$matchme found in $fname"
                    $TargetObject = [PSCustomObject] [ordered]  @{Sourcefile = $fname; ReferencedFile = $matchme ; NrofHits = $nrofhits; Occurences = $occurences  }  
                                                                          
                    $Resultlist += $TargetObject
                    $arguments += 1
                
                }
                $nrofhits = 0  
                $occurences = 1
                $cursort = $searchfile.Name.ToUpper()
                foreach ($line in $lines) {
                    $matchme = $searchfile.Name.ToUpper()
                    if ($line.ToUpper() -match $matchme) {
                        $nrofhits = $nrofhits + 1                
                    }            
                }
            }
            else {
                $occurences = $occurences + 1
            }
            
        }
        # Proces last one
        if ($nrofhits -gt 0 ) {
            
            $arguments += 1
                
            # Write-Host "$matchme found in $fname"
            $TargetObject = [PSCustomObject] [ordered]  @{Sourcefile = $fname; ReferencedFile = $matchme ; NrofHits = $nrofhits; Occurences = $occurences  } 
                                                                          
            $Resultlist += $TargetObject
                
        }        
    }
    Report "N"  " " $StatusObj $Tempfile
    Report "I"   "In scope were $FileCount files (of which $Scanned scanned and $skipped skipped) with $arguments search strings" $StatusObj $Tempfile

    $Sorted = $Resultlist | Sort-Object -Property ReferencedFile,SourceFile  

    $curname = "@#$"
    Report "N"  " " $StatusObj $Tempfile
    $rptline = " === Cross reference between ADHC sources in $ADHC_Stagingdir === "
    Report "N"  $rptline  $StatusObj $Tempfile

    foreach ($hit in $Sorted) {
        $varname = $hit.ReferencedFile
        if ($varname -ne $curname) {
            Report "N"  " " $StatusObj $Tempfile
            $rptline = $varname.Padright(44," ") + "occurences = " + $hit.occurences.ToString().Padright(8," ") +
                                                    "hits = " + $hit.nrofhits.ToString().Padright(8," ") +  $hit.Sourcefile.PadRight(100," ")
            Report "N"  $rptline $StatusObj $Tempfile
            $curname = $varname
        }
        else {
            $rptline = " ".Padright(44," ") + " ".Padright(21," ") +
                                                    "hits = " + $hit.nrofhits.ToString().Padright(8," ") +  $hit.Sourcefile.PadRight(100," ")
            Report "N"  $rptline $StatusObj $Tempfile
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
   
    if (($StatusObj.scriptaction) -and ($returncode -eq 99)) {
        $msg = ">>> Script ended normally with action required"
        Report "W"  $msg $StatusObj $Tempfile
        Report "N"  " " $StatusObj $Tempfile
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "6" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode =  8
    }

    if (($StatusObj.scriptchange) -and ($returncode -eq 99)) {
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

    try { # Free resource and copy temp file        
        
        $deffile = $ADHC_OutputDirectory + $ADHC_SourceXref.Directory + $ADHC_SourceXref.Name 
        $x = & $ADHC_CopyMoveScript $TempFile $deffile "MOVE" "REPLACE" $TempFile 
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
