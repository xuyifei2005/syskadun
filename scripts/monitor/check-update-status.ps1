Write-Host '========================================' -ForegroundColor Cyan
Write-Host '  Windows Update Status Check' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''
Write-Host '--- 1. Service Status ---' -ForegroundColor Yellow

$services = @('wuauserv','UsoSvc','WaaSMedicSvc','bits','dosvc')
foreach ($svc in $services) {
    try {
        $s = Get-Service -Name $svc -ErrorAction Stop
        $color = if ($s.Status -eq 'Stopped' -and $s.StartType -eq 'Disabled') { 'Green' } else { 'Red' }
        Write-Host "  [$svc] Status=$($s.Status), StartType=$($s.StartType)" -ForegroundColor $color
    } catch {
        Write-Host "  [$svc] Service not found or inaccessible" -ForegroundColor DarkGray
    }
}

Write-Host ''
Write-Host '--- 2. UpdateOrchestrator Reboot Tasks ---' -ForegroundColor Yellow

$taskPath = '\Microsoft\Windows\UpdateOrchestrator\'
try {
    $rebootTasks = Get-ScheduledTask -TaskPath $taskPath -ErrorAction Stop | Where-Object { $_.TaskName -like '*Reboot*' }
    if ($rebootTasks) {
        foreach ($t in $rebootTasks) {
            $ecolor = if ($t.State -ne 'Disabled') { 'Red' } else { 'Green' }
            Write-Host "  [Reboot] TaskName=$($t.TaskName), State=$($t.State)" -ForegroundColor $ecolor
        }
    } else {
        Write-Host '  No Reboot tasks found' -ForegroundColor Gray
    }
} catch {
    Write-Host "  Cannot access task path: $_" -ForegroundColor Red
}

Write-Host ''
Write-Host '--- 3. Registry Policies ---' -ForegroundColor Yellow

$regPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
try {
    if (Test-Path $regPath) {
        $noAuto = Get-ItemProperty -Path $regPath -Name 'NoAutoUpdate' -ErrorAction SilentlyContinue
        $auOpt = Get-ItemProperty -Path $regPath -Name 'AUOptions' -ErrorAction SilentlyContinue
        if ($noAuto.NoAutoUpdate -eq 1) { Write-Host '  [NoAutoUpdate] = 1 (Configured - No auto update)' -ForegroundColor Green } else { Write-Host '  [NoAutoUpdate] = NOT configured or NOT 1' -ForegroundColor Red }
        if ($auOpt.AUOptions -eq 1) { Write-Host '  [AUOptions] = 1 (Never check for updates)' -ForegroundColor Green } else { Write-Host '  [AUOptions] = NOT configured or NOT 1' -ForegroundColor Red }
    } else {
        Write-Host '  [AU] Registry path does NOT exist - policy NOT configured' -ForegroundColor Red
    }
} catch {
    Write-Host "  Registry read failed: $_" -ForegroundColor Red
}

$pausePath = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
try {
    if (Test-Path $pausePath) {
        $pauseVal = Get-ItemProperty -Path $pausePath -Name 'PauseUpdatesExpiryTime' -ErrorAction SilentlyContinue
        if ($pauseVal.PauseUpdatesExpiryTime) {
            $expiry = [DateTime]::Parse($pauseVal.PauseUpdatesExpiryTime)
            if ($expiry -gt (Get-Date)) {
                Write-Host "  [PauseUpdatesExpiryTime] = $($pauseVal.PauseUpdatesExpiryTime) (Paused - ACTIVE)" -ForegroundColor Green
            } else {
                Write-Host "  [PauseUpdatesExpiryTime] = $($pauseVal.PauseUpdatesExpiryTime) (EXPIRED!)" -ForegroundColor Red
            }
        } else {
            Write-Host '  [PauseUpdatesExpiryTime] NOT configured' -ForegroundColor Red
        }
    } else {
        Write-Host '  [UX\Settings] Path does NOT exist' -ForegroundColor Red
    }
} catch {
    Write-Host "  Registry read failed: $_" -ForegroundColor Red
}

Write-Host ''
Write-Host '--- 4. Recent Update-related Restarts ---' -ForegroundColor Yellow
try {
    $restartEvents = Get-WinEvent -LogName System -FilterXPath '*[System[EventID=1074]]' -MaxEvents 5 -ErrorAction Stop | Where-Object { $_.Message -like '*Update*' -or $_.Message -like '*更新*' }
    if ($restartEvents) {
        foreach ($e in $restartEvents) {
            Write-Host "  [Restart Event] Time=$($e.TimeCreated)" -ForegroundColor Yellow
            $firstLine = ($e.Message -split "`r`n")[0]
            Write-Host "    Message=$firstLine" -ForegroundColor Gray
        }
    } else {
        Write-Host '  No update-related restart events found' -ForegroundColor Green
    }
} catch {
    Write-Host "  Event log query failed: $_" -ForegroundColor DarkGray
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host '  CHECK COMPLETE' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan