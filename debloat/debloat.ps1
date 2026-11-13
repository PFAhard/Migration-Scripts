<#
    debloat.ps1
    Reproduces every service/task/registry change made in the "DNS spam cleanup" session.
    Run elevated (Right-click -> Run with PowerShell as Administrator).

    Assumptions baked in from that session (adjust if your setup differs on a fresh install):
      - Bluetooth: used -> Bluetooth services left alone
      - BitLocker: not used
      - No printer/scanner
      - No WSL
      - Local account only, not domain-joined
      - No Xbox/gaming features
      - No cellular/mobile hardware
      - Uses Hyper-V (vmms/vmcompute) -> SharedAccess (ICS) deliberately NOT disabled
      - Updates Defender definitions manually (nis_full.exe / mpam-fe.exe) -> cloud reporting off
      - Installs Windows updates manually via UUP dump -> wuauserv disabled
#>

#Requires -RunAsAdministrator

Write-Host "=== 1. Disabling services ===" -ForegroundColor Cyan

$services = @(
    "DiagTrack",
    "NVDisplay.ContainerLocalSystem",
    "CDPSvc",
    "wuauserv",
    "wuqisvc","WerSvc","wercplsupport","InventorySvc","PcaSvc","diagsvc","RetailDemo","wisvc",
    "ADPSvc","cloudidsvc","wlidsvc","dmwappushservice","WSAIFabricSvc","WbioSrvc",
    "XblAuthManager","XblGameSave","XboxGipSvc","XboxNetApiSvc",
    "PhoneSvc","autotimesvc","WwanSvc","icssvc","SEMgrSvc","WalletService",
    "SensorDataService","SensorService","SensrSvc","lfsvc","MapsBroker","TapiSrv",
    "webthreatdefsvc","PushToInstall",
    "BDESVC","WEPHOSTSVC",
    "Spooler","PrintNotify","PrintDeviceConfigurationService","PrintScanBrokerService",
    "CscService","Netlogon",
    "SNMPTrap","SstpSvc","SmsRouter","wcncsvc","lltdsvc","MSiSCSI","RasAuto","DsSvc","fhsvc","TrkWks"
    # NOTE: SharedAccess (ICS) intentionally excluded - required by Hyper-V default switch NAT.
    # NOTE: NVDisplay.ContainerLocalSystem also disables GeForce Experience overlay/Shadowplay/Ansel.
)

foreach ($s in $services) {
    Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
    Set-Service -Name $s -StartupType Disabled -ErrorAction SilentlyContinue
}

Write-Host "=== 2. Fixing trigger-start / per-user template services via registry ===" -ForegroundColor Cyan

# These ignore Set-Service because they're trigger-start or per-user service templates.
# Using base template names (no _<SID suffix>) so this survives a fresh install/new user SID.
$registryStartFix = @(
    "NgcSvc",
    "NgcCtnrSvc",
    "EntAppSvc",
    "webthreatdefusersvc",
    "PimIndexMaintenanceSvc",
    "PrintWorkflowUserSvc",
    "P9RdrService"
)

foreach ($svc in $registryStartFix) {
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$svc"
    if (Test-Path $regPath) {
        Set-ItemProperty -Path $regPath -Name "Start" -Value 4 -ErrorAction SilentlyContinue
    }
}

# Best-effort: stop any already-running per-user CDP instance (parent CDPSvc is disabled above,
# so it won't do anything meaningful even though it respawns per login).
Get-Service -Name "CDPUserSvc_*" -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction SilentlyContinue

Write-Host "=== 3. Disabling scheduled tasks ===" -ForegroundColor Cyan

$tasks = @(
    @{Path="\Microsoft\Windows\Application Experience\"; Name="Microsoft Compatibility Appraiser Exp"},
    @{Path="\Microsoft\Windows\Application Experience\"; Name="PcaPatchDbTask"},
    @{Path="\Microsoft\Windows\Customer Experience Improvement Program\"; Name="Consolidator"},
    @{Path="\Microsoft\Windows\Customer Experience Improvement Program\"; Name="UsbCeip"},
    @{Path="\Microsoft\Windows\DiskDiagnostic\"; Name="Microsoft-Windows-DiskDiagnosticDataCollector"},
    @{Path="\Microsoft\Windows\Diagnosis\"; Name="UnexpectedCodepath"},
    @{Path="\Microsoft\Windows\Diagnosis\"; Name="RecommendedTroubleshootingScanner"},
    @{Path="\Microsoft\Windows\Diagnosis\"; Name="Scheduled"},
    @{Path="\Microsoft\Windows\Feedback\Siuf\"; Name="DmClient"},
    @{Path="\Microsoft\Windows\Feedback\Siuf\"; Name="DmClientOnScenarioDownload"},
    @{Path="\Microsoft\Windows\Flighting\FeatureConfig\"; Name="UsageDataReporting"},
    @{Path="\Microsoft\Windows\Flighting\FeatureConfig\"; Name="UsageDataFlushing"},
    @{Path="\Microsoft\Windows\Flighting\FeatureConfig\"; Name="SafeguardsReconciliation"},
    @{Path="\Microsoft\Windows\Flighting\FeatureConfig\"; Name="UsageDataReceiver"},
    @{Path="\Microsoft\Windows\Flighting\FeatureConfig\"; Name="ReconcileConfigs"},
    @{Path="\Microsoft\Windows\Flighting\FeatureConfig\"; Name="GovernedFeatureUsageProcessing"},
    @{Path="\Microsoft\Windows\Flighting\FeatureConfig\"; Name="ReconcileFeatures"},
    @{Path="\Microsoft\Windows\Flighting\OneSettings\"; Name="RefreshCache"},
    @{Path="\Microsoft\Windows\Sustainability\"; Name="SustainabilityTelemetry"},
    @{Path="\Microsoft\Windows\Sustainability\"; Name="PowerGridForecastTask"},
    @{Path="\Microsoft\Windows\UsageAndQualityInsights\"; Name="UsageAndQualityInsights-MaintenanceTask"},
    @{Path="\Microsoft\Windows\Windows Error Reporting\"; Name="QueueReporting"},
    @{Path="\Microsoft\Windows\PerformanceTrace\"; Name="ShowFeedbackToast"},
    @{Path="\Microsoft\Windows\PerformanceTrace\"; Name="WhesvcToast"},
    @{Path="\Microsoft\Windows\WindowsAI\ClickToDo\"; Name="ModelCachingLimit"},
    @{Path="\Microsoft\Windows\WindowsAI\ClickToDo\"; Name="ModelCachingUpdate"},
    @{Path="\Microsoft\Windows\WindowsAI\Recall\"; Name="PolicyConfiguration"},
    @{Path="\Microsoft\Windows\WindowsAI\Settings\"; Name="InitialConfiguration"},
    @{Path="\Microsoft\Windows\BitLocker\"; Name="BitLocker Encrypt All Drives"},
    @{Path="\Microsoft\Windows\BitLocker\"; Name="BitLocker MDM policy Refresh"},
    @{Path="\Microsoft\Windows\Printing\"; Name="EduPrintProv"},
    @{Path="\Microsoft\Windows\Printing\"; Name="PrinterCleanupTask"},
    @{Path="\Microsoft\Windows\AppID\"; Name="EDP Policy Manager"},
    @{Path="\Microsoft\Windows\EDP\"; Name="EDP Inaccessible Credentials Task"},
    @{Path="\Microsoft\Windows\EDP\"; Name="StorageCardEncryption Task"},
    @{Path="\Microsoft\Windows\EDP\"; Name="EDP App Launch Task"},
    @{Path="\Microsoft\Windows\EDP\"; Name="EDP Auth Task"},
    @{Path="\Microsoft\Windows\EnterpriseMgmt\"; Name="MDMMaintenenceTask"},
    @{Path="\Microsoft\Windows\Active Directory Rights Management Services Client\"; Name="AD RMS Rights Policy Template Management (Manual)"},
    @{Path="\Microsoft\Windows\Management\Provisioning\"; Name="Cellular"},
    @{Path="\Microsoft\Windows\WwanSvc\"; Name="NotificationTask"},
    @{Path="\Microsoft\Windows\WwanSvc\"; Name="OobeDiscovery"},
    @{Path="\Microsoft\Windows\Shell\"; Name="FamilySafetyMonitor"},
    @{Path="\Microsoft\Windows\Shell\"; Name="FamilySafetyRefreshTask"},
    @{Path="\Microsoft\Windows\PushToInstall\"; Name="LoginCheck"},
    @{Path="\Microsoft\Windows\PushToInstall\"; Name="Registration"},
    @{Path="\Microsoft\Windows\Maps\"; Name="MapsToastTask"},
    @{Path="\Microsoft\Windows\Speech\"; Name="SpeechModelDownloadTask"},
    @{Path="\Microsoft\Windows\RemoteAssistance\"; Name="RemoteAssistanceTask"},
    @{Path="\Microsoft\Windows\FileHistory\"; Name="File History (maintenance mode)"}
)

foreach ($t in $tasks) {
    Disable-ScheduledTask -TaskPath $t.Path -TaskName $t.Name -ErrorAction SilentlyContinue | Out-Null
}

Write-Host "=== 4. Disabling TrustedInstaller-protected tasks via SYSTEM helper ===" -ForegroundColor Cyan

$protectedTasks = @(
    '\Microsoft\Windows\BitLocker\BitLocker Encrypt All Drives',
    '\Microsoft\Windows\BitLocker\BitLocker MDM policy Refresh',
    '\Microsoft\Windows\EDP\EDP App Launch Task',
    '\Microsoft\Windows\EDP\EDP Auth Task',
    '\Microsoft\Windows\EDP\EDP Inaccessible Credentials Task',
    '\Microsoft\Windows\EDP\StorageCardEncryption Task',
    '\Microsoft\Windows\UsageAndQualityInsights\UsageAndQualityInsights-MaintenanceTask',
    '\Microsoft\Windows\WindowsAI\ClickToDo\ModelCachingLimit',
    '\Microsoft\Windows\WindowsAI\ClickToDo\ModelCachingUpdate',
    '\Microsoft\Windows\WindowsAI\Recall\PolicyConfiguration',
    '\Microsoft\Windows\WindowsAI\Settings\InitialConfiguration'
)

$bat = "$env:TEMP\disable_tasks.bat"
$lines = "@echo off`r`n"
foreach ($tn in $protectedTasks) {
    $lines += "schtasks /Change /TN `"$tn`" /Disable`r`n"
}
$lines | Out-File -FilePath $bat -Encoding ascii

$action = New-ScheduledTaskAction -Execute $bat
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName "TempDisableHelper" -Action $action -Principal $principal -Force | Out-Null
Start-ScheduledTask -TaskName "TempDisableHelper"
Start-Sleep -Seconds 3
Unregister-ScheduledTask -TaskName "TempDisableHelper" -Confirm:$false
Remove-Item $bat -ErrorAction SilentlyContinue

Write-Host "=== 5. Registry policies ===" -ForegroundColor Cyan

New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Force | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Name "AutoDownload" -Value 2 -PropertyType DWORD -Force | Out-Null

New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Force | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "MetricsReportingEnabled" -Value 0 -PropertyType DWORD -Force | Out-Null

New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DisableOneSettingsDownloads" -Value 1 -PropertyType DWORD -Force | Out-Null

New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting" -Force | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting" -Name "DisableGenericReports" -Value 1 -PropertyType DWORD -Force | Out-Null

New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Force | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -PropertyType DWORD -Force | Out-Null

New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate" -Force | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate" -Name "UpdateDefault" -Value 0 -PropertyType DWORD -Force | Out-Null

Set-MpPreference -MAPSReporting Disabled -ErrorAction SilentlyContinue

Write-Host "=== Done. Reboot recommended. ===" -ForegroundColor Green