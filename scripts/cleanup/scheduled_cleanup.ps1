# 定期清理脚本
# 用法：.\scheduled_cleanup.ps1
# 建议：每周执行一次（可通过任务计划程序自动执行）

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  定期清理开始" -ForegroundColor Cyan
Write-Host "  执行时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$totalCleaned = 0

# 1. 清理临时文件
Write-Host "🗑️  清理临时文件..." -ForegroundColor Yellow
$tempPaths = @("$env:TEMP", "$env:TMP", "C:\Windows\Temp")
foreach ($path in $tempPaths) {
    if (Test-Path $path) {
        try {
            $count = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue).Count
            Remove-Item $path\* -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ 已清理：$path (约 $count 个文件)" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ 清理失败：$path" -ForegroundColor Red
        }
    }
}

# 2. 清理回收站
Write-Host "`n🗑️  清理回收站..." -ForegroundColor Yellow
try {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ 回收站已清空" -ForegroundColor Green
} catch {
    Write-Host "  ✗ 回收站清理失败（可能需要确认）" -ForegroundColor Red
}

# 3. 清理 Windows 更新缓存
Write-Host "`n🗑️  清理 Windows 更新缓存..." -ForegroundColor Yellow
try {
    Write-Host "  停止 Windows Update 服务..." -ForegroundColor Gray
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    
    $wuPath = "C:\Windows\SoftwareDistribution\Download"
    if (Test-Path $wuPath) {
        $wuSize = (Get-ChildItem $wuPath -Recurse -ErrorAction SilentlyContinue | 
                   Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1MB
        Remove-Item $wuPath\* -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ 已清理更新缓存：$([math]::Round($wuSize, 2)) MB" -ForegroundColor Green
    }
    
    Write-Host "  重启 Windows Update 服务..." -ForegroundColor Gray
    Start-Service wuauserv -ErrorAction SilentlyContinue
    Write-Host "  ✓ Windows Update 服务已重启" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Windows 更新缓存清理失败" -ForegroundColor Red
}

# 4. 清理系统缓存
Write-Host "`n🗑️  清理系统缓存..." -ForegroundColor Yellow
$cachePaths = @(
    "$env:USERPROFILE\.cache",
    "$env:USERPROFILE\.claude\cache",
    "$env:USERPROFILE\.trae\cache",
    "$env:USERPROFILE\.codex\cache"
)
foreach ($path in $cachePaths) {
    if (Test-Path $path) {
        try {
            $size = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | 
                     Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1MB
            Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ 已清理：$path ($([math]::Round($size, 2)) MB)" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ 清理失败：$path" -ForegroundColor Red
        }
    }
}

# 5. 清理浏览器缓存（可选，需要关闭浏览器）
Write-Host "`n⚠️  浏览器缓存清理跳过" -ForegroundColor Yellow
Write-Host "  提示：建议在浏览器设置中配置自动清理" -ForegroundColor Gray

# 6. 清理 Docker 未使用的资源（如果安装了 Docker）
Write-Host "`n🐳 检查 Docker..." -ForegroundColor Yellow
try {
    $dockerStatus = Get-Command docker -ErrorAction SilentlyContinue
    if ($dockerStatus) {
        Write-Host "  Docker 已安装，建议手动执行清理:" -ForegroundColor Gray
        Write-Host "  docker system prune -a -f" -ForegroundColor Cyan
    } else {
        Write-Host "  Docker 未安装，跳过" -ForegroundColor Gray
    }
} catch {
    Write-Host "  Docker 检查失败" -ForegroundColor Red
}

# 7. 清理日志文件
Write-Host "`n🗑️  清理日志文件..." -ForegroundColor Yellow
$logPaths = @(
    "C:\Windows\Logs",
    "$env:USERPROFILE\AppData\Local\Temp"
)
foreach ($path in $logPaths) {
    if (Test-Path $path) {
        try {
            $oldLogs = Get-ChildItem $path -File -Recurse -ErrorAction SilentlyContinue | 
                       Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }
            if ($oldLogs) {
                $logSize = ($oldLogs | Measure-Object -Property Length -Sum).Sum / 1MB
                $oldLogs | Remove-Item -Force -ErrorAction SilentlyContinue
                Write-Host "  ✓ 已清理 30 天前的日志：$path ($([math]::Round($logSize, 2)) MB)" -ForegroundColor Green
            }
        } catch {
            Write-Host "  ✗ 日志清理失败：$path" -ForegroundColor Red
        }
    }
}

# 清理完成
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  定期清理完成！" -ForegroundColor Green
Write-Host "  执行时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "💡 建议:" -ForegroundColor Yellow
Write-Host "  1. 每周执行一次此脚本" -ForegroundColor Gray
Write-Host "  2. 使用任务计划程序设置自动执行" -ForegroundColor Gray
Write-Host "  3. 运行 monitor_c_drive.ps1 查看清理效果" -ForegroundColor Gray
Write-Host ""
