cd c:\
$a = Get-ChildItem "c:\" -recurse -file -dir  -force | `
                                    Where-Object {($_.FullName -like "*.ssh*") } 
$a | Out-GridView