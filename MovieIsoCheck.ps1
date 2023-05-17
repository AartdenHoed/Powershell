$Version = " -- Version: 1.1"

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
    
    $dir = $ADHC_TempDirectory + $ADHC_MovieIsoCheck.Directory
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $Tempfile = $dir + $ADHC_MovieIsoCheck.Name
    Set-Content $Tempfile $Scriptmsg -force

# ==============================================

    $IsoList = Get-ChildItem -Path $ADHC_IsoDirectory | Select Name,FullName,Extension

    $MovieList = @()

    $HolidayList = Get-ChildItem $ADHC_HolidayDir -Dir | Select Name,FullName 

    foreach ($holentry in $HolidayList) {
        # vind .mph file of /film directory
        $filmpresent = $false
        $filmdir = $holentry.FullName + "\Film"
        if (Test-Path $filmdir) {
            $filmpresent = $true
        }
        $filmdir = $holentry.FullName + "\Video"
        if (Test-Path $filmdir) {
            $filmpresent = $true
        }
        $mphtest = Get-ChildItem -Path $holentry.Fullname -Filter *.mph -Recurse -File 
        $mphcount = $mphtest.Count
        if ($mphcount -gt 0) {
            # Write-Host $filmdir $mphcount
            $filmpresent = $true
        }
        $wp3test = Get-ChildItem -Path $holentry.Fullname -Filter *.wp3 -Recurse -File 
        $wp3count = $wp3test.Count
        if ($wp3count -gt 0) {
            # Write-Host $filmdir $mphcount
            $filmpresent = $true
        }

        $filmname = $holentry.Name
        $filmdir = $holentry.Fullname
        if ($filmpresent) {
            $filmexists = "Yes"
        }
        else {
            $filmexists = "No"
        }

        # Check existence DVD copy 

        $DVDSaved = "No"
        $isofile = "No"
        $DVDaantal = 0

        foreach ($iso in $IsoList) {
            if ($iso.Name.Contains("$filmname")) {
                $DVDSaved = "Yes"
                $DVDaantal += 1
                if ($iso.Extension.ToUpper() -eq ".ISO") {
                    $isofile = "Yes"
                }
                
            } 
        }
            

        $Movie = [PSCustomObject] [ordered] @{Name = $filmname;
                                            Directory = $filmdir;    
                                            Filmexists = $filmexists; 
                                            DVDsaved = $DVDsaved;
                                            DVDaantal = $DVDaantal;
                                            ISO = $isofile}
        $MovieList += $Movie

    }

    # Now check if all DVD copies have an origin

    $NoParent = @()

    foreach ($iso in $IsoList) {
        $parentfound = "No"
       
        foreach ($parent in $MovieList) {
            $pn = $parent.Name
            if ($iso.Name.Contains("$pn")) {
                $parentfound = "Yes"   
                break             
            }             
        }
        $n = $iso.Name
        $f = $iso.Fullname
        $MovieFile = [PSCustomObject] [ordered] @{Name = $n;
                                            Fullname = $f;
                                            Parentfound = $parentfound}
        $NoParent += $MovieFile

    }


    # Create reports

    Report "N" " "
    Report "N" "-".PadRight(120,"-")

    # 1 Holidays without movie
    
    $NoMovie = 0
    $NoMovieBut = 0
    Report "N" " "
    Report "N" "##########                                                                          ##########"
    Report "N" "########## Holdays without movie                                                    ##########"
    Report "N" "##########                                                                          ##########"   
    Report "N" " "
    foreach ($entry in $Movielist) {
        if ($entry.Name -like "##*") {
            continue
        }
        if ($entry.Filmexists -eq "No") {
            $NoMovie += 1
            if ($entry.DVDsaved -eq "Yes") {
                $NoMovieBut +=1
                $myline = $entry.Name.PadRight(60," ") + "===> But $DVDaantal DVD copies found"
                
            }
            else {
                $myline = $entry.Name
            } 
            
            Report "N" $myline 
        } 

    } 
    Report "N" " "
    Report "I" "$NoMovie Holidays without movie"
    if ($NoMovieBut -gt 0 ) {
        Report "W" "$NoMovieBut Holidays without movie source but with DVD files"
    } 
    Report "N" " "
    Report "N" "-".PadRight(120,"-")

     # 2 Holidays with movie but without DVD copy
    
    $MoviePresent = 0
    $MovieNoDvd = 0
    $MovieNoIso = 0 
    Report "N" " "
    Report "N" "##########                                                                          ##########"
    Report "N" "########## Holidays with movie                                                      ##########"
    Report "N" "##########                                                                          ##########"   
    Report "N" " "
    foreach ($entry in $Movielist) {
        if ($entry.Name -like "##*") {
            continue
        }
        if ($entry.Filmexists -eq "Yes") {
            $MoviePresent += 1
            if ($entry.DVDsaved -eq "No") {
                $MovieNoDvd +=1
                $myline = $entry.Name.PadRight(60," ") + "!! ===> No DVD copy found"
                
            }
            else {
                if ($entry.ISO -eq "No") {
                    $myline = $entry.Name.PadRight(60," ") + "ok (But DVD copy is not in ISO format)"
                    $MovieNoIso += 1 
                }
                else {
                    $myline = $entry.Name.PadRight(60," ") + "ok"  
                }                
            }             
            Report "N" $myline 
        } 

    } 
    Report "N" " "
    Report "I" "$MoviePresent Holidays with movie"
    if ($MovieNoDvd -gt 0 ) {
        Report "W" "$MovieNoDvd Holidays with a movie don't have a DVD copy"
    } 
    if ($MovieNoIso -gt 0 ) {
        Report "A" "$MovieNoIso Holidays with a movie have a NON-ISO DVD copy"
    } 
    Report "N" " "
    Report "N" "-".PadRight(120,"-")

    # 3 DVD copies without parent
    
    $NoParentCount = 0
    Report "N" " "
    Report "N" "##########                                                                          ##########"
    Report "N" "########## DVD copies without parent (source files)                                 ##########"
    Report "N" "##########                                                                          ##########"   
    Report "N" " "
    foreach ($entry in $NoParent) {
        
        if ($entry.Parentfound -eq "No") {
            $NoParentcount +=1
            $myline = $entry.Name.PadRight(60," ") 
            Report "N" $myline 
        }       
 
    } 
    Report "N" " "
    
    if ($NoParentFound -gt 0 ) {
        Report "W" "$NoParentCount DVD copies found without parent (source files)"
    } 
    else {
        Report "I" "All DVD copies have a parent (source files)"
    } 
    Report "N" " "
    Report "N" "-".PadRight(120,"-")


     

# ==============================================  


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
        
        $deffile = $ADHC_OutputDirectory + $ADHC_MovieIsoCheck.Directory + $ADHC_MovieIsoCheck.Name 
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
