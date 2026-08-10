$script = "c:\Users\pfapostol\Desktop\Migration Scripts\Random\TzRotate.ps1"

$action = New-ScheduledTaskAction `
    -Execute 'PowerShell.exe' `
    -Argument "-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script`""
    
$trigger = New-ScheduledTaskTrigger -AtStartup

$principal = New-ScheduledTaskPrincipal `
    -UserId 'SYSTEM' `
    -LogonType ServiceAccount `
    -RunLevel Highest

Register-ScheduledTask `
    -TaskName 'Random Timezone' `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Description 'Randomly changes the Windows system timezone.' `
    -Force