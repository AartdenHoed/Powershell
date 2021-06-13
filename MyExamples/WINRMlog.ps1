Get-WinEvent -ListLog *winrm*

Get-WinEvent -ListLog *winrm* | % {wevtutil.exe cl $_.LogName}

Get-WinEvent -ListLog *winrm* | % {echo y | wevtutil.exe sl $_.LogName /e:true}

Get-WinEvent -ListLog *winrm*  | fl *

(Get-WinEvent -ListLog *winrm*).isenabled