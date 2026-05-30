$host.UI.RawUI.WindowTitle = "Disable Win11 Update"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Completely Disable Windows 11 Auto Update" -ForegroundColor Cyan
Write-Host "  (including UpdateOrchestrator reboot tasks)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Continue"

# ============================================================
# Step 1: Stop and disable all update-related services
# ============================================================
Write-Host "[1/4] Stopping and disabling update services..." -ForegroundColor Yellow

$services = @(
    "wuauserv",
    "UsoSvc",
    "WaaSMedicSvc",
    "bits",
    "dosvc"
)

foreach ($svc in $services) {
    try {
        Write-Host "  Stopping $svc ..." -ForegroundColor Gray
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue

        Write-Host "  Disabling $svc ..." -ForegroundColor Gray
        Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue

        $status = (Get-Service -Name $svc -ErrorAction SilentlyContinue).Status
        $startMode = (Get-Service -Name $svc -ErrorAction SilentlyContinue).StartType
        Write-Host "  $svc : Status=$status, StartMode=$startMode" -ForegroundColor Green
    } catch {
        Write-Host "  $svc : FAILED - $_" -ForegroundColor Red
    }
}

# ============================================================
# Step 2: Registry policies
# ============================================================
Write-Host ""
Write-Host "[2/4] Setting registry policies..." -ForegroundColor Yellow

$regPolicies = @(
    @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"; Name="NoAutoUpdate"; Value=1; Type="DWord"},
    @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"; Name="AUOptions"; Value=1; Type="DWord"},
    @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"; Name="ScheduledInstallDay"; Value=0; Type="DWord"},
    @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"; Name="ScheduledInstallTime"; Value=3; Type="DWord"},
    @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"; Name="ExcludeWUDriversInQualityUpdate"; Value=1; Type="DWord"},
    @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching"; Name="SearchOrderConfig"; Value=0; Type="DWord"},
    @{Path="HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"; Name="PauseUpdatesExpiryTime"; Value="2033-12-31T23:59:59Z"; Type="String"},
    @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"; Name="DODownloadMode"; Value=0; Type="DWord"},
    @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"; Name="DisableWindowsConsumerFeatures"; Value=1; Type="DWord"},
    @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"; Name="TargetReleaseVersion"; Value=1; Type="DWord"},
    @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"; Name="TargetReleaseVersionInfo"; Value="23H2"; Type="String"}
)

foreach ($policy in $regPolicies) {
    try {
        if (-not (Test-Path $policy.Path)) {
            New-Item -Path $policy.Path -Force -ErrorAction SilentlyContinue | Out-Null
        }
        Set-ItemProperty -Path $policy.Path -Name $policy.Name -Value $policy.Value -Type $policy.Type -Force -ErrorAction SilentlyContinue
        Write-Host "  Set: $($policy.Path)\$($policy.Name) = $($policy.Value)" -ForegroundColor Gray
    } catch {
        Write-Host "  FAILED: $($policy.Path)\$($policy.Name) - $_" -ForegroundColor Red
    }
}

# ============================================================
# Step 3: Disable UpdateOrchestrator scheduled tasks
# ============================================================
Write-Host ""
Write-Host "[3/4] Disabling UpdateOrchestrator reboot tasks..." -ForegroundColor Yellow

$tasks = @(
    "\Microsoft\Windows\WindowsUpdate\Automatic App Update",
    "\Microsoft\Windows\WindowsUpdate\Scheduled Start",
    "\Microsoft\Windows\WindowsUpdate\sih",
    "\Microsoft\Windows\WindowsUpdate\sihboot",
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan",
    "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker",
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan Static Task",
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Retry Scan",
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Wake To Work",
    "\Microsoft\Windows\UpdateOrchestrator\UpdateModelTask",
    "\Microsoft\Windows\UpdateOrchestrator\Reboot",
    "\Microsoft\Windows\UpdateOrchestrator\Reboot_AC",
    "\Microsoft\Windows\UpdateOrchestrator\Reboot_Battery",
    "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker_Display",
    "\Microsoft\Windows\UpdateOrchestrator\Maintenance Install",
    "\Microsoft\Windows\UpdateOrchestrator\Policy Install",
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Work",
    "\Microsoft\Windows\UpdateOrchestrator\Report policies",
    "\Microsoft\Windows\UpdateOrchestrator\MusUx_LogonUpdateResults",
    "\Microsoft\Windows\UpdateOrchestrator\Start Oobe Expedite Work",
    "\Microsoft\Windows\UpdateOrchestrator\Start Backup Scan",
    "\Microsoft\Windows\UpdateOrchestrator\Start Install"
)

foreach ($task in $tasks) {
    try {
        $taskPath = Split-Path $task
        $taskName = Split-Path $task -Leaf
        $schTask = Get-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction SilentlyContinue
        if ($schTask) {
            $prevState = $schTask.State
            Disable-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction SilentlyContinue
            Write-Host "  Disabled: $task (was $prevState)" -ForegroundColor Gray
        } else {
            Write-Host "  Not found: $task" -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "  Not found: $task" -ForegroundColor DarkGray
    }
}

# ============================================================
# Step 4: Verify results
# ============================================================
Write-Host ""
Write-Host "[4/4] Verifying results..." -ForegroundColor Yellow
Write-Host ""

Write-Host "--- Service Status ---" -ForegroundColor Cyan
foreach ($svc in @("wuauserv", "UsoSvc", "WaaSMedicSvc", "bits", "dosvc")) {
    try {
        $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($s) {
            $color = if ($s.StartType -eq "Disabled") { "Green" } else { "Red" }
            Write-Host "  $svc : Status=$($s.Status)  StartMode=$($s.StartType)" -ForegroundColor $color
        } else {
            Write-Host "  $svc : Not found" -ForegroundColor Red
        }
    } catch {
        Write-Host "  $svc : Query failed" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "--- Registry ---" -ForegroundColor Cyan
$auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
if (Test-Path $auPath) {
    $noAuto = (Get-ItemProperty -Path $auPath -Name "NoAutoUpdate" -ErrorAction SilentlyContinue).NoAutoUpdate
    $color1 = if ($noAuto -eq 1) { "Green" } else { "Red" }
    Write-Host "  NoAutoUpdate = $noAuto (1=Disabled)" -ForegroundColor $color1
} else {
    Write-Host "  NoAutoUpdate not set" -ForegroundColor Red
}

Write-Host ""
Write-Host "--- Reboot Tasks ---" -ForegroundColor Cyan
try {
    $reboot = Get-ScheduledTask -TaskName "Reboot" -TaskPath "\Microsoft\Windows\UpdateOrchestrator\" -ErrorAction SilentlyContinue
    if ($reboot) {
        $color2 = if ($reboot.State -eq "Disabled") { "Green" } else { "Red" }
        Write-Host "  Reboot task State: $($reboot.State)" -ForegroundColor $color2
    } else {
        Write-Host "  Reboot task does not exist" -ForegroundColor Green
    }
} catch {
    Write-Host "  Reboot task does not exist" -ForegroundColor Green
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  DONE! All updates disabled." -ForegroundColor Green
Write-Host "  Suggest restarting PC to fully apply changes." -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan

pause