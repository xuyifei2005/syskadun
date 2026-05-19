# 移动虚拟内存到 D 盘脚本
# 需要管理员权限执行

Write-Host "========== 移动虚拟内存到 D 盘 ==========" -ForegroundColor Cyan

# 获取当前虚拟内存配置
$ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem
$CurrentPageFile = $ComputerSystem.AutomaticManagedPagefile

Write-Host "当前虚拟内存配置：自动管理 = $CurrentPageFile"

# 禁用 C 盘自动管理
Write-Host "`n 步骤 1: 禁用自动管理..."
$ComputerSystem.AutomaticManagedPagefile = $false
$ComputerSystem.Put()

# 设置 D 盘虚拟内存（初始大小 4GB，最大值 8GB）
Write-Host "步骤 2: 设置 D 盘虚拟内存（4GB-8GB）..."
$PageFileSetting = Get-WmiObject -Query "SELECT * FROM Win32_PageFileSetting" -ErrorAction SilentlyContinue
if ($PageFileSetting) {
    $PageFileSetting | Remove-WmiObject
}

# 创建新的页面文件设置
$NewPageFile = [WMIClass]"Win32_PageFileSetting"
$newInstance = $NewPageFile.CreateInstance()
$newInstance.Name = "D:\pagefile.sys"
$newInstance.InitialSize = 4096  # 4GB
$newInstance.MaximumSize = 8192  # 8GB
$newInstance.Put()

Write-Host "`n✓ 虚拟内存已配置到 D 盘"
Write-Host "  - 位置：D:\pagefile.sys"
Write-Host "  - 初始大小：4096 MB (4GB)"
Write-Host "  - 最大大小：8192 MB (8GB)"
Write-Host "`n⚠️ 需要重启计算机后生效" -ForegroundColor Yellow

# 显示当前配置
Write-Host "`n 当前虚拟内存配置:"
Get-WmiObject -Query "SELECT * FROM Win32_PageFileUsage" | Format-Table Name, AllocatedBaseSize, CurrentUsage, PeakUsage
