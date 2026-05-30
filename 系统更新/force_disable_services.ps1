$services = @{
    "wuauserv" = 4;
    "UsoSvc" = 4;
    "WaaSMedicSvc" = 4;
    "bits" = 4;
    "dosvc" = 4
}

foreach ($key in $services.Keys) {
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$key"
    try {
        if (Test-Path $regPath) {
            Set-ItemProperty -Path $regPath -Name "Start" -Value $services[$key] -Type DWord -Force
            Write-Host "  $key : Start set to 4 (Disabled)" -ForegroundColor Green
        } else {
            Write-Host "  $key : Registry key not found" -ForegroundColor Red
        }
    } catch {
        Write-Host "  $key : FAILED - $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Stopping services via net stop..."
net stop wuauserv /y 2>$null
net stop UsoSvc /y 2>$null
net stop WaaSMedicSvc /y 2>$null
net stop bits /y 2>$null
net stop dosvc /y 2>$null

Write-Host ""
Write-Host "Verification:"
Get-Service wuauserv,UsoSvc,WaaSMedicSvc,bits,dosvc | Format-Table Name,Status,StartType