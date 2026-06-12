# Collect Software Inventory - Modern PowerShell Approach
# Replaces WMIC for completeness and future-proofing

$Output = @()

# 1. Scan Windows Installer (MSI) via Get-Package (Modern)
# Dit pakt software die via de Windows Installer service is geregistreerd
try {
    $Packages = Get-Package -ErrorAction SilentlyContinue | Where-Object { $_.ProviderName -ne "msu"}
    # 'Programs|Chocolatey|Npm|Pip' -or 
    #    $_.Name -ne $null}
    foreach ($pkg in $Packages) {
        $Output += [PSCustomObject]@{
            Source      = '2 - Get-Package - ' + $pkg.ProviderName
            Name        = $pkg.Name
            Version     = $pkg.Version
            Vendor      = "Unknown"
            InstallDate = $null
            InstallLocation = $pkg.Source
            
        }
    }
    
} 
catch {
    Write-Warning "Fout bij Get-Package: $_"
}

# 2. Scan Register Uninstall Keys (Voor niet-MSI software)
# Dit vult de gaten op die WMIC laat vallen
$RegistryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

foreach ($Path in $RegistryPaths) {
    try {
        $Keys = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue
        foreach ($Key in $Keys) {
            $Props = Get-ItemProperty -Path $Key.PSPath -ErrorAction SilentlyContinue
            
            # Filter op naam, want sommige keys zijn leeg of testkeys
            if ($Props.DisplayName) {
                if ([string]::IsNullOrEmpty($Props.Publisher)) {
                    $lev = "Unknown"
                }
                else {
                    $lev = $Props.Publisher
                    if ($lev -eq "Uw bedrijfsnaam") {
                         $lev = "Unknown"
                    }
                }
                $Output += [PSCustomObject]@{
                    Source      = '1 - Registry'
                    Name        = $Props.DisplayName
                    Version     = $Props.DisplayVersion
                    Vendor      = $lev
                    InstallDate = $Props.InstallDate # Vaak YYYYMMDD formaat
                    InstallLocation = $Props.InstallLocation
                    
                }
            }
        }
    } catch {
        # Stille foutafhandeling voor sleutels zonder leesrechten
    }
}

# 3. Scan Appx (Store Apps) voor volledigheid
try {
    $Apps = Get-AppxPackage -AllUsers | Where-Object { $_.IsFramework -eq $false }
    foreach ($app in $Apps) {
        $lev = $app | Get-AppxPackageManifest | % {$_.Package.Properties.PublisherDisplayName}
        if (($lev -eq "ms-resource:PublisherDisplayName") -or ([string]::IsNullOrEmpty($lev))) {
            $lev = "Unknown"
        }
        if ($app.Name) {
            $name = $app.Name.Replace("Microsoft.", "")
            $name = $name.Replace("Windows.", "")
        }
        if ($name -match "MicrosoftCorporationII.WinAppRuntime.*") {
            $name = $name.Replace("MicrosoftCorporationII.","")
            $name = $name.Replace(".","~")
        }
        # exclude some names here
        if (($name -match "MicrosoftEdge.*") -or ($name -match "Winget.*")) {
            $name = $name.Replace(".","~")
        }
        
        # take last part after the dot as name
        $spl = $name.Split(".")
        $h = $spl.Count - 1
        $name = $spl[$h]

        # Include excluded names
        $name = $name.Replace("~",".")

        # if ($name -eq "Source") { exit}
        
        $Output += [PSCustomObject]@{
            Source      = '3 - Appx (Store)'
            Name        = $name
            Version     = $app.Version
            Vendor      = $lev
            InstallDate = $null # Appx geeft installatie datum vaak niet direct in deze vorm
            InstallLocation = $app.InstallLocation
            
        }
    }
} catch {
    Write-Warning "Fout bij Get-AppxPackage: $_"
}

# Exporteren naar CSV voor analyse
$Output | Sort-Object Name | Export-Csv -Path "C:\Users\ADHC\Downloads\SoftwareInventory_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv" -NoTypeInformation -Encoding UTF8 -Delimiter ';'

Write-Host "Inventory voltooid. Bestand opgeslagen als: SoftwareInventory_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"