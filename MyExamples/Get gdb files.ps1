﻿$TotalList = Get-ChildItem "C:\Data\Sync Gedeeld\Vakanties\" -Recurse -File -Filter *.gdb | Select-Object Name,Fullname,Extension