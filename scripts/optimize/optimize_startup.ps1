# Windows 11 启动项优化脚本
# 禁用不必要的开机自启项以提升开机速度

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Windows 11 启动项优化脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 需要禁用的启动项列表
$itemsToDisable = @(
    "Ollama",
    "CanvaAutoLaunchAvailabilityCheckAgent",
    "QuarkUpdaterTaskUser1.0.0.21",
    "闪电说",
    "CC Switch",
    "ESHOW_Sev",
    "BaiduYunDetect",
    "Virtual Pet",
    "NewPeanuthull"
)

Write-Host "即将禁用的启动项：" -ForegroundColor Yellow
foreach ($item in $itemsToDisable) {
    Write-Host "  - $item" -ForegroundColor Gray
}
Write-Host ""

# 通过注册表禁用启动项
$registryPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
)

Write-Host "开始优化..." -ForegroundColor Green
Write-Host ""

foreach ($regPath in $registryPaths) {
    if (Test-Path $regPath) {
        $items = Get-ItemProperty -Path $regPath
        foreach ($itemName in $itemsToDisable) {
            $property = Get-ItemProperty -Path $regPath -Name $itemName -ErrorAction SilentlyContinue
            if ($property) {
                Remove-ItemProperty -Path $regPath -Name $itemName -Force
                Write-Host "[已禁用] $itemName (位置：$regPath)" -ForegroundColor Green
            }
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "启动项优化完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "提示：部分应用（如 QQ、Feishu、Docker 等）保留为启动项，" -ForegroundColor Yellow
Write-Host "      如不需要可在应用内设置中禁用开机自启。" -ForegroundColor Yellow
Write-Host ""
Write-Host "重启后生效！" -ForegroundColor Cyan
