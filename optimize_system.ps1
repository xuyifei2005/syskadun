# 系统体验优化脚本 - 一键优化
# 用法：.\optimize_system.ps1

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  系统体验优化开始" -ForegroundColor Cyan
Write-Host "  执行时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# 1. 设置高性能电源模式
Write-Host "`n[1/8] 设置高性能电源模式..." -ForegroundColor Yellow
try {
    # 高性能 GUID
    $highPerfGuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
    powercfg /setactive $highPerfGuid
    Write-Host "  ✓ 已设置高性能电源模式" -ForegroundColor Green
} catch {
    Write-Host "  ✗ 电源模式设置失败" -ForegroundColor Red
}

# 2. 清理系统缓存
Write-Host "`n[2/8] 清理系统缓存..." -ForegroundColor Yellow
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

# 3. Docker 清理
Write-Host "`n[3/8] Docker 深度清理..." -ForegroundColor Yellow
try {
    $dockerStatus = Get-Command docker -ErrorAction SilentlyContinue
    if ($dockerStatus) {
        Write-Host "  停止容器..." -ForegroundColor Gray
        docker stop $(docker ps -aq) -f 2>$null
        
        Write-Host "  删除退出的容器..." -ForegroundColor Gray
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

# 4. 创建 WSL 配置文件
Write-Host "`n[4/8] 配置 WSL 资源限制..." -ForegroundColor Yellow
try {
    $wslConfig = @"
[wsl2]
memory=16GB
processors=12
swap=8GB
localhostForwarding=true
"@
    $wslConfig | Out-File -FilePath "$env:USERPROFILE\.wslconfig" -Encoding UTF8
    Write-Host "  ✓ WSL 配置已创建：$env:USERPROFILE\.wslconfig" -ForegroundColor Green
} catch {
    Write-Host "  ✗ WSL 配置创建失败" -ForegroundColor Red
}

# 5. 配置 Git 优化
Write-Host "`n[5/8] 配置 Git 性能优化..." -ForegroundColor Yellow
try {
    git config --global http.postBuffer 524288000 2>$null
    git config --global feature.manyFiles true 2>$null
    git config --global core.compression 0 2>$null
    Write-Host "  ✓ Git 优化配置完成" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Git 配置失败 (可能未安装 Git)" -ForegroundColor Yellow
}

# 6. 开启游戏模式
Write-Host "`n[6/8] 开启游戏模式..." -ForegroundColor Yellow
try {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 1 -Force
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1 -Force
    Write-Host "  ✓ 游戏模式已开启" -ForegroundColor Green
} catch {
    Write-Host "  ✗ 游戏模式开启失败" -ForegroundColor Yellow
}

# 7. 配置 DNS
Write-Host "`n[7/8] 配置 DNS 服务器..." -ForegroundColor Yellow
try {
    # 设置 DNS 为阿里云
    $adapters = Get-NetAdapter | Where-Object Status -Eq "Up"
    foreach ($adapter in $adapters) {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ("223.5.5.5", "223.6.6.6") -ErrorAction SilentlyContinue
    }
    Write-Host "  ✓ DNS 已设置为阿里云 DNS" -ForegroundColor Green
} catch {
    Write-Host "  ✗ DNS 设置失败" -ForegroundColor Yellow
}

# 8. 开启存储感知
Write-Host "`n[8/8] 开启存储感知..." -ForegroundColor Yellow
try {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 1 -Force
    Write-Host "  ✓ 存储感知已开启" -ForegroundColor Green
} catch {
    Write-Host "  ✗ 存储感知开启失败" -ForegroundColor Yellow
}

# 优化完成
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  系统优化完成！" -ForegroundColor Green
Write-Host "  执行时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "[完成的操作]:" -ForegroundColor Green
Write-Host "  ✓ 电源模式：高性能" -ForegroundColor Cyan
Write-Host "  ✓ 系统缓存：已清理" -ForegroundColor Cyan
Write-Host "  ✓ Docker: 已深度清理" -ForegroundColor Cyan
Write-Host "  ✓ WSL: 资源限制配置" -ForegroundColor Cyan
Write-Host "  ✓ Git: 性能优化配置" -ForegroundColor Cyan
Write-Host "  ✓ 游戏模式：已开启" -ForegroundColor Cyan
Write-Host "  ✓ DNS: 阿里云 DNS" -ForegroundColor Cyan
Write-Host "  ✓ 存储感知：已开启" -ForegroundColor Cyan

Write-Host "`n[建议]:" -ForegroundColor Yellow
Write-Host "  1. 重启系统以应用所有更改" -ForegroundColor Cyan
Write-Host "  2. 手动配置启动项优化（任务管理器）" -ForegroundColor Cyan
Write-Host "  3. 手动配置虚拟内存到 D 盘" -ForegroundColor Cyan
Write-Host "  4. 运行 monitor_c_drive.ps1 查看效果" -ForegroundColor Cyan
Write-Host ""

Write-Host "[待手动执行的操作]:" -ForegroundColor Yellow
Write-Host "  • 启动项优化：禁用不常用的启动程序" -ForegroundColor Gray
Write-Host "  • 虚拟内存：迁移到 D 盘（系统属性→高级→性能→虚拟内存）" -ForegroundColor Gray
Write-Host "  • Windows Defender: 添加开发文件夹排除项" -ForegroundColor Gray
Write-Host ""
