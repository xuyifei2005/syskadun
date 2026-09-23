# ============================================================
# enable-restore-point.ps1
# 用途：修复系统还原功能（此前被禁用），并补建优化前还原点（需管理员）
# 背景：apply-safe-perf-tweaks.ps1 中 Checkpoint-Computer 报错
#       "由于禁用了该服务……" → 典型原因是 VSS/swprv 服务被设为 Disabled，
#       或 C 盘系统保护未开启
# 设计约束：
#   - 仅恢复服务启动类型为 Manual（系统默认值），不做其他改动
#   - 全英文日志输出，规避中文控制台乱码
# 日志：追加写入 d:\XUYIFEI\syskadun\perf-tweak-log.txt
# ============================================================

$ErrorActionPreference = 'Continue'
# 注意：必须使用真实项目根目录绝对路径（D:\syskadun 是无关的独立目录，勿用）
$log = 'd:\XUYIFEI\syskadun\perf-tweak-log.txt'
"=== Fix restore point - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" | Out-File $log -Append -Encoding utf8

# --- 0. 管理员自检 ---
$isAdmin = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('S-1-5-32-544')
"Admin: $isAdmin" | Out-File $log -Append -Encoding utf8
if (-not $isAdmin) {
    'ERROR: not elevated, abort.' | Out-File $log -Append -Encoding utf8
    exit 1
}

# --- 1. 恢复卷影复制相关服务为 Manual（系统默认；仅当被禁用时才改） ---
foreach ($svc in 'VSS', 'swprv') {
    $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($null -eq $s) { "Service ${svc}: NOT FOUND" | Out-File $log -Append -Encoding utf8; continue }
    if ($s.StartType -eq 'Disabled') {
        Set-Service -Name $svc -StartupType Manual
        "Service ${svc}: Disabled -> Manual" | Out-File $log -Append -Encoding utf8
    } else {
        "Service ${svc}: $($s.StartType) (no change)" | Out-File $log -Append -Encoding utf8
    }
}

# --- 2. 开启 C 盘系统保护 ---
try {
    Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction Stop
    "SystemProtection C: enabled" | Out-File $log -Append -Encoding utf8
} catch {
    "SystemProtection C: FAILED - $($_.Exception.Message)" | Out-File $log -Append -Encoding utf8
}

# --- 3. 补建还原点（SystemRestorePointCreationFrequency 已在上一步清零） ---
try {
    Checkpoint-Computer -Description 'Pre-PerfTweak-Backup' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
    "RestorePoint: created OK" | Out-File $log -Append -Encoding utf8
} catch {
    "RestorePoint: FAILED - $($_.Exception.Message)" | Out-File $log -Append -Encoding utf8
}

# --- 4. 验证：列出当前所有还原点 ---
Get-ComputerRestorePoint -ErrorAction SilentlyContinue |
    Select-Object SequenceNumber, Description, CreationTime |
    Format-Table -AutoSize | Out-String | Out-File $log -Append -Encoding utf8

"=== Done ===" | Out-File $log -Append -Encoding utf8
exit 0
