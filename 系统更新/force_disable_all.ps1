# ============================================
# Force Disable Windows Update - v2.1
# Uses sc.exe + reg.exe for maximum reliability
# Run as Administrator!
# ============================================

$host.UI.RawUI.WindowTitle = "Disabling Windows Update..."

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   Windows Update - Complete Disable" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# ===========================================
# STEP 1: Kill update-related processes
# ===========================================
Write-Host "  [1/5] Killing update processes..." -ForegroundColor Yellow
$killed = $false
$procs = @("MoUsoCoreWorker", "UsoClient", "MusNotification", "MusNotifyIcon", "SihClient")
foreach ($p in $procs) {
    $found = Get-Process -Name $p -ErrorAction SilentlyContinue
    if ($found) {
        $found | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Host "    Killed: $p" -ForegroundColor Gray
        $killed = $true
    }
}
if (-not $killed) { Write-Host "    No update processes running" -ForegroundColor Gray }

# ===========================================
# STEP 2: Disable services via sc.exe
# ===========================================
Write-Host ""
Write-Host "  [2/5] Disabling services via sc.exe..." -ForegroundColor Yellow

$services = @(
    "wuauserv",
    "UsoSvc",
    "WaaSMedicSvc",
    "bits",
    "dosvc"
)

foreach ($svc in $services) {

    # Step A: sc.exe config (most reliable)
    $scCmd = "sc.exe config $svc start= disabled"
    $scOutput = cmd /c $scCmd
    $scExit = $LASTEXITCODE

    if ($scExit -eq 0) {
        Write-Host "    sc config $svc : SUCCESS" -ForegroundColor Green
    } else {
        Write-Host "    sc config $svc : FAILED, trying reg.exe..." -ForegroundColor Yellow

        # Step B: reg.exe direct write
        $regCmd = "reg.exe add HKLM\SYSTEM\CurrentControlSet\Services\$svc /v Start /t REG_DWORD /d 4 /f"
        $regOutput = cmd /c $regCmd
        $regExit = $LASTEXITCODE

        if ($regExit -eq 0) {
            Write-Host "    reg add $svc : SUCCESS" -ForegroundColor Green
        } else {
            Write-Host "    $svc : reg.exe also FAILED" -ForegroundColor Red

            # Step C: Take registry ownership and retry
            Write-Host "      Attempting registry ACL override..." -ForegroundColor Yellow
            try {
                $regPath = "SYSTEM\CurrentControlSet\Services\$svc"
                $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($regPath, 'ReadWriteSubTree', 'TakeOwnership')
                if ($key) {
                    $acl = $key.GetAccessControl()
                    $acl.SetOwner([System.Security.Principal.WindowsIdentity]::GetCurrent().User)
                    $key.SetAccessControl($acl)
                    $key.Close()

                    # Retry after ownership change
                    $retryCmd = "reg.exe add HKLM\SYSTEM\CurrentControlSet\Services\$svc /v Start /t REG_DWORD /d 4 /f"
                    cmd /c $retryCmd
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "      $svc : SUCCESS (after ACL fix)" -ForegroundColor Green
                    } else {
                        Write-Host "      $svc : STILL FAILED" -ForegroundColor Red
                        Write-Host "      Manual: regedit -> HKLM\SYSTEM\CurrentControlSet\Services\$svc -> Start=4" -ForegroundColor Red
                    }
                } else {
                    Write-Host "      $svc : Cannot access registry key" -ForegroundColor Red
                }
            } catch {
                Write-Host "      $svc : ACL error - $_" -ForegroundColor Red
            }
        }
    }

    # Stop the service immediately
    $stopCmd = "net.exe stop $svc /y"
    $stopOutput = cmd /c $stopCmd
    $stopExit = $LASTEXITCODE
    if ($stopExit -eq 0) {
        Write-Host "      Stop: OK" -ForegroundColor DarkGray
    } else {
        Write-Host "      Stop: (may need restart to take effect)" -ForegroundColor DarkGray
    }
}

# ===========================================
# STEP 3: Registry policies via reg.exe
# ===========================================
Write-Host ""
Write-Host "  [3/5] Setting Windows Update policies..." -ForegroundColor Yellow

$regCommands = @(
    @{Desc="AUOptions (Never check)";     Cmd="reg.exe add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU /v AUOptions /t REG_DWORD /d 1 /f"},
    @{Desc="NoAutoUpdate";                Cmd="reg.exe add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU /v NoAutoUpdate /t REG_DWORD /d 1 /f"},
    @{Desc="NoAutoRebootWithLoggedOnUsers"; Cmd="reg.exe add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU /v NoAutoRebootWithLoggedOnUsers /t REG_DWORD /d 1 /f"},
    @{Desc="DisableOSUpgrade";            Cmd="reg.exe add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v DisableOSUpgrade /t REG_DWORD /d 1 /f"},
    @{Desc="WUServer (fake)";             Cmd="reg.exe add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v WUServer /t REG_SZ /d 127.0.0.1 /f"},
    @{Desc="WUStatusServer (fake)";       Cmd="reg.exe add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v WUStatusServer /t REG_SZ /d 127.0.0.1 /f"},
    @{Desc="PauseUpdatesExpiryTime";      Cmd="reg.exe add HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings /v PauseUpdatesExpiryTime /t REG_SZ /d 2033-12-31T23:59:59Z /f"}
)

foreach ($entry in $regCommands) {
    cmd /c $entry.Cmd
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    $($entry.Desc) : OK" -ForegroundColor Green
    } else {
        Write-Host "    $($entry.Desc) : FAILED" -ForegroundColor Red
    }
}

# ===========================================
# STEP 4: Disable scheduled tasks
# ===========================================
Write-Host ""
Write-Host "  [4/5] Disabling scheduled tasks..." -ForegroundColor Yellow

$tasksDisabled = 0
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
    $schCmd = "schtasks.exe /Change /TN `"$($task.Path)\$($task.Name)`" /Disable"
    $schOutput = cmd /c $schCmd
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    Disabled: $($task.Name)" -ForegroundColor Green
        $tasksDisabled++
    } else {
        Write-Host "    Skipped: $($task.Name)" -ForegroundColor DarkGray
    }
}
Write-Host "    Tasks disabled: $tasksDisabled / $($tasks.Count)" -ForegroundColor $(if ($tasksDisabled -gt 0) { 'Green' } else { 'Yellow' })

# ===========================================
# STEP 5: Final
# ===========================================
Write-Host ""
Write-Host "  [5/5] Final operations..." -ForegroundColor Yellow
cmd /c "reg.exe add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-WindowsUpdateClient/Operational /v Enabled /t REG_DWORD /d 0 /f"

# ===========================================
# SUMMARY
# ===========================================
Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "        OPERATION COMPLETE" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  [ACTION REQUIRED] Please RESTART your computer now" -ForegroundColor Yellow
Write-Host ""
Write-Host "  To restore updates: right-click 'Restore Updates.bat' -> Run as Administrator" -ForegroundColor Cyan
Write-Host ""

Read-Host "Press Enter to exit"