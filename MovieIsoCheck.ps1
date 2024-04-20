$Version = " -- Version: 1.2.1"

# COMMON coding
CLS

$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"

# init flags
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
    
    $dir = $ADHC_TempDirectory + $ADHC_MovieIsoCheck.Directory
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $Tempfile = $dir + $ADHC_MovieIsoCheck.Name
    Set-Content $Tempfile $Scriptmsg -force
    foreach ($entry in $InitObj.MessageList){
        Report $entry.Level $entry.Message $StatusObj $Tempfile
    }

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
        $isofile = "??"
        $DVDaantal = 0
        $isoaantal = 0
        $otheraantal = 0

        foreach ($iso in $IsoList) {
            if ($iso.Name.Contains("$filmname")) {
                $DVDSaved = "Yes"
                $DVDaantal += 1
                if ($iso.Extension.ToUpper() -eq ".ISO") {
                    $isoaantal += 1
                }
                else {
                    $otheraantal += 1
                }
                
            } 
        }
            

        $Movie = [PSCustomObject] [ordered] @{Name = $filmname;
                                            Directory = $filmdir;    
                                            Filmexists = $filmexists; 
                                            DVDsaved = $DVDsaved;
                                            DVDaantal = $DVDaantal;
                                            ISOaantal = $isoaantal;
                                            OTHERaantal = $otheraantal
                                            }
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

    Report "N" " " $StatusObj $Tempfile
    Report "N" "-".PadRight(120,"-") $StatusObj $Tempfile

    # 1 Holidays without movie
    
    $NoMovie = 0
    $NoMovieBut = 0
    Report "N" " " $StatusObj $Tempfile
    Report "N" "##########                                                                          ##########" $StatusObj $Tempfile
    Report "N" "########## Holdays without movie                                                    ##########" $StatusObj $Tempfile
    Report "N" "##########                                                                          ##########" $StatusObj $Tempfile 
    Report "N" " " $StatusObj $Tempfile
    foreach ($entry in $Movielist) {
        if ($entry.Name -like "##*") {
            continue
        }
        if ($entry.Filmexists -eq "No") {
            $NoMovie += 1
            if ($entry.DVDsaved -eq "Yes") {
                $NoMovieBut +=1
                $a = $entry.DVDaantal
                $myline = $entry.Name.PadRight(60," ") + "===> But $a DVD copies found"
                
            }
            else {
                $myline = $entry.Name
            } 
            
            Report "N" $myline $StatusObj $Tempfile
        } 

    } 
    Report "N" " " $StatusObj $Tempfile
    Report "I" "$NoMovie Holidays without movie" $StatusObj $Tempfile
    if ($NoMovieBut -gt 0 ) {
        Report "W" "$NoMovieBut Holidays without movie source but with DVD files" $StatusObj $Tempfile
    } 
    Report "N" " " $StatusObj $Tempfile
    Report "N" "-".PadRight(120,"-") $StatusObj $Tempfile

     # 2 Holidays with movie but without DVD copy
    
    $MoviePresent = 0
    $MovieNoDvd = 0
    $MovieNoIso = 0 
    Report "N" " " $StatusObj $Tempfile
    Report "N" "##########                                                                          ##########" $StatusObj $Tempfile
    Report "N" "########## Holidays with movie                                                      ##########" $StatusObj $Tempfile
    Report "N" "##########                                                                          ##########" $StatusObj $Tempfile 
    Report "N" " " $StatusObj $Tempfile
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
                $aantal = $entry.DVDaantal
                if ($aantal -eq 1) {
                    $line = "ok"
                }
                else {
                    $line = "ok - Aantal = $aantal -" 
                }
                if ($entry.OTHERaantal -ne 0) {
                    $o = $entry.OTHERaantal
                    $myline = $entry.Name.PadRight(60," ") + $line.PadRight(20," ") + "(But $o DVD copies without ISO format)"
                    $MovieNoIso += 1 
                }
                else {
                    $myline = $entry.Name.PadRight(60," ") + $line  
                }                
            }             
            Report "N" $myline $StatusObj $Tempfile
        } 

    } 
    Report "N" " " $StatusObj $Tempfile
    Report "I" "$MoviePresent Holidays with one or more movies" $StatusObj $Tempfile
    if ($MovieNoDvd -gt 0 ) {
        Report "W" "$MovieNoDvd Holidays with a movie don't have a DVD copy" $StatusObj $Tempfile
    } 
    if ($MovieNoIso -gt 0 ) {
        Report "A" "$MovieNoIso Holidays with a movie have a NON-ISO DVD copy" $StatusObj $Tempfile
    } 
    Report "N" " " $StatusObj $Tempfile
    Report "N" "-".PadRight(120,"-") $StatusObj $Tempfile

    # 3 DVD copies without parent
    
    $NoParentCount = 0
    Report "N" " " $StatusObj $Tempfile
    Report "N" "##########                                                                          ##########" $StatusObj $Tempfile
    Report "N" "########## DVD copies without parent (source files)                                 ##########" $StatusObj $Tempfile
    Report "N" "##########                                                                          ##########" $StatusObj $Tempfile  
    Report "N" " " $StatusObj $Tempfile
    foreach ($entry in $NoParent) {
        
        if ($entry.Parentfound -eq "No") {
            $NoParentCount +=1
            $myline = $entry.Name.PadRight(60," ") 
            Report "N" $myline $StatusObj $Tempfile
        }       
 
    } 
    Report "N" " " $StatusObj $Tempfile
    
    if ($NoParentCount -gt 0 ) {
        Report "W" "$NoParentCount DVD copies found without parent (source files)" $StatusObj $Tempfile
    } 
    else {
        Report "I" "All DVD copies have a parent (source files)" $StatusObj $Tempfile
    } 
    Report "N" " " $StatusObj $Tempfile
    Report "N" "-".PadRight(120,"-") $StatusObj $Tempfile


     

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

    
    try { # Free resource and copy temp file        
        
        $deffile = $ADHC_OutputDirectory + $ADHC_MovieIsoCheck.Directory + $ADHC_MovieIsoCheck.Name 
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
