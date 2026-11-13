# ===================== CONFIG =====================

$EthernetPollSeconds = 2
$MaxAttempts          = 3

$Tasks = @(
    @{
        Name              = 'SSH Tunnel'
        ProcessName       = 'ssh-tunnel'
        FilePath          = 'C:\Users\pfapostol\Desktop\ssh-tunnel.exe'
        ArgumentList      = @()
        WorkingDirectory  = 'C:\Users\pfapostol\Desktop'
        Verify            = $true
        VerifyDelaySeconds = 2
    },
    @{
        Name              = 'OpenVPN Connect'
        ProcessName       = 'OpenVPNConnect'
        FilePath          = 'C:\Program Files\OpenVPN Connect\OpenVPNConnect.exe'
        ArgumentList      = @('--connect-shortcut=1787410069335')
        WorkingDirectory  = 'C:\Program Files\OpenVPN Connect'
        Verify            = $true
        VerifyDelaySeconds = 2
    },
    @{
        Name              = 'NetLog'
        ProcessName       = 'netlog-gui'
        FilePath          = 'Z:\rust-target\release\netlog-gui.exe'
        ArgumentList      = @()
        WorkingDirectory  = 'Z:\code\netlog'   # keep original working dir for config files
        Verify            = $true
        VerifyDelaySeconds = 5
        LogFile           = 'Z:\code\netlog\netlog.log'
    },
    # @{
    #     Name              = 'Zapret'
    #     ProcessName       = 'winws'
    #     FilePath          = 'cmd.exe'
    #     ArgumentList      = @('/c', 'preset1_example.cmd')
    #     WorkingDirectory  = 'C:\Users\pfapostol\Desktop\zapret-win-bundle-master\zapret-winws'
    #     Verify            = $false
    # },
    @{
        Name              = 'Unified Remote'
        ProcessName       = 'RemoteServerWin'
        FilePath          = 'C:\Program Files (x86)\Unified Remote 3\RemoteServerWin.exe'
        ArgumentList      = @()
        WorkingDirectory  = 'C:\Program Files (x86)\Unified Remote 3'
        Verify            = $false
    }
)

# ===================== FUNCTIONS =====================

function Wait-ForEthernet {
    Write-Host 'Waiting for Ethernet adapter to connect...'
    while (-not (Get-NetAdapter -Physical -ErrorAction SilentlyContinue |
                 Where-Object { $_.MediaType -eq '802.3' -and $_.Status -eq 'Up' })) {
        Start-Sleep -Seconds $EthernetPollSeconds
    }
    Write-Host 'Ethernet connected.'
}

function Start-ManagedTask {
    param($Task)

    if (Get-Process -Name $Task.ProcessName -ErrorAction SilentlyContinue) {
        Write-Host "$($Task.Name): already running, skipping."
        return $true
    }

    $startArgs = @{
        FilePath         = $Task.FilePath
        ArgumentList     = $Task.ArgumentList
        WorkingDirectory = $Task.WorkingDirectory
        WindowStyle      = 'Hidden'
    }
    if ($Task.LogFile) {
        $startArgs.RedirectStandardOutput = $Task.LogFile
        $startArgs.RedirectStandardError  = $Task.LogFile + '.err'
    }

    if (-not $Task.Verify) {
        Write-Host "$($Task.Name): launching (one-shot, no wait/retry)."
        Start-Process @startArgs
        return $true
    }

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        Write-Host "$($Task.Name): starting (attempt $attempt/$MaxAttempts)..."
        Start-Process @startArgs

        $elapsed = 0
        $found   = $false
        while ($elapsed -lt $Task.VerifyDelaySeconds) {
            Start-Sleep -Seconds 5
            $elapsed += 5
            if (Get-Process -Name $Task.ProcessName -ErrorAction SilentlyContinue) {
                $found = $true
                break
            }
        }

        if ($found) {
            Write-Host "$($Task.Name): started successfully."
            return $true
        }
        Write-Host "$($Task.Name): failed to stay running."
    }

    Write-Host "$($Task.Name): gave up after $MaxAttempts attempts. Aborting script."
    return $false
}

# ===================== MAIN =====================

Wait-ForEthernet

# --- Build NET log first (avoids rustup lock from `cargo run`) ---
Write-Host 'Building Netlog (cargo build -r)...'
Push-Location 'Z:\code\netlog'
cargo build -r
$buildExitCode = $LASTEXITCODE
Pop-Location

if ($buildExitCode -ne 0) {
    Write-Host "Netlog build failed with exit code $buildExitCode. Aborting."
    exit 1
}
Write-Host 'Netlog build succeeded.'

foreach ($task in $Tasks) {
    if (-not (Start-ManagedTask -Task $task)) {
        exit 1
    }
}

Write-Host 'All tasks launched.'