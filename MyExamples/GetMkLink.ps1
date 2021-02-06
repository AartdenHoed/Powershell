$a = Get-ChildItem -Path C:\ -Force -Recurse -ErrorAction 'silentlycontinue' | 
  Where { $_.Attributes -match "ReparsePoint"}
$a | Out-GridView

# of
# Command
dir /AL /S C:\ | find "SYMLINK"
