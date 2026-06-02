# WSL2与VMware共存配置脚本

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "WSL2与VMware共存配置工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Stop"

function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Show-Menu {
    Write-Host "请选择配置选项：" -ForegroundColor Yellow
    Write-Host "1. 配置WSL2优化参数" -ForegroundColor White
    Write-Host "2. 配置VMware网络为桥接模式" -ForegroundColor White
    Write-Host "3. 禁用VMware NAT服务" -ForegroundColor White
    Write-Host "4. 启用VMware NAT服务" -ForegroundColor White
    Write-Host "5. 查看当前配置状态" -ForegroundColor White
    Write-Host "6. 重启WSL2" -ForegroundColor White
    Write-Host "7. 完整配置（推荐）" -ForegroundColor Green
    Write-Host "0. 退出" -ForegroundColor Red
    Write-Host ""
}

function Configure-WSL2 {
    Write-Host "正在配置WSL2..." -ForegroundColor Yellow
    
    $wslConfigPath = "$env:USERPROFILE\.wslconfig"
    $backupPath = "$env:USERPROFILE\.wslconfig.backup"
    
    if (Test-Path $wslConfigPath) {
        Write-Host "发现现有WSL2配置文件，正在备份..." -ForegroundColor Cyan
        Copy-Item $wslConfigPath $backupPath -Force
        Write-Host "备份文件：$backupPath" -ForegroundColor Green
    }
    
    $configContent = @"
[wsl2]
networkingMode=mirrored
memory=16GB
processors=8
swap=4GB
nestedVirtualization=true
firewall=false

[experimental]
hostAddressLoopback=true
autoMemoryReclaim=gradual
sparseVhd=true
"@
    
    $configContent | Out-File -FilePath $wslConfigPath -Encoding utf8 -Force
    Write-Host "WSL2配置文件已更新：$wslConfigPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "配置内容：" -ForegroundColor Cyan
    Get-Content $wslConfigPath | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
    Write-Host ""
}

function Configure-VMwareNetwork {
    Write-Host "正在配置VMware网络..." -ForegroundColor Yellow
    Write-Host "请手动执行以下步骤：" -ForegroundColor Cyan
    Write-Host "1. 打开VMware Workstation" -ForegroundColor White
    Write-Host "2. 点击 编辑 → 虚拟网络编辑器" -ForegroundColor White
    Write-Host "3. 选择VMnet8，改为桥接模式" -ForegroundColor White
    Write-Host "4. 选择物理网卡（如WLAN）" -ForegroundColor White
    Write-Host "5. 点击确定保存设置" -ForegroundColor White
    Write-Host ""
}

function Disable-VMwareNAT {
    if (-not (Test-Admin)) {
        Write-Host "需要管理员权限，请以管理员身份运行此脚本" -ForegroundColor Red
        return
    }
    
    Write-Host "正在禁用VMware NAT服务..." -ForegroundColor Yellow
    
    try {
        $service = Get-Service -Name "VMware NAT Service" -ErrorAction SilentlyContinue
        if ($service) {
            Set-Service -Name "VMware NAT Service" -StartupType Manual
            Write-Host "VMware NAT服务已设置为手动启动" -ForegroundColor Green
        } else {
            Write-Host "未找到VMware NAT服务" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "配置VMware NAT服务失败：$_" -ForegroundColor Red
    }
    
    Write-Host ""
}

function Enable-VMwareNAT {
    if (-not (Test-Admin)) {
        Write-Host "需要管理员权限，请以管理员身份运行此脚本" -ForegroundColor Red
        return
    }
    
    Write-Host "正在启用VMware NAT服务..." -ForegroundColor Yellow
    
    try {
        $service = Get-Service -Name "VMware NAT Service" -ErrorAction SilentlyContinue
        if ($service) {
            Set-Service -Name "VMware NAT Service" -StartupType Automatic
            Start-Service -Name "VMware NAT Service" -ErrorAction SilentlyContinue
            Write-Host "VMware NAT服务已设置为自动启动" -ForegroundColor Green
        } else {
            Write-Host "未找到VMware NAT服务" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "配置VMware NAT服务失败：$_" -ForegroundColor Red
    }
    
    Write-Host ""
}

function Show-Status {
    Write-Host "当前配置状态：" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "WSL2配置：" -ForegroundColor Cyan
    $wslConfigPath = "$env:USERPROFILE\.wslconfig"
    if (Test-Path $wslConfigPath) {
        Write-Host "  配置文件：$wslConfigPath" -ForegroundColor Green
        Write-Host "  配置内容：" -ForegroundColor White
        Get-Content $wslConfigPath | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
    } else {
        Write-Host "  未找到WSL2配置文件" -ForegroundColor Yellow
    }
    Write-Host ""
    
    Write-Host "WSL2状态：" -ForegroundColor Cyan
    try {
        $wslStatus = wsl --status 2>&1
        Write-Host "  $wslStatus" -ForegroundColor White
    } catch {
        Write-Host "  无法获取WSL2状态" -ForegroundColor Yellow
    }
    Write-Host ""
    
    Write-Host "VMware服务：" -ForegroundColor Cyan
    $vmwareServices = Get-Service | Where-Object {$_.Name -like '*vmware*'}
    if ($vmwareServices) {
        $vmwareServices | ForEach-Object {
            $statusColor = if ($_.Status -eq 'Running') { 'Green' } else { 'Yellow' }
            Write-Host "  $($_.DisplayName): $($_.Status)" -ForegroundColor $statusColor
        }
    } else {
        Write-Host "  未找到VMware服务" -ForegroundColor Yellow
    }
    Write-Host ""
    
    Write-Host "VMware网络适配器：" -ForegroundColor Cyan
    $vmwareAdapters = Get-NetAdapter | Where-Object {$_.InterfaceDescription -like '*VMware*'}
    if ($vmwareAdapters) {
        $vmwareAdapters | ForEach-Object {
            Write-Host "  $($_.Name): $($_.LinkSpeed)" -ForegroundColor White
        }
    } else {
        Write-Host "  未找到VMware网络适配器" -ForegroundColor Yellow
    }
    Write-Host ""
    
    Write-Host "虚拟化状态：" -ForegroundColor Cyan
    $hyperV = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue
    if ($hyperV) {
        $stateColor = if ($hyperV.State -eq 'Enabled') { 'Green' } else { 'Yellow' }
        Write-Host "  Hyper-V: $($hyperV.State)" -ForegroundColor $stateColor
    } else {
        Write-Host "  无法获取Hyper-V状态（需要管理员权限）" -ForegroundColor Yellow
    }
    Write-Host ""
}

function Restart-WSL2 {
    Write-Host "正在重启WSL2..." -ForegroundColor Yellow
    wsl --shutdown
    Start-Sleep -Seconds 2
    Write-Host "WSL2已关闭，请手动启动：wsl" -ForegroundColor Green
    Write-Host ""
}

function Full-Configuration {
    Write-Host "开始完整配置..." -ForegroundColor Green
    Write-Host ""
    
    Configure-WSL2
    Write-Host "按任意键继续配置VMware网络..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    Configure-VMwareNetwork
    Write-Host "按任意键继续配置VMware NAT服务..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    Disable-VMwareNAT
    
    Write-Host "完整配置完成！" -ForegroundColor Green
    Write-Host ""
    Write-Host "后续步骤：" -ForegroundColor Yellow
    Write-Host "1. 重启计算机" -ForegroundColor White
    Write-Host "2. 启动WSL2：wsl" -ForegroundColor White
    Write-Host "3. 启动VMware虚拟机" -ForegroundColor White
    Write-Host "4. 验证网络连接" -ForegroundColor White
    Write-Host ""
}

do {
    Show-Menu
    $choice = Read-Host "请输入选项"
    
    switch ($choice) {
        "1" { Configure-WSL2 }
        "2" { Configure-VMwareNetwork }
        "3" { Disable-VMwareNAT }
        "4" { Enable-VMwareNAT }
        "5" { Show-Status }
        "6" { Restart-WSL2 }
        "7" { Full-Configuration }
        "0" { 
            Write-Host "退出配置工具" -ForegroundColor Green
            break 
        }
        default { 
            Write-Host "无效选项，请重新选择" -ForegroundColor Red
            Write-Host ""
        }
    }
    
    if ($choice -ne "0") {
        Write-Host "按任意键继续..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        Clear-Host
    }
} while ($true)
