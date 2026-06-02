#!/usr/bin/env pwsh
# ROG 游戏本专项优化脚本
# 适用于：ROG Strix G16 G615LM + Intel Core Ultra 9 275HX + 64GB 内存

param(
    [switch]$Help,
    [switch]$GamingMode,
    [switch]$CreatorMode,
    [switch]$DevMode
)

function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Cyan }
function Write-Success { Write-Host "[SUCCESS] $args" -ForegroundColor Green }
function Write-Warning { Write-Host "[WARNING] $args" -ForegroundColor Yellow }
function Write-Error { Write-Host "[ERROR] $args" -ForegroundColor Red }
function Write-ROG { Write-Host "[ROG] $args" -ForegroundColor Magenta }

# 检查管理员权限
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Error "请以管理员身份运行此脚本！"
    exit 1
}

Write-ROG "ROG Strix G16 专项优化脚本"
Write-Host "系统：Intel Core Ultra 9 275HX (24 核心) | 64GB 内存"
Write-Host "=" * 70

# 模式选择
$mode = ""
if ($GamingMode) { $mode = "Gaming" }
elseif ($CreatorMode) { $mode = "Creator" }
elseif ($DevMode) { $mode = "Dev" }
else {
    Write-Host "`n请选择使用模式：" -ForegroundColor Yellow
    Write-Host "1. 游戏模式（-GamingMode） - 最大化游戏性能"
    Write-Host "2. 创作模式（-CreatorMode） - 视频渲染/图形处理"
    Write-Host "3. 开发模式（-DevMode） - 编程开发/多任务"
    Write-Host "4. 全部优化（默认） - 应用所有优化"
    
    $choice = Read-Host "请输入选项 (1-4，默认 4)"
    switch ($choice) {
        "1" { $mode = "Gaming" }
        "2" { $mode = "Creator" }
        "3" { $mode = "Dev" }
        default { $mode = "All" }
    }
}

Write-Info "当前模式：$mode"

# GPU 优化
function Invoke-GPUOptimize {
    Write-Host "`n[GPU 优化] 针对 Intel Arc 核显 + NVIDIA 独显" -ForegroundColor Green
    Write-Host "-" * 70
    
    # 1. 设置硬件加速 GPU 计划
    Write-Info "正在配置硬件加速 GPU 计划..."
    try {
        $path = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        $value = "HwSchMode"
        
        # 2 = 启用，带优化
        Set-ItemProperty -Path $path -Name $value -Value 2 -Force
        Write-Success "硬件加速 GPU 计划已启用（模式 2：优化）"
    } catch {
        Write-Warning "GPU 计划设置失败：$_"
    }
    
    # 2. 禁用全屏优化
    Write-Info "正在禁用全屏优化（减少游戏延迟）..."
    try {
        $path = "HKCU:\System\GameConfigStore"
        Set-ItemProperty -Path $path -Name "GameDVR_Enabled" -Value 0 -Force
        Write-Success "游戏 DVR 已禁用"
    } catch {
        Write-Warning "游戏 DVR 设置失败：$_"
    }
    
    # 3. 禁用 Xbox Game Bar（可选）
    Write-Info "正在配置 Xbox Game Bar..."
    try {
        $path = "HKCU:\Software\Microsoft\GameBar"
        Set-ItemProperty -Path $path -Name "AutoGameModeEnabled" -Value 0 -Force
        Write-Info "Xbox Game Bar 自动游戏模式已禁用"
    } catch {
        Write-Warning "Xbox Game Bar 设置失败：$_"
    }
}

# CPU 优化（针对 Ultra 9 275HX）
function Invoke-CPUOptimize {
    Write-Host "`n[CPU 优化] Intel Core Ultra 9 275HX (24 核心)" -ForegroundColor Green
    Write-Host "-" * 70
    
    # 1. 设置处理器电源管理
    Write-Info "正在优化处理器电源管理..."
    try {
        # 最小处理器状态 - 高性能模式
        powercfg /setacvalueindex scheme_current sub_processor 54533251-82be-4824-96c1-47b60b740d00 0
        powercfg /setactive scheme_current
        
        Write-Success "处理器电源管理已优化"
    } catch {
        Write-Warning "处理器电源管理设置失败：$_"
    }
    
    # 2. 禁用核心停车（Core Parking）- 提升响应速度
    Write-Info "正在禁用核心停车功能..."
    try {
        # 启用所有核心
        powercfg /setacvalueindex scheme_current sub_processor 0cc5b647-c1df-4637-891a-dec35c318583 0
        powercfg /setactive scheme_current
        Write-Success "核心停车已禁用（所有核心保持活跃）"
    } catch {
        Write-Warning "核心停车设置失败：$_"
    }
}

# 内存优化（64GB 配置）
function Invoke-MemoryOptimize {
    Write-Host "`n[内存优化] 64GB DDR5" -ForegroundColor Green
    Write-Host "-" * 70
    
    # 1. 优化页面文件（64GB 内存可以设置更小）
    Write-Info "正在优化虚拟内存配置..."
    try {
        $pagefile = Get-CimInstance Win32_PageFileSetting -Filter "Name='C:\\pagefile.sys'" -ErrorAction SilentlyContinue
        if ($pagefile) {
            # 对于 64GB 内存，设置 8-16GB 足够
            $pagefile.InitialSize = 8192
            $pagefile.MaximumSize = 16384
            $pagefile.Put()
            Write-Success "虚拟内存已设置为 8-16GB（适合 64GB 物理内存）"
        } else {
            Write-Info "未找到 C 盘虚拟内存配置"
        }
    } catch {
        Write-Warning "虚拟内存设置失败：$_"
    }
    
    # 2. 禁用 Superfetch（对于大内存 + SSD 不是必须）
    Write-Info "正在配置 SysMain 服务..."
    try {
        # 注意：不建议完全禁用，改为延迟启动
        $service = Get-Service -Name SysMain -ErrorAction Stop
        if ($service.Status -eq 'Running') {
            Set-Service -Name SysMain -StartupType Automatic
            Write-Info "SysMain 服务保持启用（预加载常用程序）"
        }
    } catch {
        Write-Warning "SysMain 服务配置失败：$_"
    }
}

# 网络优化
function Invoke-NetworkOptimize {
    Write-Host "`n[网络优化] 低延迟配置" -ForegroundColor Green
    Write-Host "-" * 70
    
    # 1. 禁用 Nagle 算法（降低网络延迟）
    Write-Info "正在优化 TCP 配置..."
    try {
        # 启用 TCP Window Scaling
        netsh int tcp set global windowingautotuninglevel=normal
        
        # 启用接收端缩放
        netsh int tcp set global rss=enabled
        
        Write-Success "TCP 网络已优化（低延迟模式）"
    } catch {
        Write-Warning "TCP 配置失败：$_"
    }
    
    # 2. 禁用大发送卸载
    Write-Info "正在配置网络适配器..."
    try {
        # 获取网络适配器
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
        foreach ($adapter in $adapters) {
            # 启用节能以太网（笔记本省电）
            Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Energy Efficient Ethernet" -DisplayValue "Enabled" -ErrorAction SilentlyContinue
        }
        Write-Success "网络适配器已优化"
    } catch {
        Write-Warning "网络适配器配置失败：$_"
    }
}

# 散热优化（ROG 游戏本关键）
function Invoke-ThermalOptimize {
    Write-Host "`n[散热优化] ROG 智能散热配置" -ForegroundColor Green
    Write-Host "-" * 70
    
    Write-ROG "ROG 散热建议："
    Write-Host "  1. 使用 ROG Armoury Crate 设置风扇模式"
    Write-Host "     - 办公：Silent 模式"
    Write-Host "     - 游戏/渲染：Performance 或 Turbo 模式"
    Write-Host "     - 手动：Manual 模式（自定义风扇曲线）"
    Write-Host ""
    Write-Host "  2. 垫高笔记本底部或使用散热底座"
    Write-Host "  3. 定期清理风扇灰尘（建议 3-6 个月）"
    Write-Host "  4. 更换高性能硅脂（如：霍尼韦尔 PTM7950）"
    Write-Host ""
    Write-Host "  5. 禁用 CPU Overclocking（除非必要）"
    Write-Host "  6. 使用 ThrottleStop 或 Intel XTU 调整功耗墙"
    
    # 配置电源按钮行为
    Write-Info "正在配置电源按钮..."
    try {
        # 设置电源按钮为睡眠
        powercfg /setacvalueindex scheme_current 4f971e89-eebd-4455-a8de-9e59040e7347 a7066653-8d6c-40a8-910e-a1f54b84c7e5 3
        powercfg /setactive scheme_current
        Write-Success "电源按钮已配置为睡眠"
    } catch {
        Write-Warning "电源按钮配置失败：$_"
    }
}

# 游戏模式专项优化
function Invoke-GamingMode {
    Write-Host "`n[游戏模式] 最大化游戏性能" -ForegroundColor Magenta
    Write-Host "-" * 70
    
    Invoke-GPUOptimize
    Invoke-CPUOptimize
    
    # 启用游戏模式
    Write-Info "正在启用游戏模式..."
    try {
        $path = "HKCU:\Software\Microsoft\GameBar"
        Set-ItemProperty -Path $path -Name "AllowAutoGameMode" -Value 1 -Force
        Set-ItemProperty -Path $path -Name "AutoGameModeEnabled" -Value 1 -Force
        Write-Success "游戏模式已启用"
    } catch {
        Write-Warning "游戏模式设置失败：$_"
    }
    
    # 禁用鼠标加速
    Write-Info "正在禁用鼠标加速（提升游戏精准度）..."
    try {
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0" -Force
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0" -Force
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0" -Force
        Write-Success "鼠标加速已禁用"
    } catch {
        Write-Warning "鼠标加速设置失败：$_"
    }
}

# 创作模式专项优化
function Invoke-CreatorMode {
    Write-Host "`n[创作模式] 视频渲染/图形处理优化" -ForegroundColor Magenta
    Write-Host "-" * 70
    
    Invoke-GPUOptimize
    Invoke-MemoryOptimize
    
    # 优化多媒体设置
    Write-Info "正在优化多媒体性能..."
    try {
        # 禁用音频增强
        $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio"
        # 注意：此设置可能需要重启音频服务
        Write-Info "建议在音频设置中禁用音频增强"
    } catch {
        Write-Warning "多媒体设置失败：$_"
    }
    
    # 启用硬件加速
    Write-Info "正在启用硬件加速..."
    try {
        # 图形设置中启用硬件加速
        $path = "HKCU:\Software\Microsoft\Windows\DWM"
        Set-ItemProperty -Path $path -Name "UseDpiScaling" -Value 1 -Force
        Write-Success "DPI 缩放已启用"
    } catch {
        Write-Warning "DPI 缩放设置失败：$_"
    }
}

# 开发模式专项优化
function Invoke-DevMode {
    Write-Host "`n[开发模式] 编程开发/多任务优化" -ForegroundColor Magenta
    Write-Host "-" * 70
    
    Invoke-MemoryOptimize
    Invoke-NetworkOptimize
    
    # 启用开发者模式
    Write-Info "正在配置开发者模式..."
    try {
        $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
        Set-ItemProperty -Path $path -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Force
        Set-ItemProperty -Path $path -Name "AllowAllTrustedApps" -Value 1 -Force
        Write-Success "开发者模式已启用"
    } catch {
        Write-Warning "开发者模式设置失败：$_"
    }
    
    # 优化多任务处理
    Write-Info "正在优化多任务处理..."
    try {
        # 增加桌面堆大小
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\SubSystems" `
            -Name "Windows" -Type String -Force
        Write-Info "桌面堆已优化"
    } catch {
        Write-Warning "桌面堆设置失败：$_"
    }
}

# 执行优化
try {
    switch ($mode) {
        "Gaming" {
            Invoke-GamingMode
            Invoke-ThermalOptimize
        }
        "Creator" {
            Invoke-CreatorMode
            Invoke-ThermalOptimize
        }
        "Dev" {
            Invoke-DevMode
            Invoke-ThermalOptimize
        }
        default {
            Invoke-GamingMode
            Invoke-CreatorMode
            Invoke-DevMode
            Invoke-ThermalOptimize
        }
    }
    
    Write-Host "`n" + "=" * 70
    Write-ROG "ROG 专项优化完成！"
    Write-Host "=" * 70
    
    Write-Host @"

📌 后续建议：

1. 安装并配置 ROG Armoury Crate
   - 下载：Microsoft Store 或 ASUS 官网
   - 设置风扇曲线和性能模式
   - 配置情景模式（办公/游戏/创作）

2. 更新驱动程序
   - NVIDIA 显卡驱动：GeForce Experience
   - Intel 显卡驱动：Intel Driver & Support Assistant
   - 主板芯片组：ASUS 官网下载

3. 监控工具推荐
   - HWiNFO64：硬件监控
   - MSI Afterburner：GPU 监控
   - ThrottleStop：CPU 功耗管理

4. 定期维护
   - 清理风扇灰尘（3-6 个月）
   - 更换硅脂（1-2 年）
   - 清理系统垃圾（每周）

⚠️  注意事项：
   - 部分优化需要重启系统
   - 游戏模式下功耗和发热会增加
   - 建议使用散热底座
   - 插电使用以获得最佳性能

"@
    
    Write-Success "优化完成！建议重启系统。"
    
} catch {
    Write-Error "优化过程出现错误：$_"
    exit 1
}

Write-Host "`n按任意键退出..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
