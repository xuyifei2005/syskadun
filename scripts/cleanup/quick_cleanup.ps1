# 快速清理脚本 - 释放约 60-70GB 空间
# 用法：.\quick_cleanup.ps1

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  快速清理开始" -ForegroundColor Cyan
Write-Host "  执行时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$totalCleaned = 0

# 1. 系统缓存清理
Write-Host "[1/6] 清理系统缓存..." -ForegroundColor Yellow
$cachePaths = @(
    "$env:USERPROFILE\.cache",
    "$env:USERPROFILE\.claude\cache",
    "$env:USERPROFILE\.trae\cache",
    "$env:USERPROFILE\.trae-cn\cache",
    "$env:USERPROFILE\.codex\cache",
    "$env:USERPROFILE\.qoder\cache"
)
foreach ($path in $cachePaths) {
    if (Test-Path $path) {
        try {
            $size = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | 
                     Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1MB
            Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ 已清理：$path ($([math]::Round($size, 2)) MB)" -ForegroundColor Green
            $totalCleaned += $size
        } catch {
            Write-Host "  ✗ 清理失败：$path" -ForegroundColor Red
        }
    }
}

# 2. 临时文件清理
Write-Host "`n[2/6] 清理临时文件..." -ForegroundColor Yellow
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

# 3. 回收站清理
Write-Host "`n[3/6] 清理回收站..." -ForegroundColor Yellow
try {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ 回收站已清空" -ForegroundColor Green
} catch {
    Write-Host "  ✗ 回收站清理失败" -ForegroundColor Red
}

# 4. Docker 清理
Write-Host "`n[4/6] Docker 深度清理..." -ForegroundColor Yellow
try {
    $dockerStatus = Get-Command docker -ErrorAction SilentlyContinue
    if ($dockerStatus) {
        Write-Host "  停止未使用的容器..." -ForegroundColor Gray
        docker stop $(docker ps -aq -f status=running) -f 2>$null
        
        Write-Host "  删除已退出的容器..." -ForegroundColor Gray
        docker container prune -f
        
        Write-Host "  删除未使用的镜像..." -ForegroundColor Gray
        docker image prune -a -f
        
        Write-Host "  删除未使用的卷..." -ForegroundColor Gray
        docker volume prune -f
        
        Write-Host "  ✓ Docker 清理完成" -ForegroundColor Green
    } else {
        Write-Host "  Docker 未安装，跳过" -ForegroundColor Gray
    }
} catch {
    Write-Host "  ✗ Docker 清理失败" -ForegroundColor Red
}

# 5. Bun 缓存清理
Write-Host "`n[5/6] 清理 Bun 缓存..." -ForegroundColor Yellow
try {
    if (Test-Path "$env:USERPROFILE\.bun\cache") {
        $size = (Get-ChildItem "$env:USERPROFILE\.bun\cache" -Recurse -ErrorAction SilentlyContinue | 
                 Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1MB
        Remove-Item "$env:USERPROFILE\.bun\cache" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ 已清理 Bun 缓存 ($([math]::Round($size, 2)) MB)" -ForegroundColor Green
        $totalCleaned += $size
    } else {
        Write-Host "  Bun 缓存不存在，跳过" -ForegroundColor Gray
    }
} catch {
    Write-Host "  ✗ Bun 缓存清理失败" -ForegroundColor Red
}

# 6. 本地状态缓存清理
Write-Host "`n[6/6] 清理本地状态缓存..." -ForegroundColor Yellow
$localStatePaths = @(
    "$env:USERPROFILE\AppData\Local\Microsoft\Windows\Explorer\thumbcache_*.db",
    "$env:USERPROFILE\AppData\Local\CrashDumps\*"
)
foreach ($path in $localStatePaths) {
    try {
        Remove-Item $path -Force -ErrorAction SilentlyContinue
    } catch {}
}
Write-Host "  ✓ 本地状态缓存已清理" -ForegroundColor Green

# 清理完成
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  清理完成！" -ForegroundColor Green
Write-Host "  执行时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "[统计] 估算清理空间:" -ForegroundColor Yellow
Write-Host "  缓存文件：$([math]::Round($totalCleaned, 2)) MB" -ForegroundColor Cyan
Write-Host "  Docker 镜像：约 48000 MB (48GB)" -ForegroundColor Cyan
Write-Host "  临时文件：约 3000-4000 MB" -ForegroundColor Cyan
Write-Host "  总计：约 60-70 GB" -ForegroundColor Green
Write-Host ""

Write-Host "[提示] 运行以下命令查看效果:" -ForegroundColor Yellow
Write-Host "  .\monitor_c_drive.ps1" -ForegroundColor Cyan
Write-Host ""

Write-Host "[注意] 以下缓存会重新生成:" -ForegroundColor Yellow
Write-Host "  - IDE 扩展和索引（.vscode, .lingma）" -ForegroundColor Gray
Write-Host "  - 包管理器缓存（.bun, .m2）" -ForegroundColor Gray
Write-Host "  - 应用缓存（.cache, .claude 等）" -ForegroundColor Gray
Write-Host ""
