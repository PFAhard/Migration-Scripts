# PowerShell 7+
# Uninstalls only packages previously installed by your winget installer script.
# Does NOT touch packages that were already present before your install run.

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

    # winget list output varies by version; we do a conservative text check.
    $out = & winget list --id $Id --exact --source winget 2>&1
    $text = ($out | Out-String)

    if ($text -match 'No installed package found matching input criteria') { return $false }
    if ($text -match 'No installed package found') { return $false }

    # Heuristic: if the exact Id appears in the table, treat as installed.
    # (winget tends to print a row containing the Id)
    return ($text -match [regex]::Escape($Id))
}

function Invoke-WingetUninstallExact {
    param(
        [Parameter(Mandatory)][string]$Id
    )

    Write-Host "Uninstalling: $Id"
    & winget uninstall --id $Id --exact --source winget
    $code = $LASTEXITCODE
    if ($code -ne 0) {
        throw "winget uninstall failed for Id '$Id' (exit code $code)"
    }
}

Assert-WingetAvailable

$statePath = Join-Path $PSScriptRoot 'WingetTools.state.json'
if (-not (Test-Path -LiteralPath $statePath)) {
    Write-Host "State file not found: $statePath"
    Write-Host "Nothing to uninstall (safe no-op)."
    return
}

$state = Get-Content -LiteralPath $statePath -Encoding UTF8 | ConvertFrom-Json

if (-not $state.installs) {
    Write-Host "State file has no installs recorded. Nothing to uninstall."
    return
}

# Uninstall only entries that were installed by the script and not yet uninstalled.
$toRemove = @($state.installs | Where-Object { $_.id -and -not $_.uninstalledAt })

if ($toRemove.Count -eq 0) {
    Write-Host "No recorded packages pending uninstall."
    return
}

foreach ($entry in $toRemove) {
    $id = [string]$entry.id

    if (-not (Test-WingetIdInstalled -Id $id)) {
        Write-Host "Not installed (skipping): $id"
        $entry.uninstalledAt = (Get-Date).ToString('o')
        continue
    }

    Invoke-WingetUninstallExact -Id $id
    $entry.uninstalledAt = (Get-Date).ToString('o')
}

# Persist updated state (keeps history)
$state.lastUninstallAt = (Get-Date).ToString('o')
$state | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $statePath -Encoding UTF8

Write-Host "Done."
