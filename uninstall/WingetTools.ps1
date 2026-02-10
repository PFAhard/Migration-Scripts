# PowerShell 7+
# Reads toolset.txt from the same folder as this script and installs each winget Id.
# - Skips empty lines and lines starting with '#'
# - Forces winget source (avoids msstore)
# - Uses exact Id match and accepts agreements to keep migrations non-interactive

$ErrorActionPreference = 'Stop'

$toolsetPath = Join-Path $PSScriptRoot 'toolset.txt'
if (-not (Test-Path -LiteralPath $toolsetPath)) {
    throw "File not found: $toolsetPath"
}

# Basic preflight: ensure winget exists
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget not found in PATH. Install 'App Installer' or ensure winget is available."
}

$ids = Get-Content -LiteralPath $toolsetPath -Encoding UTF8 |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -and -not $_.StartsWith('#') }

foreach ($id in $ids) {
    Write-Host "Installing: $id"
    & winget install --id $id --exact --source winget --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        throw "winget failed for Id '$id' (exit code $LASTEXITCODE)"
    }
}

Write-Host "Done."
