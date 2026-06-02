# C 盘紧急清理脚本
# 需要管理员权限运行

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "C 盘紧急清理工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查管理员权限
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "警告：需要管理员权限才能执行完整清理" -ForegroundColor Yellow
    Write-Host "部分清理将被跳过..." -ForegroundColor Gray
    Write-Host ""
}

$freedSpace = 0

# 1. 清理 Windows.old
Write-Host "[1/6] 清理 Windows.old 旧系统文件..." -ForegroundColor Yellow
if (Test-Path "C:\Windows.old") {
    try {
        $size = (Get-ChildItem "C:\Windows.old" -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        Remove-Item -Path "C:\Windows.old" -Recurse -Force -ErrorAction SilentlyContinue
        $freedSpace += $size
        Write-Host "  ✓ 已删除 Windows.old (约 $([math]::Round($size / 1GB, 2)) GB)" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ 删除失败，需要管理员权限" -ForegroundColor Red
    }
} else {
    Write-Host "  - Windows.old 不存在" -ForegroundColor Gray
}

# 2. 清理临时文件
Write-Host ""
Write-Host "[2/6] 清理临时文件..." -ForegroundColor Yellow
$tempPaths = @("$env:TEMP", "C:\Windows\Temp")
foreach ($path in $tempPaths) {
    if (Test-Path $path) {
        $count = (Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
        Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ 已清理：$path ($count 个文件)" -ForegroundColor Green
    }
}

# 3. 清理 Windows 更新缓存
Write-Host ""
Write-Host "[3/6] 清理 Windows 更新缓存..." -ForegroundColor Yellow
if (Test-Path "C:\Windows\SoftwareDistribution\Download") {
    Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ 已清理更新缓存" -ForegroundColor Green
}

# 4. 清理回收站
Write-Host ""
Write-Host "[4/6] 清理回收站..." -ForegroundColor Yellow
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Write-Host "  ✓ 已清理回收站" -ForegroundColor Green

# 5. 清理 Docker（如安装）
Write-Host ""
Write-Host "[5/6] 清理 Docker 资源..." -ForegroundColor Yellow
if (Get-Command docker -ErrorAction SilentlyContinue) {
    docker system prune -f -ErrorAction SilentlyContinue
    Write-Host "  ✓ 已清理 Docker 未使用资源" -ForegroundColor Green
} else {
    Write-Host "  - 未检测到 Docker" -ForegroundColor Gray
}

# 6. 清理日志文件
Write-Host ""
Write-Host "[6/6] 清理系统日志..." -ForegroundColor Yellow
Get-ChildItem "C:\Windows\Logs" -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
Write-Host "  ✓ 已清理日志文件" -ForegroundColor Green

# 统计结果
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "清理完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
if ($freedSpace -gt 0) {
    Write-Host "总计释放空间：$([math]::Round($freedSpace / 1GB, 2)) GB" -ForegroundColor Green
} else {
    Write-Host "提示：部分清理需要管理员权限" -ForegroundColor Yellow
    Write-Host "请右键 PowerShell → 以管理员身份运行 → 重新执行此脚本" -ForegroundColor Gray
}
Write-Host ""
Write-Host "建议操作：" -ForegroundColor Yellow
Write-Host "1. 禁用休眠（如不需要）：powercfg /h off" -ForegroundColor Gray
Write-Host "2. 迁移虚拟内存到 D 盘" -ForegroundColor Gray
Write-Host "3. 迁移个人文件夹到 D 盘" -ForegroundColor Gray
