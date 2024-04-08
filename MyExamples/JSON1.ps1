cls

$mode = "JSON"

$result = & "D:\Data\Sync ADHC\OneDrive\ADHC Development\Powershell.git\MyExamples\JSON2.ps1" "$Mode"

if ($Mode -eq "JSON") {

    $mylist = ConvertFrom-Json $result
    foreach ($entry in $mylist) {
        write-host $entry.Level " *** " $entry.Message

    }

}
else {

    foreach ($entry in $result) {
        write-host $entry.Level " *** " $entry.Message

    }
}