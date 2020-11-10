$Version = " -- Version: 2.4"

# COMMON coding
CLS

$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"

try {
    $Node = " -- Node: " + $env:COMPUTERNAME
    $d = Get-Date
    $Datum = " -- Date: " + $d.ToShortDateString()
    $Tijd = " -- Time: " + $d.ToShortTimeString()

    $myname = $MyInvocation.MyCommand.Name
    $FullScriptName = $MyInvocation.MyCommand.Definition
    $mypath = $FullScriptName.Replace($MyName, "")

    $Scriptmsg = "Directory " + $mypath + " -- PowerShell script " + $MyName + $Version + $Datum + $Tijd +$Node
    Write-Information $Scriptmsg 

    $LocalInitVar = $mypath + "InitVar.PS1"
    & "$LocalInitVar"

    if (!$ADHC_InitSuccessfull) {
        # Write-Warning "YES"
        throw $ADHC_InitError
    }

     # init flags
    $scripterror = $false
    $scriptaction = $false
    $scriptchange = $false

# END OF COMMON CODING   

    # Init reporting file
    $str = $ADHC_VariableXref.Split("/")
    $dir = $ADHC_OutputDirectory + $str[0]
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $Report = $ADHC_OutputDirectory + $ADHC_VariableXref
    Set-Content $Report $Scriptmsg -force

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
    
    Write-Host "$FileCount Files have been scanned with $varcount search strings"  

    $Sorted = $Resultlist | Sort-Object -Property Searchstring,SourceFile  

    $curname = "@#$"
    Add-Content $Report " "
    $rptline = " === Cross reference between ADHC variables and sources in $ADHC_Stagingdir === "
    Add-Content $Report $rptline

    foreach ($hit in $Sorted) {
        $varname = $hit.Searchstring
        if ($varname -ne $curname) {
            Add-Content $Report " "
            $rptline = $varname.Padright(32," ") + "hits = " + $hit.nrofhits.ToString().Padright(8," ") +  $hit.Sourcefile.PadRight(100," ") + "Value = '"+ $hit.Value + "'"
            Add-Content $Report $rptline
            $curname = $varname
        }
        else {
            $rptline = " ".Padright(32," ") + "hits = " + $hit.nrofhits.ToString().Padright(8," ") +  $hit.Sourcefile.PadRight(100," ") 
            Add-Content $Report $rptline
        }
     

    } 

    # report ADHC variables that are not being used
    Add-Content $Report " "
    $rptline = " === ADHC variables that are not being referenced in any source in $ADHC_Stagingdir === "
    Add-Content $Report $rptline

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
            Add-Content $Report $rptline
            write-warning "$findvar not referenced in any source"
            $written = $true
        }
    
    
    }
    if (!$written) { 
        $rptline = " >>> N O N E"
        Add-Content $Report $rptline
    } 
    else {
        $scriptaction = $true
    }

}
catch {
    $scripterror = $true
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
    
    Add-Content $Report " "

        
    if ($scripterror) {
        $msg = ">>> Script ended abnormally"
        Add-Content $Report $msg
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "9" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        Add-Content $jobstatus "Failed item = $FailedItem"
        Add-Content $jobstatus "Errormessage = $ErrorMessage"
        Add-Content $jobstatus "Dump info = $dump"

        Report "E" "Failed item = $FailedItem"
        Report "E" "Errormessage = $ErrorMessage"
        Report "E" "Dump info = $dump"
        exit 16        
    }
   
    if ($scriptaction) {
        $msg = ">>> Script ended normally with action required"
        Add-Content $Report $msg
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "6" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        exit 8
    }

    if ($scriptchange) {
        $msg = ">>> Script ended normally with reported changes, but no action required"
        Add-Content $Report $msg
        $dt = Get-Date
        $jobline = $ADHC_Computer + "|" + $process + "|" + "3" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
        Set-Content $jobstatus $jobline
       
        exit 4
    }

    $msg = ">>> Script ended normally without reported changes, and no action required"
    Add-Content $Report $msg
    $dt = Get-Date
    $jobline = $ADHC_Computer + "|" + $process + "|" + "0" + "|" + $version + "|" + $dt.ToString("dd-MM-yyyy HH:mm:ss")
    Set-Content $jobstatus $jobline
       
    exit 0
   

} 
