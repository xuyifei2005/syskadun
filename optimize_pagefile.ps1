# Windows 11 虚拟内存优化脚本
# 针对 64GB 大内存系统优化

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "虚拟内存优化配置" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 对于 64GB 内存，设置 4GB 固定页面文件（足够用于崩溃转储）
$initialSize = 4096  # MB
$maximumSize = 4096  # MB

Write-Host "检测到系统有 64GB 物理内存" -ForegroundColor Green
Write-Host "建议配置：" -ForegroundColor Yellow
Write-Host "  初始大小：4096 MB (4GB)" -ForegroundColor Gray
Write-Host "  最大值：4096 MB (4GB)" -ForegroundColor Gray
Write-Host "  类型：固定大小（避免动态调整开销）" -ForegroundColor Gray
Write-Host ""

# 自动管理设置为 false，手动配置
$ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem
$ComputerSystem.AutomaticManagedPagefile = $false
$ComputerSystem.Put()

Write-Host "[已完成] 禁用自动管理页面文件" -ForegroundColor Green

# 设置 C 盘页面文件
$PageFile = Get-WmiObject -Class Win32_PageFileSetting -Filter "Name='C:\\pagefile.sys'"
if ($PageFile) {
    $PageFile.InitialSize = $initialSize
    $PageFile.MaximumSize = $maximumSize
    $PageFile.Put()
    Write-Host "[已更新] C:\pagefile.sys = 4096 MB" -ForegroundColor Green
} else {
    # 如果不存在则创建
    Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{Name='C:\pagefile.sys'; InitialSize=$initialSize; MaximumSize=$maximumSize}
    Write-Host "[已创建] C:\pagefile.sys = 4096 MB" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "虚拟内存优化完成！需要重启系统生效。" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
