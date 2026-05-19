#!/usr/bin/env pwsh
# Windows 11 性能优化脚本
# 适用于：编程开发、视频创作、图形处理的多任务场景
# 系统要求：Windows 11 + SSD + 32GB+ 内存

param(
    [switch]$Help,
    [switch]$CleanOnly,
    [switch]$PerformanceOnly,
    [switch]$All
)

# 设置控制台颜色
$Host.UI.RawUI.WindowTitle = "Windows 11 性能优化脚本"

function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Cyan }
function Write-Success { Write-Host "[SUCCESS] $args" -ForegroundColor Green }
function Write-Warning { Write-Host "[WARNING] $args" -ForegroundColor Yellow }
function Write-Error { Write-Host "[ERROR] $args" -ForegroundColor Red }

# 检查管理员权限
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Error "请以管理员身份运行此脚本！"
    Write-Info "右键点击 PowerShell，选择'以管理员身份运行'"
    exit 1
}

Write-Info "开始 Windows 11 性能优化..."
Write-Host "=" * 60

# 第一阶段：系统清理
function Invoke-SystemClean {
    Write-Host "`n[阶段 1/3] 系统清理" -ForegroundColor Green
    Write-Host "-" * 60
    
    # 1. 清理 Windows 更新缓存
    Write-Info "正在停止 Windows Update 服务..."
    try {
        Stop-Service -Name wuauserv -Force -ErrorAction Stop
        Write-Info "正在清理 Windows 更新缓存..."
        $updatePath = "$env:systemroot\SoftwareDistribution\Download"
        if (Test-Path $updatePath) {
            $size = (Get-ChildItem $updatePath -Recurse | Measure-Object -Property Length -Sum).Sum / 1GB
            Write-Info "将清理约 $([math]::Round($size, 2)) GB 文件"
            Remove-Item -Path $updatePath -Recurse -Force -ErrorAction SilentlyContinue
        }
        Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        Write-Success "Windows 更新缓存清理完成"
    } catch {
        Write-Warning "Windows 更新清理失败：$_"
    }
    
    # 2. 清理临时文件
    Write-Info "正在清理临时文件..."
    $tempPaths = @(
        "$env:TEMP",
        "$env:LOCALAPPDATA\Temp",
        "$env:systemroot\Temp"
    )
    
    $totalCleaned = 0
    foreach ($path in $tempPaths) {
        if (Test-Path $path) {
            $files = Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue
            $size = ($files | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            if ($size) {
                $totalCleaned += $size
                Remove-Item $path\* -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    Write-Success "临时文件清理完成，释放 $([math]::Round($totalCleaned / 1GB, 2)) GB 空间"
    
    # 3. 清理 Delivery Optimization 缓存
    Write-Info "正在清理传输优化缓存..."
    try {
        Stop-Service -Name DoSvc -Force -ErrorAction SilentlyContinue
        $doPath = "$env:systemroot\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache"
        if (Test-Path $doPath) {
            Remove-Item -Path "$doPath\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        Start-Service -Name DoSvc -ErrorAction SilentlyContinue
        Write-Success "传输优化缓存清理完成"
    } catch {
        Write-Warning "传输优化缓存清理失败：$_"
    }
    
    # 4. 清理回收站
    Write-Info "正在清空回收站..."
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Success "回收站清理完成"
    
    # 5. 清理旧的 Windows 安装（如果存在）
    Write-Info "检查 Windows.old 文件夹..."
    if (Test-Path "C:\Windows.old") {
        $winOldSize = (Get-ChildItem "C:\Windows.old" -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
        Write-Warning "发现 Windows.old 文件夹，占用约 $([math]::Round($winOldSize, 2)) GB"
        Write-Info "如需清理，请运行：cleanmgr /sageset:1"
    }
}

# 第二阶段：性能优化
function Invoke-PerformanceTweak {
    Write-Host "`n[阶段 2/3] 性能优化" -ForegroundColor Green
    Write-Host "-" * 60
    
    # 1. 禁用休眠（节省 C 盘空间）
    Write-Info "正在禁用休眠功能..."
    try {
        powercfg -h off
        Write-Success "休眠已禁用，预计释放 10-30GB 空间"
    } catch {
        Write-Warning "禁用休眠失败：$_"
    }
    
    # 2. 启用卓越性能模式
    Write-Info "正在启用卓越性能电源模式..."
    try {
        $guid = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
        if ($guid) {
            powercfg -setactive $guid.Split(':')[1].Trim()
            Write-Success "卓越性能模式已启用"
        } else {
            Write-Info "卓越性能模式可能已启用"
        }
    } catch {
        Write-Warning "电源模式设置失败：$_"
    }
    
    # 3. 优化虚拟内存（针对 64GB+ 内存）
    Write-Info "正在优化虚拟内存设置..."
    try {
        # 设置自定义虚拟内存
        $pagefile = Get-CimInstance Win32_PageFileSetting -Filter "Name='C:\\pagefile.sys'" -ErrorAction SilentlyContinue
        if ($pagefile) {
            $pagefile.InitialSize = 4096
            $pagefile.MaximumSize = 8192
            $pagefile.Put()
            Write-Success "虚拟内存已设置为 4-8GB"
        } else {
            Write-Info "未找到 C 盘虚拟内存配置"
        }
    } catch {
        Write-Warning "虚拟内存设置失败：$_"
    }
    
    # 4. 禁用透明度效果
    Write-Info "正在禁用窗口透明度效果..."
    try {
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
            -Name "EnableTransparency" -Value 0 -Force
        Write-Success "透明度效果已禁用"
    } catch {
        Write-Warning "透明度设置失败：$_"
    }
    
    # 5. 优化系统响应优先级
    Write-Info "正在优化系统响应优先级..."
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" `
            -Name "Win32PrioritySeparation" -Value 26 -Force
        Write-Success "系统响应优先级已优化（需要重启）"
    } catch {
        Write-Warning "优先级设置失败：$_"
    }
    
    # 6. 禁用 8.3 文件名创建
    Write-Info "正在禁用 8.3 文件名创建..."
    try {
        fsutil behavior set disable8dot3 1
        Write-Success "8.3 文件名创建已禁用"
    } catch {
        Write-Warning "8.3 文件名设置失败：$_"
    }
    
    # 7. 检查 TRIM 状态
    Write-Info "检查 TRIM 功能状态..."
    try {
        $trimStatus = fsutil behavior query DisableDeleteNotify
        if ($trimStatus -match "DisableDeleteNotify = 0") {
            Write-Success "TRIM 功能已启用"
        } else {
            Write-Warning "TRIM 功能未启用，正在启用..."
            fsutil behavior set DisableDeleteNotify 0
        }
    } catch {
        Write-Warning "TRIM 检查失败：$_"
    }
}

# 第三阶段：启动项优化
function Invoke-StartupOptimize {
    Write-Host "`n[阶段 3/3] 启动项分析" -ForegroundColor Green
    Write-Host "-" * 60
    
    Write-Info "正在分析启动项..."
    $startupItems = Get-CimInstance Win32_StartupCommand | 
        Select-Object Name, Command, Location, User |
        Sort-Object Name
    
    Write-Host "`n当前启动项列表：" -ForegroundColor Cyan
    $startupItems | Format-Table -AutoSize -Wrap
    
    # 统计启动项数量
    $count = ($startupItems | Measure-Object).Count
    Write-Info "共发现 $count 个启动项"
    
    Write-Host "`n建议保留的启动项：" -ForegroundColor Green
    Write-Host "  - 杀毒软件（Windows Defender 已内置）"
    Write-Host "  - 硬件驱动相关（音频、显卡等）"
    Write-Host "  - 必需的业务软件"
    
    Write-Host "`n可以禁用的启动项：" -ForegroundColor Yellow
    Write-Host "  - 云存储同步（OneDrive、Dropbox 等）"
    Write-Host "  - 聊天工具（微信、QQ、Discord 等）"
    Write-Host "  - 游戏平台（Steam、Epic 等）"
    Write-Host "  - 媒体工具（Spotify、iTunes 等）"
    
    Write-Host "`n禁用方法：" -ForegroundColor Cyan
    Write-Host "  1. 任务管理器 -> 启动 -> 禁用不需要的项"
    Write-Host "  2. 设置 -> 应用 -> 启动 -> 关闭开关"
    Write-Host "  3. 运行 shell:startup 删除启动文件夹快捷方式"
}

# 显示优化建议
function Show-Recommendations {
    Write-Host "`n" + "=" * 60
    Write-Host "优化建议" -ForegroundColor Magenta
    Write-Host "=" * 60
    
    Write-Host @"

📌 立即可做的优化：

1. 禁用不必要的开机启动项
   - 按 Ctrl+Shift+Esc 打开任务管理器
   - 切换到"启动"选项卡
   - 禁用不需要的应用

2. 调整视觉效果
   - 系统 -> 关于 -> 高级系统设置
   - 性能 -> 设置 -> 选择"调整为最佳性能"
   - 勾选"平滑屏幕字体边缘"（保持字体清晰）

3. 存储感知
   - 设置 -> 系统 -> 存储
   - 开启"存储感知"
   - 配置自动清理规则

4. 游戏模式（即使不玩游戏也建议开启）
   - 设置 -> 游戏 -> 游戏模式
   - 开启游戏模式（优化资源分配）

5. 硬件加速 GPU 计划
   - 设置 -> 系统 -> 屏幕 -> 图形设置
   - 开启"硬件加速 GPU 计划"
   - 需要重启系统

📌 开发环境专项优化：

1. Docker/WSL2 内存限制
   - 编辑 %USERPROFILE%\.wslconfig
   - 添加：[wsl2] memory=32GB

2. 浏览器优化
   - Chrome/Edge: 启用"睡眠标签页"
   - 限制后台扩展数量

3. 定期清理开发缓存
   - npm cache clean --force
   - dotnet nuget locals all --clear
   - cargo clean

4. 使用 Process Lasso 管理进程优先级
   - 设置开发工具为高优先级
   - 限制后台进程 CPU 使用

📌 监控工具推荐：

1. MSI Afterburner - 硬件实时监控
2. Process Lasso - 进程优先级管理
3. WizTree - 磁盘空间分析
4. Resource Monitor - 系统资源监控

"@
    
    Write-Host "`n⚠️  注意事项：" -ForegroundColor Yellow
    Write-Host "  - 部分优化需要重启系统才能生效"
    Write-Host "  - 建议在优化前创建系统还原点"
    Write-Host "  - 如遇到异常，可恢复默认设置"
    
    Write-Host "`n✅ 优化完成！" -ForegroundColor Green
    Write-Host "建议重启系统以获得最佳效果。"
}

# 主流程
try {
    if ($Help) {
        Write-Host @"
Windows 11 性能优化脚本

用法:
  .\win11-optimize.ps1 [-CleanOnly] [-PerformanceOnly] [-All]

参数:
  -CleanOnly        仅执行系统清理
  -PerformanceOnly  仅执行性能优化
  -All              执行所有优化（默认）
  -Help             显示此帮助信息

示例:
  .\win11-optimize.ps1              # 执行所有优化
  .\win11-optimize.ps1 -CleanOnly   # 仅清理
"@
        exit 0
    }
    
    if ($CleanOnly) {
        Invoke-SystemClean
    } elseif ($PerformanceOnly) {
        Invoke-PerformanceTweak
        Invoke-StartupOptimize
    } else {
        Invoke-SystemClean
        Invoke-PerformanceTweak
        Invoke-StartupOptimize
    }
    
    Show-Recommendations
    
} catch {
    Write-Error "优化过程出现错误：$_"
    exit 1
}

Write-Host "`n按任意键退出..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
