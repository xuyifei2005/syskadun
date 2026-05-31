# ============================================
# Restore Windows Update - Complete Recovery
# Run as Administrator!
# ============================================

$host.UI.RawUI.WindowTitle = "Restoring Windows Update..."

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   Windows Update - Full Restore" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# ===========================================
# STEP 1: Restore services to default start types
# ===========================================
Write-Host "  [1/4] Restoring service startup types..." -ForegroundColor Yellow

$serviceDefaults = @{
    "wuauserv"     = "3"   # Manual (Trigger Start)
    "UsoSvc"       = "2"   # Automatic (Delayed Start)
    "WaaSMedicSvc" = "3"   # Manual
    "bits"         = "3"   # Manual (Demand Start)
    "dosvc"        = "3"   # Manual
}

foreach ($svc in $serviceDefaults.Keys) {
    $startType = $serviceDefaults[$svc]
    
    # Use reg.exe for reliability
    cmd /c "reg.exe add HKLM\SYSTEM\CurrentControlSet\Services\$svc /v Start /t REG_DWORD /d $startType /f"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    $svc : Start=$startType (Restored)" -ForegroundColor Green
        
        # Also try sc.exe for consistency
        $scStart = switch ($startType) { "2" { "auto" } "3" { "demand" } default { "demand" } }
        cmd /c "sc.exe config $svc start= $scStart" | Out-Null
    } else {
        Write-Host "    $svc : FAILED to restore" -ForegroundColor Red
    }
}

# ===========================================
# STEP 2: Remove registry policies
# ===========================================
Write-Host ""
Write-Host "  [2/4] Removing Windows Update policies..." -ForegroundColor Yellow

$policiesToRemove = @(
    @{Path="HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"; Name="AUOptions"},
    @{Path="HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"; Name="NoAutoUpdate"},
    @{Path="HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"; Name="NoAutoRebootWithLoggedOnUsers"},
    @{Path="HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"; Name="DisableOSUpgrade"},
    @{Path="HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"; Name="WUServer"},
    @{Path="HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"; Name="WUStatusServer"}
)

foreach ($policy in $policiesToRemove) {
    cmd /c "reg.exe delete $($policy.Path) /v $($policy.Name) /f"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    Removed: $($policy.Name)" -ForegroundColor Green
    } else {
        Write-Host "    Skipped: $($policy.Name) (not present)" -ForegroundColor DarkGray
    }
}

# Remove pause
cmd /c "reg.exe delete HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings /v PauseUpdatesExpiryTime /f"
if ($LASTEXITCODE -eq 0) {
    Write-Host "    Removed: PauseUpdatesExpiryTime (updates unpaused)" -ForegroundColor Green
} else {
    Write-Host "    Skipped: PauseUpdatesExpiryTime (not present)" -ForegroundColor DarkGray
}

# ===========================================
# STEP 3: Enable scheduled tasks
# ===========================================
Write-Host ""
Write-Host "  [3/4] Enabling scheduled tasks..." -ForegroundColor Yellow

$tasksEnabled = 0
$tasks = @(
    @{Path="\Microsoft\Windows\WindowsUpdate"; Name="Automatic App Update"},
    @{Path="\Microsoft\Windows\WindowsUpdate"; Name="Scheduled Start"},
    @{Path="\Microsoft\Windows\UpdateOrchestrator"; Name="Reboot"},
    @{Path="\Microsoft\Windows\UpdateOrchestrator"; Name="Reboot_AC"},
    @{Path="\Microsoft\Windows\UpdateOrchestrator"; Name="Reboot_Battery"},
    @{Path="\Microsoft\Windows\UpdateOrchestrator"; Name="Schedule Scan"},
    @{Path="\Microsoft\Windows\UpdateOrchestrator"; Name="USO_UxBroker"},
    @{Path="\Microsoft\Windows\UpdateOrchestrator"; Name="Schedule Work"}
)

foreach ($task in $tasks) {
    cmd /c "schtasks.exe /Change /TN `"$($task.Path)\$($task.Name)`" /Enable"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    Enabled: $($task.Name)" -ForegroundColor Green
        $tasksEnabled++
    } else {
        Write-Host "    Skipped: $($task.Name)" -ForegroundColor DarkGray
    }
}
Write-Host "    Tasks enabled: $tasksEnabled / $($tasks.Count)" -ForegroundColor Cyan

# ===========================================
# STEP 4: Start essential services
# ===========================================
Write-Host ""
Write-Host "  [4/4] Starting services..." -ForegroundColor Yellow

foreach ($svc in $serviceDefaults.Keys) {
    cmd /c "net.exe start $svc /y"
    $startExit = $LASTEXITCODE
    if ($startExit -eq 0) {
        Write-Host "    $svc : Started" -ForegroundColor Green
    } else {
        Write-Host "    $svc : (may need restart to take effect)" -ForegroundColor Yellow
    }
}

# ===========================================
# SUMMARY
# ===========================================
Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "     WINDOWS UPDATE RESTORED" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Windows Update is now fully restored." -ForegroundColor Cyan
Write-Host "  Go to Settings -> Windows Update -> Check for updates." -ForegroundColor Cyan
Write-Host ""

Read-Host "Press Enter to exit"