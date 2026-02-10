# --- Add near the top of installer ---
$repoRoot = $PSScriptRoot   # if installer sits in repo root; adjust if not
$uninstallDir = Join-Path $repoRoot 'uninstall'
New-Item -ItemType Directory -Path $uninstallDir -Force | Out-Null
$statePath = Join-Path $uninstallDir 'WingetTools.state.json'

function Test-WingetIdInstalled {
    param([Parameter(Mandatory)][string]$Id)
    $out = & winget list --id $Id --exact --source winget 2>&1
    $text = ($out | Out-String)
    if ($text -match 'No installed package found') { return $false }
    return ($text -match [regex]::Escape($Id))
}

# Load or init state
if (Test-Path -LiteralPath $statePath) {
    $state = Get-Content -LiteralPath $statePath -Encoding UTF8 | ConvertFrom-Json
} else {
    $state = [pscustomobject]@{
        createdAt        = (Get-Date).ToString('o')
        lastInstallAt     = $null
        lastUninstallAt   = $null
        installs          = @()
    }
}

# --- In your foreach ($id in $ids) loop, wrap install like this ---
if (Test-WingetIdInstalled -Id $id) {
    Write-Host "Already installed (not recording): $id"
} else {
    Write-Host "Installing: $id"
    & winget install --id $id --exact --source winget --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) { throw "winget failed for Id '$id' (exit code $LASTEXITCODE)" }

    # record only what we actually added
    $state.installs += [pscustomobject]@{
        id           = $id
        installedAt  = (Get-Date).ToString('o')
        uninstalledAt= $null
    }
}

# --- At end of installer ---
$state.lastInstallAt = (Get-Date).ToString('o')
$state | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $statePath -Encoding UTF8
