$ErrorActionPreference = 'Continue'
# 注意：必须使用真实项目根目录绝对路径（D:\syskadun 是无关的独立目录，勿用）
$log = 'd:\XUYIFEI\syskadun\perf-tweak-log.txt'
"=== Finalize optimize - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" | Out-File $log -Append -Encoding utf8

# --- 0. 管理员自检（SID 字面量，避免子表达式吞噬问题） ---
$isAdmin = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('S-1-5-32-544')
"Admin: $isAdmin" | Out-File $log -Append -Encoding utf8
if (-not $isAdmin) { 'ERROR: not elevated, abort.' | Out-File $log -Append -Encoding utf8; exit 1 }

# --- 1. 禁用 DiagTrack 遥测（Connected User Experiences and Telemetry） ---
try {
    Stop-Service DiagTrack -Force -ErrorAction SilentlyContinue
    Set-Service DiagTrack -StartupType Disabled -ErrorAction Stop
    'DiagTrack: disabled' | Out-File $log -Append -Encoding utf8
} catch {
    "DiagTrack: FAILED - $($_.Exception.Message)" | Out-File $log -Append -Encoding utf8
}

# --- 2. 关闭 Windows 提示与建议（ContentDeliveryManager 订阅内容） ---
$cdm = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
foreach ($name in 'SubscribedContent-338388Enabled','SubscribedContent-338389Enabled','SubscribedContent-338393Enabled','SubscribedContent-353698Enabled') {
    Set-ItemProperty $cdm -Name $name -Value 0 -Type DWord -ErrorAction SilentlyContinue
}
'ContentDelivery tips: disabled' | Out-File $log -Append -Encoding utf8

# --- 3. 开启存储感知（自动清理临时文件/回收站） ---
$ss = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'
if (-not (Test-Path $ss)) { New-Item $ss -Force | Out-Null }
Set-ItemProperty $ss -Name '01' -Value 1 -Type DWord
'StorageSense: enabled' | Out-File $log -Append -Encoding utf8

# --- 4. 清理临时目录（跳过被占用文件，安全） ---
$before = (Get-PSDrive C).Free / 1GB
foreach ($dir in @($env:TEMP, 'C:\Windows\Temp')) {
    Get-ChildItem $dir -Recurse -Force -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}
$after = (Get-PSDrive C).Free / 1GB
"TempClean: freed $([math]::Round($after-$before,2)) GB; C free now $([math]::Round($after,2)) GB" | Out-File $log -Append -Encoding utf8

# --- 5. 刷新 DNS 缓存 ---
Clear-DnsClientCache -ErrorAction SilentlyContinue
'DNS cache: flushed' | Out-File $log -Append -Encoding utf8

# --- 6. DISM 组件存储清理（压缩 WinSxS，耗时 5-15 分钟） ---
'DISM StartComponentCleanup: started...' | Out-File $log -Append -Encoding utf8
$dismOut = & DISM /Online /Cleanup-Image /StartComponentCleanup 2>&1 | Select-Object -Last 3
$dismOut | Out-String | Out-File $log -Append -Encoding utf8
$finalFree = (Get-PSDrive C).Free / 1GB
"C free after DISM: $([math]::Round($finalFree,2)) GB" | Out-File $log -Append -Encoding utf8
'=== Done ===' | Out-File $log -Append -Encoding utf8
exit 0
