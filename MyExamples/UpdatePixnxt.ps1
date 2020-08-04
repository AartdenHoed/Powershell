$file = $args[0]
$title = $args[1]

Add-Type -path "${env:ProgramFiles(x86)}\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.5\PresentationCore.dll"
$fs = New-Object System.IO.FileStream($file, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
$decoder = New-Object System.Windows.Media.Imaging.JpegBitmapDecoder(
    $fs, 
    [System.Windows.Media.Imaging.BitmapCreateOptions]::PreservePixelFormat,
    [System.Windows.Media.Imaging.BitmapCacheOption]::Default)

$frame = [System.Windows.Media.Imaging.BitmapFrame]::Create($decoder.Frames[0])
$metadata = [System.Windows.Media.Imaging.BitmapMetadata]$frame.Metadata
$metadata.Title = $title

$encoder = New-Object System.Windows.Media.Imaging.JpegBitmapEncoder
$encoder.Frames.Add($frame)
$tempfile = $args[0] + "___temp"
$fsout = New-Object System.IO.FileStream($tempfile, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
$encoder.Save($fsout)
$fsout.Dispose()
$fs.Dispose()

copy $tempfile $file