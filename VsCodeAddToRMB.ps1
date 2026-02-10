# PowerShell 7+
$ErrorActionPreference = "Stop"

function Get-VSCodePath {
    $candidates = @(
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",  # User install
        "$env:ProgramFiles\Microsoft VS Code\Code.exe",          # System install (64-bit)
        "${env:ProgramFiles(x86)}\Microsoft VS Code\Code.exe"    # System install (32-bit)
    )
    foreach ($p in $candidates) {
        if (Test-Path $p) { return $p }
    }
    throw "VS Code not found. Install it first, or adjust paths in Get-VSCodePath."
}

$codeExe = Get-VSCodePath

# Registry base (current user only)
$classes = "HKCU:\Software\Classes"

# 1) Files: right-click any file -> Open with VS Code
New-Item -Path "$classes\*\shell\OpenWithVSCode" -Force | Out-Null
New-ItemProperty -Path "$classes\*\shell\OpenWithVSCode" -Name "(default)" -Value "Open with VS Code" -PropertyType String -Force | Out-Null
New-ItemProperty -Path "$classes\*\shell\OpenWithVSCode" -Name "Icon" -Value "`"$codeExe`"" -PropertyType String -Force | Out-Null
New-Item -Path "$classes\*\shell\OpenWithVSCode\command" -Force | Out-Null
New-ItemProperty -Path "$classes\*\shell\OpenWithVSCode\command" -Name "(default)" -Value "`"$codeExe`" `"%1`"" -PropertyType String -Force | Out-Null

# 2) Folders: right-click a folder -> Open with VS Code
New-Item -Path "$classes\Directory\shell\OpenWithVSCode" -Force | Out-Null
New-ItemProperty -Path "$classes\Directory\shell\OpenWithVSCode" -Name "(default)" -Value "Open with VS Code" -PropertyType String -Force | Out-Null
New-ItemProperty -Path "$classes\Directory\shell\OpenWithVSCode" -Name "Icon" -Value "`"$codeExe`"" -PropertyType String -Force | Out-Null
New-Item -Path "$classes\Directory\shell\OpenWithVSCode\command" -Force | Out-Null
New-ItemProperty -Path "$classes\Directory\shell\OpenWithVSCode\command" -Name "(default)" -Value "`"$codeExe`" `"%1`"" -PropertyType String -Force | Out-Null

# 3) Folder background: right-click empty area inside a folder -> Open with VS Code here
New-Item -Path "$classes\Directory\Background\shell\OpenWithVSCode" -Force | Out-Null
New-ItemProperty -Path "$classes\Directory\Background\shell\OpenWithVSCode" -Name "(default)" -Value "Open with VS Code" -PropertyType String -Force | Out-Null
New-ItemProperty -Path "$classes\Directory\Background\shell\OpenWithVSCode" -Name "Icon" -Value "`"$codeExe`"" -PropertyType String -Force | Out-Null
New-Item -Path "$classes\Directory\Background\shell\OpenWithVSCode\command" -Force | Out-Null
New-ItemProperty -Path "$classes\Directory\Background\shell\OpenWithVSCode\command" -Name "(default)" -Value "`"$codeExe`" `"%V`"" -PropertyType String -Force | Out-Null

Write-Host "Added classic context-menu entries for VS Code (HKCU)."
