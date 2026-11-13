$adapter = Get-NetAdapter -Name "Ethernet"
$statusNow = $adapter.Status

$stateFile = "C:\Users\pfapostol\Desktop\Migration Scripts\Startup\eth-state.txt"
$lastState = if (Test-Path $stateFile) { Get-Content $stateFile } else { "Unknown" }

$procRunning = Get-Process -Name "ssh-tunnel" -ErrorAction SilentlyContinue

if ($statusNow -eq "Up" -and ($lastState -ne "Up" -or -not $procRunning)) {
    Get-Process -Name "ssh-tunnel" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Process "C:\Users\pfapostol\Desktop\ssh-tunnel.exe"
}

Set-Content -Path $stateFile -Value $statusNow