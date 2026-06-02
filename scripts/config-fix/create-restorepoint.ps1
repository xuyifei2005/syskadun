#!/usr/bin/env pwsh
# 创建系统还原点脚本
# 在执行优化前使用

function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Cyan }
function Write-Success { Write-Host "[SUCCESS] $args" -ForegroundColor Green }
function Write-Error { Write-Host "[ERROR] $args" -ForegroundColor Red }

# 检查管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Error "请以管理员身份运行此脚本！"
    exit 1
}

Write-Info "正在创建系统还原点..."

# 启用系统保护（如果未启用）
$drive = Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty SystemDrive
Write-Info "系统盘：$drive"

try {
    # 创建还原点
    $restorePoint = @{
        Description = "Windows 11 性能优化前备份 - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        RestorePointType = 12  # MODIFY_SETTINGS
        EventType = 100        # BEGIN_SYSTEM_CHANGE
    }
    
    Checkpoint-Computer @restorePoint
    
    Write-Success "系统还原点创建成功！"
    Write-Info "还原点名称：$($restorePoint.Description)"
    Write-Info "`n如需还原系统："
    Write-Info "1. 搜索并打开'创建还原点'"
    Write-Info "2. 点击'系统还原'按钮"
    Write-Info "3. 选择刚才创建的还原点"
    
} catch {
    Write-Error "创建还原点失败：$_"
    Write-Info "请检查系统保护是否已启用"
    Write-Info "控制面板 -> 系统 -> 系统保护 -> 配置"
}

Write-Host "`n按任意键退出..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
