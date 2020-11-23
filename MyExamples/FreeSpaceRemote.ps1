$dr = get-WmiObject win32_logicaldisk -Computername adhc

foreach ($drive in $dr)  {
    if ($drive.DriveType -eq "3") {
        $did = $drive.DeviceID
        $name = $drive.VolumeName
        $size = $drive.Size/(1024 * 1024 * 1024)
        $freesp = $drive.FreeSpace  / (1024 * 1024 *1024)
        $freeperc = $freesp / $size * 100
        Write-Host "Drive $did ($name) has drivetype 3"
        Write-Host "Size (GB) = $size, freespace (GB) = $freesp, percentage free = $freeperc"
    }

}