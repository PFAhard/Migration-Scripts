# PowerShell 7+
# Increase Jump List size (taskbar right-click recent items)

param(
    [ValidateRange(0, 150)]
    [int]$MaxItems = 30,

    [switch]$RestartExplorer
)

$ErrorActionPreference = 'Stop'

$regPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
$name    = 'JumpListItems_Maximum'

# Write or overwrite value ONLY (no key creation)
Set-ItemProperty -Path $regPath -Name $name -Type DWord -Value $MaxItems

Write-Host "Set JumpListItems_Maximum = $MaxItems"

if ($RestartExplorer) {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Process explorer.exe
    Write-Host "Explorer restarted."
}
