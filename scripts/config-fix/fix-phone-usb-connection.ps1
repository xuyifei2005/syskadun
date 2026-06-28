# 手机 USB 连接诊断与修复脚本
# 解决插入手机后无法弹出存储、手机端无 USB 模式选择提示的问题

param(
    [switch]$DiagnoseOnly,   # 仅诊断，不修复
    [switch]$FixOnly,        # 仅修复，不诊断
    [switch]$Help,           # 显示帮助
    [switch]$SkipAdbCheck,   # 跳过 ADB 检测（确定电脑上没有 ADB 时使用）
    [switch]$AdbOnly         # 仅运行 ADB 相关诊断和修复
)

# 参数互斥验证
if ($SkipAdbCheck -and $AdbOnly) {
    Write-Host "[ERROR] -SkipAdbCheck 和 -AdbOnly 不能同时使用。" -ForegroundColor Red
    exit 1
}

function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Cyan }
function Write-Success { Write-Host "[SUCCESS] $args" -ForegroundColor Green }
function Write-Warning { Write-Host "[WARNING] $args" -ForegroundColor Yellow }
function Write-Error { Write-Host "[ERROR] $args" -ForegroundColor Red }

function Test-Administrator {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Error "此脚本需要管理员权限运行。请右键 -> 以管理员身份运行 PowerShell，然后重新执行。"
        exit 1
    }
}

# ============================================================
# ADB 相关辅助函数
# ============================================================

function Find-AdbInstallation {
    <#
    .SYNOPSIS
        检测 Windows 上是否安装了 Android Debug Bridge (ADB)
    .DESCRIPTION
        依次检查 PATH、常见安装路径，返回 ADB 安装状态、路径、版本信息
    #>
    $result = [PSCustomObject]@{
        Installed = $false
        Path      = $null
        Version   = $null
        IsInPath  = $false
    }

    # 1. 先检查 PATH
    $fromPath = Get-Command adb -ErrorAction SilentlyContinue
    if ($fromPath) {
        $result.Path      = $fromPath.Source
        $result.Installed = $true
        $result.IsInPath  = $true
    }

    # 2. 如果 PATH 中没有，检查常见安装路径
    if (-not $result.Installed) {
        $candidatePaths = @(
            "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
            "$env:ProgramFiles\platform-tools\adb.exe",
            "${env:ProgramFiles(x86)}\platform-tools\adb.exe",
            "C:\adb\adb.exe",
            "C:\platform-tools\adb.exe",
            "D:\platform-tools\adb.exe",
            "$env:USERPROFILE\adb\adb.exe",
            "$env:USERPROFILE\platform-tools\adb.exe"
        )

        foreach ($p in $candidatePaths) {
            if (Test-Path $p) {
                $result.Path      = $p
                $result.Installed = $true
                $result.IsInPath  = $false
                break
            }
        }
    }

    # 3. 获取版本信息
    if ($result.Installed -and $result.Path) {
        try {
            $verOut = & $result.Path version 2>&1
            if ($verOut -match '(\d+\.\d+\.\d+)') {
                $result.Version = $Matches[1]
            }
        } catch {
            # 版本检测失败不影响诊断流程
        }
    }

    return $result
}

function Test-AdbServerRunning {
    <#
    .SYNOPSIS
        检查 ADB 守护进程是否正在运行
    #>
    param([string]$AdbPath)
    if (-not $AdbPath) { return $false }
    try {
        $out = & $AdbPath devices 2>&1
        return ($out -join "`n") -match 'List of devices attached'
    } catch {
        return $false
    }
}

function Get-UsbDeviceClass {
    <#
    .SYNOPSIS
        对已连接的 USB 设备进行分类：ADB / MTP / RNDIS / PTP / MIDI
    .DESCRIPTION
        通过设备 FriendlyName 和硬件 ID 分类每个 USB 设备
    #>
    $usbDevices = Get-PnpDevice -Class USB -ErrorAction SilentlyContinue
    if (-not $usbDevices) { return @() }

    $results = @()
    foreach ($dev in $usbDevices) {
        $friendlyName = $dev.FriendlyName
        $mode = '其他/未知'

        if ($friendlyName -match 'ADB|Android Debug|Composite ADB|Android Composite') {
            $mode = 'ADB Interface'
        } elseif ($friendlyName -match 'MTP|Portable Device|便携设备|Media Transfer') {
            $mode = 'MTP (文件传输)'
        } elseif ($friendlyName -match 'RNDIS|Remote NDIS|Network') {
            $mode = 'RNDIS (网络共享)'
        } elseif ($friendlyName -match 'PTP|Picture Transfer|Camera|相机') {
            $mode = 'PTP (照片传输)'
        } elseif ($friendlyName -match 'MIDI') {
            $mode = 'MIDI'
        } elseif ($friendlyName -match 'Charging|充电') {
            $mode = '仅充电'
        } elseif ($friendlyName -match 'phone|android|samsung|xiaomi|huawei|oppo|vivo|oneplus|google pixel') {
            # 品牌匹配但不明确模式
            $mode = '手机设备（模式未识别）'
        }

        $results += [PSCustomObject]@{
            InstanceId   = $dev.InstanceId
            FriendlyName = $friendlyName
            Mode         = $mode
            Status       = $dev.Status
        }
    }
    return $results
}

function Stop-AdbServer {
    <#
    .SYNOPSIS
        停止 ADB 服务器，释放 USB 端口供 MTP 使用
    #>
    param([string]$AdbPath)
    if (-not $AdbPath) { return $false }
    try {
        $proc = Start-Process -FilePath $AdbPath -ArgumentList 'kill-server' -Wait -PassThru -NoNewWindow -ErrorAction Stop
        return $proc.ExitCode -eq 0
    } catch {
        Write-Warning "无法停止 ADB 服务器: $_"
        return $false
    }
}

# ============================================================
# 帮助信息
# ============================================================
if ($Help) {
    Write-Host @"
手机 USB 连接诊断与修复工具 (v2)
================================

用法:
  .\fix-phone-usb-connection.ps1                  # 诊断 + 修复
  .\fix-phone-usb-connection.ps1 -DiagnoseOnly    # 仅诊断
  .\fix-phone-usb-connection.ps1 -FixOnly         # 仅修复
  .\fix-phone-usb-connection.ps1 -AdbOnly         # 仅 ADB 相关诊断与修复
  .\fix-phone-usb-connection.ps1 -SkipAdbCheck    # 跳过 ADB 检测

v2 新增功能（针对安装 Termux 后 USB 连接失效）:
  - 检测 Windows 端 ADB 安装和服务状态
  - 区分 ADB Interface 和 MTP 设备模式
  - 停止 adb server 释放 USB 通道
  - Termux 手机端专项排查指南

常见原因:
  1. USB 线缆仅支持充电，不支持数据传输
  2. 手机端默认 USB 配置为"仅充电"（Termux 开启开发者选项后常见）
  3. ADB 服务占用 USB 端口，导致 MTP 无法建立连接
  4. Windows MTP 驱动异常或 ADB 驱动优先级过高
  5. USB 选择性暂停导致端口休眠
  6. 手机未解锁屏幕

"@
    exit 0
}

# ============================================================
# 管理员权限检查
# ============================================================
Test-Administrator

# ============================================================
# 阶段 1: 诊断
# ============================================================

# --- 通用诊断 (跳过 -AdbOnly 模式) ---
if (-not $FixOnly -and -not $AdbOnly) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host "  阶段 1: USB / MTP 连接诊断" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host ""

    # 1.1 检查 MTP 相关设备
    Write-Info "检查设备管理器中便携设备 (MTP) 状态..."
    $mtpDevices = Get-PnpDevice -Class WPD -ErrorAction SilentlyContinue
    $usbDevices = Get-PnpDevice -Class USB -ErrorAction SilentlyContinue

    if ($mtpDevices) {
        Write-Host "  发现以下便携设备 (WPD/MTP):"
        $mtpDevices | ForEach-Object {
            $statusIcon = if ($_.Status -eq 'OK') { '[OK]' } elseif ($_.Status -eq 'Error') { '[ERROR]' } else { "[$($_.Status)]" }
            $statusColor = if ($_.Status -eq 'OK') { 'Green' } else { 'Red' }
            Write-Host "    $statusIcon $($_.FriendlyName) - $($_.Status)" -ForegroundColor $statusColor
        }
    } else {
        Write-Warning "未检测到任何便携设备 (WPD/MTP)。可能原因："
        Write-Host "    - 手机未连接或未解锁"
        Write-Host "    - USB 线缆仅支持充电（请更换数据线）"
        Write-Host "    - 手机端 USB 模式默认为'仅充电'"
        Write-Host "    - ADB 服务占用了 USB 端口（运行 -AdbOnly 检查）"
    }

    # 1.2 检查 USB 设备
    Write-Host ""
    Write-Info "检查 USB 设备连接状态..."
    if ($usbDevices) {
        $phoneMatched = $usbDevices | Where-Object { $_.Status -ne 'OK' -or $_.FriendlyName -match 'phone|android|samsung|xiaomi|huawei|oppo|vivo|oneplus' }
        if ($phoneMatched) {
            $phoneMatched | ForEach-Object {
                Write-Warning "异常/USB 设备: $($_.FriendlyName) - Status: $($_.Status)"
            }
        } else {
            Write-Success "未发现异常 USB 设备"
        }
    }

    # 1.5 (原 1.3) 检查关键服务
    Write-Host ""
    Write-Info "检查关键服务状态..."
    $services = @(
        'WPDBusEnum',      # Portable Device Enumerator Service
        'stisvc',          # Windows Image Acquisition (WIA)
        'ShellHWDetection' # Shell Hardware Detection
    )

    foreach ($svc in $services) {
        $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($service) {
            $statusIcon = if ($service.Status -eq 'Running') { '[OK]' } else { '[STOPPED]' }
            $statusColor = if ($service.Status -eq 'Running') { 'Green' } else { 'Yellow' }
            Write-Host "  $statusIcon $($service.DisplayName) ($svc): $($service.Status)" -ForegroundColor $statusColor
        } else {
            Write-Warning "  服务不存在: $svc"
        }
    }

    # 1.6 (原 1.4) 检查 USB 选择性暂停
    Write-Host ""
    Write-Info "检查 USB 选择性暂停电源设置..."
    $usbSusp = powercfg /query SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 2>&1
    if ($usbSusp -match '0x00000000') {
        Write-Success "USB 选择性暂停: 已禁用"
    } elseif ($usbSusp -match '0x00000001') {
        Write-Warning "USB 选择性暂停: 已启用（可能导致 USB 口休眠）"
    } else {
        Write-Warning "无法读取 USB 选择性暂停设置"
    }

    # 1.7 (原 1.5) 检查设备管理器中的未知设备
    Write-Host ""
    Write-Info "检查设备管理器中的未知/异常设备..."
    $unknownDevices = Get-PnpDevice -Status Error -ErrorAction SilentlyContinue
    if ($unknownDevices) {
        Write-Warning "发现以下异常设备:"
        $unknownDevices | ForEach-Object {
            Write-Host "    [!] $($_.FriendlyName) - Class: $($_.Class) - InstanceId: $($_.InstanceId)"
        }
    } else {
        Write-Success "未发现异常设备"
    }
}

# --- ADB 专项诊断 (当非 FixOnly 且非 SkipAdbCheck 时运行) ---
if (-not $FixOnly -and -not $SkipAdbCheck) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Magenta
    if ($AdbOnly) {
        Write-Host "  阶段 1: ADB 专项诊断" -ForegroundColor Magenta
    } else {
        Write-Host "  ADB 专项诊断 (1.3 / 1.4)" -ForegroundColor Magenta
    }
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host ""

    # 1.3 ADB 安装检测
    Write-Info "检测 Windows 上是否安装了 Android Debug Bridge (ADB)..."
    $adbInfo = Find-AdbInstallation

    if ($adbInfo.Installed) {
        Write-Warning "已检测到 ADB 安装:"
        Write-Host "    路径: $($adbInfo.Path)"
        if ($adbInfo.Version) { Write-Host "    版本: $($adbInfo.Version)" }
        Write-Host "    PATH 中: $($adbInfo.IsInPath)"

        # 检查 ADB 服务状态
        $adbRunning = Test-AdbServerRunning -AdbPath $adbInfo.Path
        if ($adbRunning) {
            Write-Warning "    ADB 服务器状态: 运行中（可能占用 USB 端口，导致 MTP 无法连接！）"
        } else {
            Write-Success "    ADB 服务器状态: 未运行"
        }
    } else {
        Write-Success "未检测到 ADB 安装（Windows 端无 ADB 冲突风险）"
    }

    # 1.4 USB 设备模式分类
    Write-Host ""
    Write-Info "对已连接的 USB 设备进行模式分类..."
    $usbClasses = Get-UsbDeviceClass

    if ($usbClasses.Count -gt 0) {
        # 检查是否有 ADB 模式的设备
        $adbDevices = $usbClasses | Where-Object { $_.Mode -eq 'ADB Interface' }
        $mtpDevices2 = $usbClasses | Where-Object { $_.Mode -eq 'MTP (文件传输)' }
        $otherDevices = $usbClasses | Where-Object { $_.Mode -notin @('ADB Interface', 'MTP (文件传输)') }

        if ($adbDevices) {
            Write-Warning "检测到 ADB Interface 模式的设备:"
            $adbDevices | ForEach-Object {
                Write-Host "    [ADB] $($_.FriendlyName) - Status: $($_.Status)"
            }
            if (-not $mtpDevices2) {
                Write-Warning ">>> 手机当前仅以 ADB 模式连接，无 MTP 模式！"
                Write-Host "    Windows 将手机识别为调试设备而非存储设备，"
                Write-Host "    导致文件传输功能不可用。这正是 Termux 开启"
                Write-Host "    USB 调试后的常见问题。"
                Write-Host "    解决: 手机端 -> 通知栏 USB 通知 -> 选择'文件传输'"
            }
        }

        if ($mtpDevices2) {
            Write-Success "检测到 MTP 模式的设备:"
            $mtpDevices2 | ForEach-Object {
                Write-Host "    [MTP] $($_.FriendlyName) - Status: $($_.Status)"
            }
        }

        if ($otherDevices -and -not $AdbOnly) {
            Write-Host ""
            Write-Info "其他 USB 设备:"
            $otherDevices | ForEach-Object {
                Write-Host "    [$($_.Mode)] $($_.FriendlyName) - Status: $($_.Status)"
            }
        }

        if (-not $adbDevices -and -not $mtpDevices2) {
            Write-Warning "未检测到手机设备（ADB 或 MTP 模式均未发现）"
            Write-Host "    请确保:"
            Write-Host "    - 手机已通过 USB 连接且已解锁屏幕"
            Write-Host "    - USB 数据线支持数据传输"
        }
    } else {
        Write-Warning "未检测到任何 USB 设备连接"
    }
}

# ============================================================
# 阶段 2: 修复
# ============================================================

# --- 通用修复 (跳过 -AdbOnly 模式) ---
if (-not $DiagnoseOnly -and -not $AdbOnly) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host "  阶段 2: 自动修复" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host ""

    # 2.1 确保关键服务运行
    Write-Info "启动关键服务..."
    $servicesToFix = @('WPDBusEnum', 'stisvc', 'ShellHWDetection')
    foreach ($svc in $servicesToFix) {
        try {
            $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
            if ($service -and $service.Status -ne 'Running') {
                Start-Service -Name $svc -ErrorAction Stop
                Write-Success "已启动服务: $svc"
            } elseif ($service) {
                Write-Info "服务已在运行: $svc"
            }
        } catch {
            Write-Warning "无法启动服务 $svc : $_"
        }
    }

    # 2.2 禁用 USB 选择性暂停
    Write-Host ""
    Write-Info "禁用 USB 选择性暂停（防止 USB 口休眠）..."
    try {
        powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>&1 | Out-Null
        powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>&1 | Out-Null
        powercfg /setactive SCHEME_CURRENT 2>&1 | Out-Null
        Write-Success "USB 选择性暂停已禁用（插电 + 电池模式）"
    } catch {
        Write-Warning "无法修改 USB 选择性暂停设置: $_"
    }

    # 2.3 顺序重启 MTP 核心服务（确保干净初始化）
    Write-Host ""
    Write-Info "顺序重启 WPDBusEnum 服务（确保 MTP 干净初始化）..."
    try {
        $wpdService = Get-Service -Name 'WPDBusEnum' -ErrorAction SilentlyContinue
        if ($wpdService -and $wpdService.Status -eq 'Running') {
            Stop-Service -Name 'WPDBusEnum' -Force -ErrorAction Stop
            Write-Info "  已停止 WPDBusEnum"
            Start-Sleep -Seconds 2
        }
        if ($wpdService) {
            Start-Service -Name 'WPDBusEnum' -ErrorAction Stop
            Write-Success "  已重新启动 WPDBusEnum"
        }
    } catch {
        Write-Warning "WPDBusEnum 服务重启失败: $_"
    }

    # 2.4 重启 Windows 资源管理器（刷新 MTP 设备列表）
    Write-Host ""
    Write-Info "重启 Windows 资源管理器以刷新设备列表..."
    try {
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        Start-Process explorer
        Write-Success "Windows 资源管理器已重启"
    } catch {
        Write-Warning "无法重启资源管理器: $_"
    }

    # 2.5 尝试重新扫描硬件
    Write-Host ""
    Write-Info "触发硬件扫描..."
    try {
        $null = pnputil /scan-devices 2>&1
        Write-Success "硬件扫描完成"
    } catch {
        Write-Warning "硬件扫描失败: $_"
    }
}

# --- ADB 专项修复 (当非 DiagnoseOnly 且非 SkipAdbCheck 时运行) ---
if (-not $DiagnoseOnly -and -not $SkipAdbCheck) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Magenta
    if ($AdbOnly) {
        Write-Host "  阶段 2: ADB 专项修复" -ForegroundColor Magenta
    } else {
        Write-Host "  ADB 专项修复 (2.6 / 2.7)" -ForegroundColor Magenta
    }
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host ""

    # 确保有 ADB 信息（如果前面诊断阶段因为 -FixOnly 跳过了诊断）
    if (-not $adbInfo) {
        $adbInfo = Find-AdbInstallation
    }

    # 2.6 停止 ADB 服务器
    if ($adbInfo.Installed) {
        $adbRunning = Test-AdbServerRunning -AdbPath $adbInfo.Path
        if ($adbRunning) {
            Write-Warning "ADB 服务器正在运行，将停止它以释放 USB 端口..."
            Write-Warning "注意: 这会同时断开 Android Studio / scrcpy 等工具的 ADB 连接"
            $stopped = Stop-AdbServer -AdbPath $adbInfo.Path
            if ($stopped) {
                Write-Success "ADB 服务器已停止。USB 端口已释放，请重新插拔手机尝试 MTP 连接。"
            } else {
                Write-Warning "ADB 服务器停止失败，请手动运行: adb kill-server"
            }
        } else {
            Write-Success "ADB 服务器未运行，无需停止"
        }
    } else {
        Write-Info "未安装 ADB，跳过此步骤"
    }

    # 2.7 ADB 驱动切换指引（Windows 设备管理器）
    Write-Host ""
    Write-Info "检查是否需要切换 USB 驱动模式（ADB → MTP）..."
    Write-Host ""
    Write-Host "如果 Windows 设备管理器中将手机识别为"Android Composite ADB Interface""
    Write-Host "而非"MTP USB Device"，请按以下步骤手动切换驱动：" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. 按 Win+X，选择"设备管理器"" -ForegroundColor White
    Write-Host "  2. 找到你的手机（可能在"Android Device"、"便携设备"或"通用串行总线设备"下）" -ForegroundColor White
    Write-Host "  3. 右键点击 → 更新驱动程序 → 浏览我的电脑以查找驱动程序 → 让我从可用驱动列表中选取" -ForegroundColor White
    Write-Host "  4. 在列表中选择"MTP USB Device"（而非 Android Composite ADB Interface）" -ForegroundColor White
    Write-Host "  5. 点击下一步，等待驱动切换完成" -ForegroundColor White
    Write-Host ""
    Write-Info "提示: 切换驱动后需要重新插拔手机才能生效。"

    # 列出可能的 ADB 驱动包
    Write-Host ""
    Write-Info "查询系统中的 ADB 相关驱动包..."
    try {
        $adbDrivers = pnputil /enum-drivers 2>&1 | Select-String -Pattern 'android|adb|google.*usb' -SimpleMatch -AllMatches
        if ($adbDrivers) {
            Write-Host "  发现以下可能相关的驱动包 (.inf):"
            $adbDrivers | Select-Object -First 5 | ForEach-Object {
                Write-Host "    $_"
            }
            Write-Host "  如需删除 ADB 驱动以强制使用 MTP: pnputil /delete-driver <inf名称>"
        } else {
            Write-Info "  未找到 ADB 相关驱动包"
        }
    } catch {
        # pnputil 查询失败不影响主流程
    }
}

# ============================================================
# 阶段 3: 手机端排查指南
# ============================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  手机端排查步骤" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

Write-Host @"
如果以上修复后问题仍存在，请在手机端逐一排查：

1. 【更换 USB 数据线】
   - 很多充电线内部没有数据线芯，只能充电不能传数据
   - 使用原装数据线或确认支持数据传输的第三方线缆
   - 尝试更换线缆后重新插拔

2. 【更换 USB 端口】
   - 优先使用电脑机箱背面的 USB 口（直接连主板）
   - 避免使用 USB Hub 或延长线
   - 台式机优先用 USB 2.0（黑色）口，兼容性更好

3. 【解锁手机屏幕】
   - 确保手机已解锁（亮屏状态下插入 USB）
   - 部分手机锁屏状态下不会弹出 USB 模式选择

4. 【检查手机 USB 默认配置】
   Android 手机路径：
   - 设置 -> 开发者选项 -> 默认 USB 配置 -> 选择"文件传输/MTP"
   （如未开启开发者选项：设置 -> 关于手机 -> 连续点击"版本号"7次）

   - 部分手机（小米/红米）：
     设置 -> 更多设置 -> 开发者选项 -> USB 调试（开启）
     -> 默认 USB 配置 -> 文件传输

   - 华为/荣耀：
     设置 -> 关于手机 -> 连续点击版本号 -> 开发者选项
     -> 选择 USB 配置 -> MTP（媒体传输协议）

5. 【重新插拔 + 观察通知栏】
   - 拔出手机，等待 5 秒
   - 重新插入，观察手机通知栏是否出现"USB 正在充电"
   - 点击该通知，手动选择"文件传输"或"MTP"

6. 【重启手机 + 电脑】
   - 有时简单的重启能解决大部分驱动/协议问题

"@ -ForegroundColor Yellow

Write-Host "--- Termux 专项排查 ---" -ForegroundColor Cyan
Write-Host ""

Write-Host @"
7. 【Termux 安装后的 USB 连接失效 — 专项修复】

   ▸ 7a. 开发者选项中的 USB 默认配置（最常见原因！）
      Termux 要求开启开发者选项和 USB 调试，
      这会导致默认 USB 配置被改成"仅充电"：
      设置 → 开发者选项 → 默认 USB 配置 → 选择"文件传输"

   ▸ 7b. 检查 Termux 中是否安装了 ADB 工具
      在 Termux 中执行：pkg list-installed | grep adb
      如果安装了 termux-adb 或 android-tools：
      - 运行: adb kill-server（停止 adbd 占用的 USB 端口）
      - 或者在 Termux 中执行: pkg uninstall termux-adb

   ▸ 7c. 临时关闭 USB 调试，确认 MTP 是否恢复
      设置 → 开发者选项 → USB 调试 → 暂时关闭
      → 拔出并重新插入手机 → 观察是否弹出 MTP 文件传输
      如果 MTP 恢复，说明电脑端 ADB 驱动优先级过高
      （参考阶段 2 的 ADB 驱动切换指引）

   ▸ 7d. 通知栏手动切换 USB 模式
      插入手机后下拉通知栏 → 点击"USB 正在充电"通知
      → 选择"文件传输"或"MTP"（这会覆盖默认配置）

   ▸ 7e. 先插线后解锁
      先把 USB 线插入手机，再解锁屏幕
      这样系统会在解锁瞬间弹出 USB 模式选择

"@ -ForegroundColor Yellow

Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

# 根据检测结果输出总结建议
if ($adbInfo -and $adbInfo.Installed) {
    $adbRunningNow = Test-AdbServerRunning -AdbPath $adbInfo.Path
    if ($adbRunningNow) {
        Write-Warning "诊断与修复完毕。ADB 服务器仍在运行，建议手机端优先排查 USB 默认配置。"
    } else {
        Write-Info "诊断与修复完毕。ADB 端无冲突，建议优先检查手机端的 USB 默认配置。"
    }
} else {
    Write-Info "诊断与修复完毕。如果问题仍未解决，请优先检查 USB 数据线是否支持数据传输。"
}
Write-Host "========================================" -ForegroundColor Magenta