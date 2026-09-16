cd c:\
$a = Get-ChildItem "C:\Data\Sync Gedeeld\Vakanties\" -recurse -file | Select Name,FullName | `
                                    Where-Object {($_.FullName.ToUpper() -like "*.MP3") }  | Sort-Object -Property Name -Unique
$a.Count
$a | Out-GridView -PassThru | Export-Csv "C:\Data\Sync Gedeeld\Vakanties\VakantieMuziekNummers.csv" -NoTypeInformation -Delimiter "~"
