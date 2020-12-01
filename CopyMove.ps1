param (
     [string]$InputFile = "In"  ,
     [string]$OutputFile = "Out" ,
     [string]$Action = "Move/COpy" ,
     [string]$Mode = "Replace/Append" ,
     [string]$Messages = $Null,
     [string]$Lock = ""
)
#$InputFile = "D:\AartenHetty\OneDrive\Documents\Bron.txt"
#$Action = "move"
#$Mode = "Append"
#$OutputFile = "D:\AartenHetty\OneDrive\NogNie\Target.txt"
#$Lock ="a,b"

$Action = $Action.ToUpper()
$Mode = $Mode.ToUpper()
$Actionlist = @("MOVE","COPY")
$Modelist = @("REPLACE","APPEND")

$ScriptVersion = " -- Version: 1.1"

function Report ([string]$level, [string]$line) {
    
    switch ($level) {
        ("N") {$rptline = $line}
        ("I") {
            $rptline = "Info    *".Padright(10," ") + $line
        }
        ("H") {
            $rptline = "-------->".Padright(10," ") + $line
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
        default {
            $rptline = "Error   *".Padright(10," ") + "Messagelevel $level is not valid"
            $global:scripterror = $true
        }
    }
    if ($global:writemsg) {
        Add-Content $Messages $rptline
    }
    else {
        Write-Host $rptline
    }

}

$scripterror = $false

# COMMON coding
Try {
    $InformationPreference = "Continue"
    $WarningPreference = "Continue"
    $ErrorActionPreference = "Stop"

    $Node = " -- Node: " + $env:COMPUTERNAME
    $d = Get-Date
    $Datum = " -- Date: " + $d.ToString("dd-MM-yyyy")
    $Tijd = " -- Time: " + $d.ToString("HH:mm:ss")

    $myname = $MyInvocation.MyCommand.Name
    $p = $myname.Split(".")
    $process = $p[0]
    $FullScriptName = $MyInvocation.MyCommand.Definition
    $mypath = $FullScriptName.Replace($MyName, "")

    $LocalInitVar = $mypath + "InitVar.PS1"
    & "$LocalInitVar" -JSON Silent
    if (!$ADHC_InitSuccessfull) {
        # Write-Warning "YES"
        throw $ADHC_InitError
    }
}
Catch {
    $scripterror = $true
    $errortext = $error[0]
    $scripterrormsg = "Input validation failed - $errortext"
    Report "E" "$scripterrormsg"

}

# Determine input parameters and verify input

if (!$scripterror) {
    try {
        if ($Messages) {
            $global:writemsg = $true
            if (!(Test-Path $Messages)) {
                Throw "Messages file $messages does not exist"
            }
        } 
        else {
            $global:writemsg = $false
        }
        $Scriptmsg = "*** STARTED *** " + $mypath + " -- PowerShell script " + $MyName + $ScriptVersion + $Datum + $Tijd +$Node
        Report "N" $Scriptmsg 
        Write-Host $scriptmsg
    
        $mymsg = "Input Validation: $Action file $InputFile to $Outputfile (mode: $Mode)"
        Report "I"  $mymsg
        if ($lock) {
            Report "I" "... With lock parameters $lock"
        }

        if ($global:writemsg) {
            $mymsg = "Messages will be written to $Messages"
        }
        else {
            $mymsg = "Messages will be suppressed"
        }
        Report "I"  $mymsg

        if (!(Test-Path $InputFile)) {
            Throw "Input file $InputFile does not exist"
        }
        if (!($Actionlist -contains $action)) {
            Throw "Action $action is invalid"
        }
        if (!($Modelist -contains $Mode)) {
            Throw "Mode $mode is invalid"
        }
        if ($Lock) {
            $lockverbs = $lock.SPlit(",")
            if ($lockverbs.Count -ne 2) {
                Throw "Lock parameter $lock must consist of exactly two words"    
            } 
            $Resource = $lockverbs[0]
            $Process = $lockverbs[1]
            If (!($Resource -match "\w+")) {
                Throw "Lock resource $Resource is not valid"
            }
            If (!($Process -match "\w+")) {
                Throw "Lock process $process is not valid"
            }
        }

    
    }
    catch {    
        $scripterror = $true
        $errortext = $error[0]
        $scripterrormsg = "Input validation failed - $errortext"
        Report "E" "$scripterrormsg" 
    }
}

if (!$scripterror) {
    try {
        Report "I" "Perform requested actions"
        if ($lock) {
            $m = & $ADHC_LockScript "Lock" "$Resource" "$Process" "10" "SILENT"
            foreach ($msgentry in $m) {
                $msglvl = $msgentry.level
                $msgtext = $msgentry.Message
                Report $msglvl $msgtext
            }            
        } 
        $outdir = Split-Path $Outputfile
        if (!(Test-Path $outdir)) {
            New-Item  -Path "$outdir" -ItemType directory -force | Out-Null
            Report "I" "Directory $outdir did not exist but has been created now"
        }
        if ($Action -eq "COPY") {
            if ($Mode -eq "REPLACE") {
                copy-item -path "$inputfile" -destination "$outputfile" -force
            }
            else {
                Get-Content $inputfile | Out-Null                
                Add-Content $outputfile $inputfile
            }

           
        }
        else {
            if ($Mode -eq "REPLACE") {
                move-item -path "$inputfile" -destination "$outputfile" -force
            }
            else {
                Get-Content $inputfile | Out-Null               
                Add-Content $outputfile $inputfile
                Remove-Item $inputfile
            }               
            
        }
        if ($Messages.ToUpper() -eq $Inputfile.ToUpper()) {
            $Messages = $OutputFile                           # from here messages are directed to output file
        }

        Report "I" "$ACTION with $MODE $inputfile to $outputfile completed"
        if ($lock) {
            $m = & $ADHC_LockScript "Free" "$Resource" "$Process" "10" "SILENT"
            foreach ($msgentry in $m) {
                $msglvl = $msgentry.level
                $msgtext = $msgentry.Message
                Report $msglvl $msgtext
            }            
        } 
              
    }
    catch {
        $scripterror = $true
        $errortext = $error[0]
        $scripterrormsg = "Requested actions failed - $errortext"
        Report "E" "$scripterrormsg"
    }
}
if ($scripterror) {
    throw "$FullScriptName ended abnormally"
} 
else {
    $d = Get-Date
    $Datum = " -- Date: " + $d.ToString("dd-MM-yyyy")
    $Tijd = " -- Time: " + $d.ToString("HH:mm:ss")
    $Scriptmsg = "*** ENDED ***** " + $mypath + " -- PowerShell script " + $MyName + $ScriptVersion + $Datum + $Tijd +$Node
    Report "N" $Scriptmsg 
    Write-Host $scriptmsg
}

