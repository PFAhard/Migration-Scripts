# PowerShell 7+
# WingetTools installer
# - Reads toolset.txt from the same folder as this script
# - Installs each winget Id (skips empty lines and lines starting with '#')
# - Uses --source winget to avoid msstore
# - Records ONLY what it actually installed to ./uninstall/WingetTools.state.json
#   so the uninstaller won't remove pre-existing packages.

$ErrorActionPreference = 'Stop'

function Assert-WingetAvailable {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "winget not found in PATH. Install 'App Installer' or ensure winget is available."
    }
}

function Test-WingetIdInstalled {
    param(
        [Parameter(Mandatory)][string]$Id
    )

    $out = & winget list --id $Id --exact --source winget 2>&1
    $text = ($out | Out-String)

    if ($text -match 'No installed package found matching input criteria') { return $false }
    if ($text -match 'No installed package found') { return $false }

    return ($text -match [regex]::Escape($Id))
}

function Get-ToolsetIds {
    param(
        [Parameter(Mandatory)][string]$ToolsetPath
    )

    if (-not (Test-Path -LiteralPath $ToolsetPath)) {
        throw "File not found: $ToolsetPath"
    }

    Get-Content -LiteralPath $ToolsetPath -Encoding UTF8 |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith('#') }
}

function Load-OrInitState {
    param(
        [Parameter(Mandatory)][string]$StatePath
    )

    if (Test-Path -LiteralPath $StatePath) {
        try {
            return (Get-Content -LiteralPath $StatePath -Encoding UTF8 | ConvertFrom-Json)
        } catch {
            throw "Failed to parse state file: $StatePath. $_"
        }
    }

    return [pscustomobject]@{
        createdAt      = (Get-Date).ToString('o')
        lastInstallAt  = $null
        lastUninstallAt= $null
        installs       = @()
    }
}

function Save-State {
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)][string]$StatePath
    )

    $State | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $StatePath -Encoding UTF8
}

function Add-InstallRecord {
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)][string]$Id
    )

    # Avoid duplicate records across multiple runs (idempotent-ish)
    $existing = @($State.installs | Where-Object { $_.id -eq $Id -and -not $_.uninstalledAt })
    if ($existing.Count -gt 0) { return }

    $State.installs += [pscustomobject]@{
        id            = $Id
        installedAt   = (Get-Date).ToString('o')
        uninstalledAt = $null
    }
}

Assert-WingetAvailable

# toolset.txt must be next to this installer script
$toolsetPath = Join-Path $PSScriptRoot 'toolset.txt'
$ids = @(Get-ToolsetIds -ToolsetPath $toolsetPath)

if ($ids.Count -eq 0) {
    Write-Host "No package Ids found in $toolsetPath (after filtering). Nothing to do."
    return
}

# State file stored in ./uninstall relative to this script's folder
$uninstallDir = Join-Path $PSScriptRoot 'uninstall'
New-Item -ItemType Directory -Path $uninstallDir -Force | Out-Null
$statePath = Join-Path $uninstallDir 'WingetTools.state.json'
$state = Load-OrInitState -StatePath $statePath

foreach ($id in $ids) {
    if (Test-WingetIdInstalled -Id $id) {
        Write-Host "Already installed (skipping, not recording): $id"
        continue
    }

    Write-Host "Installing: $id"
    & winget install --id $id --exact --source winget --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        throw "winget failed for Id '$id' (exit code $LASTEXITCODE)"
    }

    Add-InstallRecord -State $state -Id $id
}

$state.lastInstallAt = (Get-Date).ToString('o')
Save-State -State $state -StatePath $statePath

Write-Host "Done. State saved to: $statePath"
