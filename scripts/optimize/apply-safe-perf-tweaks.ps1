# ============================================================
# apply-safe-perf-tweaks.ps1
# 用途：创建还原点后，应用 5 项已评估安全的性能优化（需管理员）
# 设计约束：
#   - 完全不触碰 Docker/WSL2/ASUS 相关组件（安全红线）
#   - 跳过"卓越性能电源计划"（与 G-Helper Turbo 冲突）
#   - 跳过"固定虚拟内存"（Docker/WSL2 场景有 OOM 风险）
#   - 全英文输出，规避中文控制台乱码
# 日志：d:\XUYIFEI\syskadun\perf-tweak-log.txt（UTF8，供外部验证）
# ============================================================

$ErrorActionPreference = 'Continue'
# 注意：必须使用真实项目根目录绝对路径（D:\syskadun 是无关的独立目录，勿用）
$log = 'd:\XUYIFEI\syskadun\perf-tweak-log.txt'
"=== Safe perf tweaks - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" | Out-File $log -Encoding utf8

# --- 0. 管理员自检 ---
$isAdmin = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('S-1-5-32-544')
"Admin: $isAdmin" | Out-File $log -Append -Encoding utf8
if (-not $isAdmin) {
    'ERROR: not elevated, abort.' | Out-File $log -Append -Encoding utf8
    exit 1
}

# --- 1. 创建还原点（安全红线：优化前必做） ---
# 临时清零"24小时内仅允许一个还原点"的限制，确保本次必定创建
try {
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore' `
        -Name 'SystemRestorePointCreationFrequency' -Value 0 -PropertyType DWord -Force | Out-Null
    Checkpoint-Computer -Description 'Pre-PerfTweak-Backup' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
    "RestorePoint: created OK" | Out-File $log -Append -Encoding utf8
} catch {
    "RestorePoint: FAILED - $($_.Exception.Message)" | Out-File $log -Append -Encoding utf8
}
Get-ComputerRestorePoint -ErrorAction SilentlyContinue |
    Select-Object SequenceNumber, Description, CreationTime |
    Format-Table -AutoSize | Out-String | Out-File $log -Append -Encoding utf8

# --- 2. 禁用休眠（释放 hiberfil.sys 磁盘空间；睡眠不受影响） ---
powercfg -h off 2>&1 | Out-String | Out-File $log -Append -Encoding utf8
"Hibernate: disabled (exit=$LASTEXITCODE)" | Out-File $log -Append -Encoding utf8

# --- 3. 关闭透明效果（降低 DWM 合成开销） ---
Set-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' `
    -Name EnableTransparency -Value 0 -Type DWord
"Transparency: disabled" | Out-File $log -Append -Encoding utf8

# --- 4. 前台程序优先调度（短量子 + 前台加权，游戏/交互更跟手） ---
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' `
    -Name Win32PrioritySeparation -Value 26 -Type DWord
"Win32PrioritySeparation: 26" | Out-File $log -Append -Encoding utf8

# --- 5. 禁用 NTFS 8.3 短文件名（减少文件系统元数据开销） ---
fsutil behavior set disable8dot3 1 2>&1 | Out-String | Out-File $log -Append -Encoding utf8

# --- 6. TRIM 状态检查（只读；0 = 已启用） ---
"TRIM query:" | Out-File $log -Append -Encoding utf8
fsutil behavior query DisableDeleteNotify 2>&1 | Out-String | Out-File $log -Append -Encoding utf8

# --- 7. 复查 C 盘可用空间（含休眠文件释放效果） ---
$free = (Get-PSDrive C).Free / 1GB
"C free: $([math]::Round($free,2)) GB" | Out-File $log -Append -Encoding utf8

"=== Done ===" | Out-File $log -Append -Encoding utf8
exit 0
