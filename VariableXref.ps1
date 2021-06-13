$Version = " -- Version: 3.1.1"

# COMMON coding
CLS

$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"

function Report ([string]$level, [string]$line) {
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
            $global:scriptchange = $true
        }
        ("W") {
            $rptline = "Warning *".Padright(10," ") + $line
            $global:scriptaction = $true
        }
        ("E") {
            $rptline = "Error   *".Padright(10," ") + $line
            $global:scripterror = $true
        }
        ("G") {
            $rptline = "GIT:    *".Padright(10," ") + $line
        }
        default {
            $rptline = "Error   *".Padright(10," ") + "Messagelevel $level is not valid"
            $global:scripterror = $true
        }
    }
    Add-Content $tempfile $rptline

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
    & "$LocalInitVar"

    if (!$ADHC_InitSuccessfull) {
        # Write-Warning "YES"
        throw $ADHC_InitError
    }

     # init flags
    $global:scripterror = $false
    $global:scriptaction = $false
    $global:scriptchange = $false

# END OF COMMON CODING   

    # Init reporting file
    
    $dir = $ADHC_TempDirectory + $ADHC_VariableXref.Directory
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $Tempfile = $dir + $ADHC_VariableXref.NAme
    Set-Content $Tempfile $Scriptmsg -force

    $ADHCvars = Get-Variable |  Where-Object {$_.Name -like "ADHC_*"}
    $varcount = $ADHCvars.Count

    $filelist = Get-ChildItem $ADHC_Stagingdir -Recurse -File | Select-Object Name,Fullname
    $Totaal = $fileList.count
    $n = 0
    $percentiel = [math]::floor($totaal / 10)
    $part = $percentiel

    $FileCount = 0

    $Resultlist = @()

    foreach ($sourcefile in $filelist) {

        if ($sourcefile.Name -eq $ADHC_InitVar) {
            # Skip references from initvar
            continue
        }


        # Write-host $sourcefile.FullName
    
        $Filecount = $Filecount + 1
    
        $n = $n + 1;

        if ($n -eq $part) {
            $percentage = [math]::round($n * 100 / $totaal)
            Write-host "Processing $n van $totaal ($percentage %)"
            $part = $part + $percentiel
        }         
               
        $lines = (Get-Content $sourcefile.FullName) 
    
                 
        foreach ($myvar in $ADHCvars) {
            $nrofhits = 0  
            $fvalue = $myvar.Value
            foreach ($line in $lines) {
                $matchme = $myvar.Name.ToUpper()
                if ($line.ToUpper() -match $matchme) {
                    $nrofhits = $nrofhits + 1                
                }
            
            }
            if ($nrofhits -gt 0 ) {
                $fname = $sourcefile.FullName
                
                # Write-Host "$matchme found in $fname"
                $TargetObject = [PSCustomObject] [ordered]  @{Sourcefile = $fname; Searchstring = $matchme ; NrofHits = $nrofhits ; Value = $fvalue}  
                                                                          
                $Resultlist += $TargetObject
            }
        }        
    }
    
    Report "N"  " "
    Report "I"  "$FileCount Files have been scanned with $varcount search strings"  

    $Sorted = $Resultlist | Sort-Object -Property Searchstring,SourceFile  

    $curname = "@#$"
    Report "N"  " "
    $rptline = " === Cross reference between ADHC variables and sources in $ADHC_Stagingdir === "
    Report "N"  $rptline

    foreach ($hit in $Sorted) {
        $varname = $hit.Searchstring
        if ($varname -ne $curname) {
            Report "N"  " "
            $rptline = $varname.Padright(32," ") + "hits = " + $hit.nrofhits.ToString().Padright(8," ") +  $hit.Sourcefile.PadRight(100," ") + "Value = '"+ $hit.Value + "'"
            Report "N"  $rptline
            $curname = $varname
        }
        else {
            $rptline = " ".Padright(32," ") + "hits = " + $hit.nrofhits.ToString().Padright(8," ") +  $hit.Sourcefile.PadRight(100," ") 
            Report "N"  $rptline
        }
     

    } 

    # report ADHC variables that are not being used
    Report "N"  " "
    $rptline = " === ADHC variables that are not being referenced in any source in $ADHC_Stagingdir === "
    Report "N"  $rptline

    $written = $false

    foreach ($fvar in $ADHCvars) {
        $findvar = $fvar.Name.ToUpper()

        $foundit = $false
        foreach ($s in $sorted) {
            if ($findvar-eq $s.Searchstring) {
                $foundit = $true
            }
        }
        if (!$foundit) {
            $rptline = " >>> $findvar"
            Report "N"  $rptline
            write-warning "$findvar not referenced in any source"
            $written = $true
        }
    
    
    }
    if (!$written) { 
        $rptline = " >>> N O N E"
        Report "N"  $rptline
    } 
    else {
        $global:scriptaction = $true
    }

}
catch {
    $global:scripterror = $true
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
    
    Report "N"  " "
    $returncode = 99
        
    if (($global:scripterror) -and ($returncode -eq 99)) {
        $msg = ">>> Script ended abnormally"
        Report "N"  $msg
        Report "N"  " "
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "9" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        Add-Content $jobstatus "Failed item = $FailedItem"
        Add-Content $jobstatus "Errormessage = $ErrorMessage"
        Add-Content $jobstatus "Dump info = $dump"

        Report "E" "Failed item = $FailedItem"
        Report "E" "Errormessage = $ErrorMessage"
        Report "E" "Dump info = $dump"
        $returncode =  16        
    }
   
    if (($global:scriptaction) -and ($returncode -eq 99)) {
        $msg = ">>> Script ended normally with action required"
        Report "W"  $msg
        Report "N"  " "
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "6" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode =  8
    }

    if (($global:scriptchange) -and ($returncode -eq 99)) {
        $msg = ">>> Script ended normally with reported changes, but no action required"
        Report "C"  $msg
        Report "N"  " "
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "3" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode =  4
    }

    if ($returncode -eq 99) {

        $msg = ">>> Script ended normally without reported changes, and no action required"
        Report "I"  $msg
        Report "N"  " "
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "0" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        $returncode = 0
    }

    $d = Get-Date
    $Datum = " -- Date: " + $d.ToString("dd-MM-yyyy")
    $Tijd = " -- Time: " + $d.ToString("HH:mm:ss")
    $Scriptmsg = "*** ENDED ***** " + $mypath + " -- PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node
    Report "N" $scriptmsg
    Report "N" " "

    try { # Free resource and copy temp file        
        
        $deffile = $ADHC_OutputDirectory + $ADHC_VariableXref.Directory + $ADHC_VariableXref.Name 
        & $ADHC_CopyMoveScript $TempFile $deffile "MOVE" "REPLACE" $TempFile 
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
        Exit $Returncode
        
    }  
   

} 
