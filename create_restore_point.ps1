# Windows 11 系统还原点创建脚本
# 需要管理员权限运行

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "系统还原点创建工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查管理员权限
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "错误：需要管理员权限才能创建系统还原点" -ForegroundColor Red
    Write-Host ""
    Write-Host "请右键点击 PowerShell，选择'以管理员身份运行'，然后重新执行此脚本" -ForegroundColor Yellow
    exit 1
}

Write-Host "[检查通过] 当前为管理员权限" -ForegroundColor Green
Write-Host ""

# 检查系统还原状态
try {
    $systemRestore = Get-WmiObject -Class SystemRestore -Namespace "root\default" -ErrorAction Stop
    Write-Host "[检查通过] 系统还原功能可用" -ForegroundColor Green
} catch {
    Write-Host "错误：无法访问系统还原服务" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Gray
    exit 1
}

# 创建还原点
$description = "Manual_Restore_Point_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Write-Host ""
Write-Host "正在创建还原点：$description" -ForegroundColor Cyan

$result = $systemRestore.CreateRestorePoint($description, 0, 100)

if ($result.ReturnValue -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "还原点创建成功！" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "还原点名称：$description" -ForegroundColor White
    Write-Host "创建时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "还原点创建失败，错误代码：$($result.ReturnValue)" -ForegroundColor Red
    Write-Host ""
    Write-Host "常见错误代码:" -ForegroundColor Yellow
    Write-Host "  0  - 成功" -ForegroundColor Gray
    Write-Host "  2  - 权限不足" -ForegroundColor Gray
    Write-Host "  5  - 系统还原服务未运行" -ForegroundColor Gray
    Write-Host "  其他 - 系统错误或磁盘空间不足" -ForegroundColor Gray
}

Write-Host ""
Write-Host "提示：可以使用以下命令查看还原点列表" -ForegroundColor Yellow
Write-Host "  Get-ComputerRestorePoint" -ForegroundColor Gray
