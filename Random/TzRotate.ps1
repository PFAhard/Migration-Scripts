$timezones = Get-TimeZone -ListAvailable
while ($true) {
    $delay = Get-Random -Minimum 13 -Maximum 322
    Start-Sleep -Seconds $delay
    $timezone = Get-Random -InputObject $timezones
    Set-TimeZone -Id $timezone.Id
}