$ErrorActionPreference = "SilentlyContinue"
Remove-Item "HKCU:\Software\Classes\*\shell\OpenWithVSCode" -Recurse -Force
Remove-Item "HKCU:\Software\Classes\Directory\shell\OpenWithVSCode" -Recurse -Force
Remove-Item "HKCU:\Software\Classes\Directory\Background\shell\OpenWithVSCode" -Recurse -Force
Write-Host "Removed VS Code context-menu entries."
