#!/usr/bin/env pwsh
<#
.SYNOPSIS
    配置 Windows Update 重启策略：活动时间 + 有用户登录时禁止自动重启。
    防止补丁安装后在工作时段/使用电脑时被强制重启（如 2026-09-12 KB5127716 事件）。

.DESCRIPTION
    通过 HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate 策略注册表项实现，
    家庭版（无 gpedit.msc）同样生效。不关闭 Windows 更新本身。

    写入的策略：
      1. SetActiveHours = 1            启用策略方式的活动时间
         ActiveHoursStart / End        活动时间（默认 08:00 - 23:00，跨度 <=18 小时）
      2. AU\NoAutoRebootWithLoggedOnUsers = 1
         有用户登录时不自动重启，改为等待用户确认
      3. AU\AUOptions = 3
         自动下载补丁，安装/重启前通知用户

.PARAMETER ActiveStart
    活动时间开始小时（0-23），默认 8。

.PARAMETER ActiveEnd
    活动时间结束小时（0-23），默认 23。

.PARAMETER Apply
    执行写入（会先尝试创建系统还原点）。不带任何开关时只显示当前状态与预览。

.PARAMETER Revert
    删除本脚本写入的全部策略值，恢复 Windows 默认行为。

.EXAMPLE
    .\set-windowsupdate-reboot-policy.ps1              # 查看当前状态 + 预览
    .\set-windowsupdate-reboot-policy.ps1 -Apply       # 应用策略（默认 8-23）
    .\set-windowsupdate-reboot-policy.ps1 -Apply -ActiveStart 9 -ActiveEnd 22
    .\set-windowsupdate-reboot-policy.ps1 -Revert      # 撤销
#>

[CmdletBinding()]
param(
    [ValidateRange(0, 23)][int]$ActiveStart = 8,
    [ValidateRange(0, 23)][int]$ActiveEnd   = 23,
    [switch]$Apply,
    [switch]$Revert,
    [switch]$Force
)

# ---------------------------------------------------------------------------
# 通用输出函数（控制台输出刻意使用英文，规避中文 Windows 控制台编码问题）
# ---------------------------------------------------------------------------
function Write-Info    { Write-Host "[INFO]    $args" -ForegroundColor Cyan }
function Write-Success { Write-Host "[OK]      $args" -ForegroundColor Green }
function Write-WarnMsg { Write-Host "[WARN]    $args" -ForegroundColor Yellow }
function Write-ErrMsg  { Write-Host "[ERROR]   $args" -ForegroundColor Red }

function Test-Administrator {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 策略注册表路径
$script:WuPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
$script:AuPolicyPath = Join-Path $WuPolicyPath 'AU'

# 本脚本管理的值（-Revert 时精确删除，不碰其它键值）
$script:ManagedWuValues = @('SetActiveHours', 'ActiveHoursStart', 'ActiveHoursEnd')
$script:ManagedAuValues = @('NoAutoRebootWithLoggedOnUsers', 'AUOptions')

# ---------------------------------------------------------------------------
# 读取当前策略状态
# ---------------------------------------------------------------------------
function Get-CurrentPolicy {
    $wu = Get-ItemProperty -Path $script:WuPolicyPath -ErrorAction SilentlyContinue
    $au = Get-ItemProperty -Path $script:AuPolicyPath -ErrorAction SilentlyContinue
    # 用户在"设置"里手动配置的活动时间（非策略）
    $ux = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' -ErrorAction SilentlyContinue

    [PSCustomObject]@{
        PolicySetActiveHours     = if ($wu) { $wu.SetActiveHours }                else { $null }
        PolicyActiveHoursStart   = if ($wu) { $wu.ActiveHoursStart }              else { $null }
        PolicyActiveHoursEnd     = if ($wu) { $wu.ActiveHoursEnd }                else { $null }
        NoAutoRebootForUsers     = if ($au) { $au.NoAutoRebootWithLoggedOnUsers } else { $null }
        AUOptions                = if ($au) { $au.AUOptions }                     else { $null }
        UserActiveHoursStart     = if ($ux) { $ux.ActiveHoursStart }              else { $null }
        UserActiveHoursEnd       = if ($ux) { $ux.ActiveHoursEnd }                else { $null }
    }
}

function Show-Status {
    $c = Get-CurrentPolicy
    Write-Host ""
    Write-Host "===== Windows Update Reboot Policy Status =====" -ForegroundColor Cyan
    Write-Host ("Policy - Active Hours enabled : {0}" -f $(if ($null -ne $c.PolicySetActiveHours) { $c.PolicySetActiveHours } else { '(not set)' }))
    Write-Host ("Policy - Active Hours range   : {0} - {1}" -f $(if ($null -ne $c.PolicyActiveHoursStart) { '{0:D2}:00' -f $c.PolicyActiveHoursStart } else { '(not set)' }), $(if ($null -ne $c.PolicyActiveHoursEnd) { '{0:D2}:00' -f $c.PolicyActiveHoursEnd } else { '' }))
    Write-Host ("Policy - No reboot w/ users   : {0}  (1 = enabled)" -f $(if ($null -ne $c.NoAutoRebootForUsers) { $c.NoAutoRebootForUsers } else { '(not set)' }))
    Write-Host ("Policy - AUOptions            : {0}  (3 = auto download, notify install)" -f $(if ($null -ne $c.AUOptions) { $c.AUOptions } else { '(not set)' }))
    Write-Host ("User-set Active Hours (Settings app): {0} - {1}" -f $(if ($null -ne $c.UserActiveHoursStart) { '{0:D2}:00' -f $c.UserActiveHoursStart } else { '(none)' }), $(if ($null -ne $c.UserActiveHoursEnd) { '{0:D2}:00' -f $c.UserActiveHoursEnd } else { '' }))
    Write-Host ""
}

# ---------------------------------------------------------------------------
# 写入前创建系统还原点（遵循项目安全红线：优化前必须先创建还原点）
# ---------------------------------------------------------------------------
function New-SafetyRestorePoint {
    Write-Info "Creating system restore point before policy change..."
    try {
        $desc = "WU reboot policy change - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Checkpoint-Computer -Description $desc -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Success "Restore point created: $desc"
        return $true
    } catch {
        Write-WarnMsg "Failed to create restore point: $($_.Exception.Message)"
        Write-WarnMsg "Common cause: Windows throttles restore points to 1 per 24h."
        Write-WarnMsg "Policy change is fully reversible via -Revert; continuing."
        return $false
    }
}

# ---------------------------------------------------------------------------
# 应用策略
# ---------------------------------------------------------------------------
function Set-Policy {
    # 活动时间跨度校验（Windows 允许范围 1-18 小时，且不支持跨午夜环绕）
    $span = if ($ActiveEnd -gt $ActiveStart) { $ActiveEnd - $ActiveStart } else { $ActiveEnd + 24 - $ActiveStart }
    if ($span -gt 18 -or $span -lt 1) {
        Write-ErrMsg "Active hours span must be between 1 and 18 hours (got $span h: $ActiveStart -> $ActiveEnd)."
        exit 1
    }

    Write-Info "Target policy values:"
    Write-Host "         Active Hours           : {0:D2}:00 - {1:D2}:00 ($span h)" -f $ActiveStart, $ActiveEnd
    Write-Host "         NoAutoRebootWithUsers  : 1"
    Write-Host "         AUOptions              : 3 (download auto, install/restart by user)"
    Write-Host ""

    if (-not $script:Confirmed) {
        $answer = Read-Host "Apply these policy changes? (Y/N)"
        if ($answer -notin @('Y','y')) {
            Write-WarnMsg "Aborted by user. No changes made."
            exit 0
        }
    }

    New-SafetyRestorePoint | Out-Null

    # 创建/写入活动时间策略
    if (-not (Test-Path $script:WuPolicyPath)) {
        New-Item -Path $script:WuPolicyPath -Force | Out-Null
    }
    New-ItemProperty -Path $script:WuPolicyPath -Name 'SetActiveHours'   -PropertyType DWord -Value 1           -Force | Out-Null
    New-ItemProperty -Path $script:WuPolicyPath -Name 'ActiveHoursStart' -PropertyType DWord -Value $ActiveStart -Force | Out-Null
    New-ItemProperty -Path $script:WuPolicyPath -Name 'ActiveHoursEnd'   -PropertyType DWord -Value $ActiveEnd   -Force | Out-Null

    # 创建/写入 AU 子键策略
    if (-not (Test-Path $script:AuPolicyPath)) {
        New-Item -Path $script:AuPolicyPath -Force | Out-Null
    }
    New-ItemProperty -Path $script:AuPolicyPath -Name 'NoAutoRebootWithLoggedOnUsers' -PropertyType DWord -Value 1 -Force | Out-Null
    New-ItemProperty -Path $script:AuPolicyPath -Name 'AUOptions'                     -PropertyType DWord -Value 3 -Force | Out-Null

    Write-Success "Policy applied successfully."
    Write-Info "Effective immediately for future update scans; no reboot required."
}

# ---------------------------------------------------------------------------
# 撤销策略
# ---------------------------------------------------------------------------
function Undo-Policy {
    if (-not $script:Confirmed) {
        $answer = Read-Host "Remove ALL Windows Update reboot policies written by this script? (Y/N)"
        if ($answer -notin @('Y','y')) {
            Write-WarnMsg "Aborted by user. No changes made."
            exit 0
        }
    }

    foreach ($name in $script:ManagedWuValues) {
        Remove-ItemProperty -Path $script:WuPolicyPath -Name $name -ErrorAction SilentlyContinue
    }
    foreach ($name in $script:ManagedAuValues) {
        Remove-ItemProperty -Path $script:AuPolicyPath -Name $name -ErrorAction SilentlyContinue
    }
    Write-Success "Managed policy values removed. Windows Update is back to default behavior."
}

# ---------------------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------------------
if ($Apply -and $Revert) {
    Write-ErrMsg "-Apply and -Revert cannot be used together."
    exit 1
}

# -Force 用于非交互执行（自动化工具/计划任务），跳过 Read-Host 确认
$script:Confirmed = [bool]$Force

Show-Status

if (-not (Test-Administrator)) {
    if ($Apply -or $Revert) {
        Write-ErrMsg "Administrator privileges required. Re-run as Administrator."
        exit 1
    }
    Write-WarnMsg "Running without -Apply/-Revert: showing status only (no admin needed)."
    Write-Info ('Preview -> Active Hours {0:D2}:00-{1:D2}:00, NoAutoReboot=1, AUOptions=3' -f $ActiveStart, $ActiveEnd)
    Write-Info "Run as Administrator with -Apply to write, or -Revert to remove."
    exit 0
}

if ($Apply) {
    Set-Policy
    Show-Status
} elseif ($Revert) {
    Undo-Policy
    Show-Status
} else {
    Write-Info ('Preview (no changes made) -> Active Hours {0:D2}:00-{1:D2}:00, NoAutoReboot=1, AUOptions=3' -f $ActiveStart, $ActiveEnd)
    Write-Info "Run with -Apply to write policy, or -Revert to remove existing policy."
}
