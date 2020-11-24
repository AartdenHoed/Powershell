cls
Write-Warning "Version 1.0"
Write-Warning "Scannen van files op bepaalde literals"
Write-Warning "Selecteer een directory" 

[void][System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")    

$OpenFolderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
$OpenFolderDialog.SelectedPath = "D:\AartenHetty\OneDrive\ADHC Development"
$Show = $OpenFolderDialog.ShowDialog()
if ($Show -eq "OK") {
    $FileDirectory = $OpenFolderDialog.SelectedPath
}
else {
    Write-Warning "Operation cancelled by user."
    return
}

$t = Get-Date
Write-Host $t

 
$FileList = Get-ChildItem $FileDirectory -Recurse -File  -Exclude *.png,*.jpg,*.dll |  `

        Where-Object {(($_.FullName -notlike "*.git*") -and `                        ($_.FullName -notlike "*\.vs\*") -and `                        ($_.FullName -notlike "*\debug\*") -and `                        ($_.FullName -notlike "*\packages\*") -and `                        ($_.FullName -notlike "*\bin\*")) } | `    	Select-Object Name,Fullname
$Totaal = $FileList.count
Write-host "$Totaal Files will be analyzed"

$n = 0
$percentiel = [math]::floor($totaal / 10)
$part = $percentiel


# $Filelist | Out-GridView

$FileCount = 0


$searchlist = @("Credential","Userid","USR","PSW","PASSWORD")

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