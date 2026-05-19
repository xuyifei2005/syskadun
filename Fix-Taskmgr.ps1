# Task Manager Performance Fix Script
# Rebuilds performance counters to fix Task Manager lag

param(
    [switch]$NoRestart,
    [switch]$Help
)

$Host.UI.RawUI.WindowTitle = "Task Manager Fix Tool v2.0"
Clear-Host

function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Cyan }
function Write-Success { Write-Host "[OK] $args" -ForegroundColor Green }
function Write-Warn { Write-Host "[WARN] $args" -ForegroundColor Yellow }
function Write-Err { Write-Host "[ERROR] $args" -ForegroundColor Red }
function Write-Step { 
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  $args" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
}

# Check admin rights
function Test-Admin {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($user)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Err "Please run as Administrator!"
    Write-Info "Steps:"
    Write-Info "1. Right-click PowerShell"
    Write-Info "2. Select Run as Administrator"
    Write-Info "3. Run this script"
    Write-Host "`nPress any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Success "Administrator rights confirmed"
Write-Host ""

if ($Help) {
    Write-Host @"
Task Manager Fix Tool v2.0

Usage:
  .\Fix-TaskMgr-Full.ps1 [-NoRestart] [-Help]

Parameters:
  -NoRestart    Do not restart automatically
  -Help         Show this help message

Features:
  1. Rebuild performance counters
  2. Repair Windows image (DISM)
  3. Scan system files (SFC)
  4. Reset Task Manager settings
  5. Verify results

Estimated time: 15-30 minutes
"@
    exit 0
}

# Create restore point
Write-Step "Step 0: Create System Restore Point"
Write-Info "Creating restore point..."
try {
    Checkpoint-Computer -Description "TaskMgr Fix" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
    Write-Success "Restore point created successfully"
} catch {
    Write-Warn "Restore point creation failed (continuing anyway)"
}
Write-Host ""

# Step 1: Rebuild performance counters
Write-Step "Step 1: Rebuild Performance Counters"
Write-Info "This is the key step to fix Task Manager lag"
Write-Host ""

Write-Info "Rebuilding System32 counters..."
Set-Location C:\Windows\System32
$proc = Start-Process -FilePath "lodctr.exe" -ArgumentList "/r" -Wait -PassThru -NoNewWindow
if ($proc.ExitCode -eq 0) {
    Write-Success "System32 counters rebuilt"
} else {
    Write-Warn "System32 rebuild failed (code: $($proc.ExitCode))"
    Write-Info "Trying backup method..."
    $backup = Start-Process -FilePath "lodctr.exe" -ArgumentList "/r:PerfStringBackup.INI" -Wait -PassThru -NoNewWindow
    if ($backup.ExitCode -eq 0) {
        Write-Success "Backup method succeeded"
    } else {
        Write-Warn "Backup method also failed"
    }
}

if (Test-Path C:\Windows\SysWOW64) {
    Write-Info "Rebuilding SysWOW64 counters..."
    Set-Location C:\Windows\SysWOW64
    $proc2 = Start-Process -FilePath "lodctr.exe" -ArgumentList "/r" -Wait -PassThru -NoNewWindow
    if ($proc2.ExitCode -eq 0) {
        Write-Success "SysWOW64 counters rebuilt"
    } else {
        Write-Warn "SysWOW64 rebuild failed (can be ignored)"
    }
}
Write-Host ""

# Step 2: DISM
Write-Step "Step 2: Repair Windows Image (DISM)"
Write-Info "This may take 5-10 minutes..."
Write-Host ""

$proc = Start-Process -FilePath "DISM.exe" -ArgumentList "/Online","/Cleanup-Image","/RestoreHealth" -Wait -PassThru -NoNewWindow
if ($proc.ExitCode -eq 0) {
    Write-Success "DISM repair completed"
} else {
    Write-Warn "DISM failed (code: $($proc.ExitCode))"
}
Write-Host ""

# Step 3: SFC
Write-Step "Step 3: Scan System Files (SFC)"
Write-Info "This may take 5-15 minutes..."
Write-Host ""

$proc = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -PassThru -NoNewWindow
$code = $proc.ExitCode

switch ($code) {
    0 { Write-Success "SFC scan completed - No issues found" }
    1 { Write-Warn "SFC scan completed - Unfixable issues found" }
    2 { Write-Success "SFC scan completed - Issues repaired" }
    3 { Write-Warn "SFC scan completed - Repair requires restart" }
    default { Write-Warn "SFC scan failed (code: $code)" }
}
Write-Host ""

# Step 4: Reset Task Manager
Write-Step "Step 4: Reset Task Manager Settings"
Write-Info "Backup and reset registry settings"
Write-Host ""

$ts = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = "$env:USERPROFILE\Desktop\TaskbarBackup_$ts.reg"
Write-Info "Backing up to: $backup"
$proc = Start-Process -FilePath "reg.exe" -ArgumentList "export","HKCU\Software\Microsoft\Windows\CurrentVersion\Applets\Taskbar",$backup -Wait -PassThru -NoNewWindow -RedirectStandardOutput $null -RedirectStandardError $null
if ($proc.ExitCode -eq 0) {
    Write-Success "Registry backed up"
} else {
    Write-Warn "Registry backup failed"
}

Write-Info "Resetting Task Manager..."
$proc = Start-Process -FilePath "reg.exe" -ArgumentList "delete","HKCU\Software\Microsoft\Windows\CurrentVersion\Applets\Taskbar","/f" -Wait -PassThru -NoNewWindow -RedirectStandardOutput $null -RedirectStandardError $null
if ($proc.ExitCode -eq 0) {
    Write-Success "Task Manager reset"
} else {
    Write-Warn "Task Manager reset failed"
}
Write-Host ""

# Step 5: Verify
Write-Step "Step 5: Verify Performance Counters"
Write-Info "Testing performance counters..."
Write-Host ""

try {
    $test = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction Stop
    Write-Success "Performance counters working"
    Write-Info "Current CPU: $([math]::Round($test.CounterSamples.CookedValue, 1))%"
} catch {
    Write-Err "Performance counters still not working"
    Write-Warn "Restart may be required"
}
Write-Host ""

# Complete
Write-Step "Repair Complete"
Write-Success "All steps completed"
Write-Host ""

Write-Info "Next steps:"
Write-Host "1. Restart your computer (highly recommended)" -ForegroundColor Yellow
Write-Host "2. Test Task Manager after restart" -ForegroundColor White
Write-Host "3. If still laggy, check Event Viewer" -ForegroundColor White
Write-Host ""

if (-not $NoRestart) {
    Write-Info "Restart recommended to apply all changes"
    Write-Host ""
    Write-Host "Restart now?" -ForegroundColor Yellow
    Write-Host "Press Y to restart, any other key to exit..." -ForegroundColor Gray
    
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    if ($key.Character -eq 'Y' -or $key.Character -eq 'y') {
        Write-Info "Restarting..."
        Restart-Computer -Force
    }
} else {
    Write-Info "Please restart manually"
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
