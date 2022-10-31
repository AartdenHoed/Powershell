cls
Write-Warning "Version 2.0"
Write-Warning "Scannen van files op bepaalde literals"
Write-Warning "Selecteer een directory" 

[void][System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")    

$OpenFolderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
$OpenFolderDialog.SelectedPath = "o:\"
$Show = $OpenFolderDialog.ShowDialog()
if ($Show -eq "OK") {
    $FileDirectory = $OpenFolderDialog.SelectedPath
}
else {
    Write-Warning "Operation cancelled by user."
    return
}

$avi = 0
$dll = 0
$exe = 0
$jpeg = 0
$jpg = 0
$mov = 0
$mp3 = 0
$mp4 = 0
$png = 0

 
$TotalList = Get-ChildItem $FileDirectory -Recurse -File | Select-Object Name,Fullname,Extension
$FileList = @()

foreach ($foundfile in $TotalList) {

    switch ($foundfile.Extension.ToUpper()) {
        ".AVI" {$avi +=1}
        ".DLL" {$dll +=1}
        ".EXE" {$exe +=1}
        ".JPEG" {$jpeg +=1}
        ".JPG" {$jpg +=1}
        ".MOV" {$mov +=1}
        ".MP3" {$mp3 +=1}
        ".MP4" {$mp4 +=1}
        ".PNG" {$png +=1}
        default {$FileList += $foundfile}
    }

} 

Write-Host "Excluded files:"
Write-Host "$avi AVI files"
Write-Host "$dll DLL files"
Write-Host "$exe EXE files"
Write-Host "$jpeg JPEG files"
Write-Host "$jpg JPG files"
Write-Host "$mov MOV files"
Write-Host "$mp3 MP3 files"
Write-Host "$mp4 MP4 files"
Write-Host "$png PNG files"

      
$Totaal = $FileList.count
Write-Host "=============================="
Write-host "$Totaal Files will be analyzed"

$n = 0
$percentiel = [math]::floor($totaal / 10)
$part = $percentiel


# $Filelist | Out-GridView

$FileCount = 0


$TempFile = New-TemporaryFile
Set-Content $TempFile "~ Specificeer hieronder de zoekargumenten en save the file."
Add-Content $TempFile "~ Eén zoekargument per regel"
Add-Content $TempFile "~ (Het ~-teken in positie 1 geeft een commentaarregel aan)"

Start-Process -FilePath 'C:\Windows\Notepad.exe' -ArgumentList $TempFile -wait

# Write-Host "Passed"

$searchlist = @()
$searchargs = (Get-Content $Tempfile)   

$t = Get-Date
Write-Host $t             
    
foreach ($searcharg in $searchargs) {      
    if ($searcharg.Substring(0,1) -ne "~") {
        $searcharg = $searcharg.Trim()
        # $searcharg
        $searchlist += $searcharg     
    }
}         


$Resultlist = @()


foreach ($File in $FileList) {

    # Write-host $File.FullName
    
    $Filecount = $Filecount + 1
       
    $n = $n + 1

    if ($n -eq $part) {
        $percentage = [math]::round($n * 100 / $totaal)
        Write-host "Processing $n van $totaal ($percentage %)"
        $part = $part + $percentiel
    }         
               
    $lines = (Get-Content $File.FullName)                
    
    foreach ($arg in $searchlist) {      
        foreach ($line in $lines) {         
        
            if ($line.ToUpper() -match $arg.ToUpper()) {
                $fname = $File.FullName
                Write-Host "$arg found in $fname"
                $TargetObject = [PSCustomObject] [ordered]  @{File = $fname; Searchstring = $arg ; Line = $line}  
                                                                            
                $Resultlist += $TargetObject
                break                               # one hit is enough
            }
        }
            
    }        
}
    
Write-Host "$FileCount Files" 
 

$t = Get-Date
Write-Host $t


$Resultlist | Out-GridView    
Remove-Item $TempFile
Write-Host "$Tempfile Deleted"