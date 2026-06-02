# C 盘空间监控脚本 - English Version (避免编码问题)
# Usage: .\monitor_c_drive.ps1

$ErrorActionPreference = 'SilentlyContinue'

# Get C drive info
$drive = Get-PSDrive C
$freeGB = [math]::Round($drive.Free / 1GB, 2)
$usedGB = [math]::Round($drive.Used / 1GB, 2)
$totalGB = [math]::Round(($drive.Used + $drive.Free) / 1GB, 2)
$usedPercent = [math]::Round(($drive.Used / ($drive.Used + $drive.Free)) * 100, 2)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  C: Drive Monitoring Report" -ForegroundColor Cyan
Write-Host "  Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "[INFO] Storage Statistics:" -ForegroundColor Yellow
Write-Host "  Total Capacity: $totalGB GB"
Write-Host "  Used: $usedGB GB ($usedPercent %)"
Write-Host "  Free Space: $freeGB GB"
Write-Host ""

# Threshold alerts
if ($usedPercent -gt 90) {
    Write-Host "[CRITICAL] C: Drive usage exceeds 90%!" -ForegroundColor Red
    Write-Host "   Recommend immediate cleanup or file migration!" -ForegroundColor Red
    Write-Host ""
} elseif ($usedPercent -gt 85) {
    Write-Host "[WARNING] C: Drive usage exceeds 85%!" -ForegroundColor Red
    Write-Host "   Recommend cleanup or file migration" -ForegroundColor Yellow
    Write-Host ""
} elseif ($usedPercent -gt 75) {
    Write-Host "[NOTICE] C: Drive usage exceeds 75%" -ForegroundColor Yellow
    Write-Host "   Monitor space usage" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "[OK] C: Drive space is sufficient" -ForegroundColor Green
    Write-Host ""
}

# Show top 10 folders
Write-Host "[INFO] Top 10 Largest Folders:" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Gray

$topFolders = Get-ChildItem -Path "C:\" -Directory -ErrorAction SilentlyContinue | 
Where-Object { $_.PSIsContainer } |
ForEach-Object {
    try {
        $size = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | 
                 Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1GB
        if ($size -gt 0.1) {
            [PSCustomObject]@{
                Name = $_.Name
                Path = $_.FullName
                SizeGB = [math]::Round($size, 2)
            }
        }
    } catch {
        # Ignore access errors
    }
} | Sort-Object SizeGB -Descending | Select-Object -First 10

if ($topFolders) {
    $topFolders | Format-Table -Property Name, SizeGB, Path -AutoSize
} else {
    Write-Host "  Unable to get folder sizes (may require admin privileges)" -ForegroundColor Yellow
}

# Cleanup suggestions
Write-Host "`n[TIP] Quick Cleanup Suggestions:" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Gray

$suggestions = @()

# Check temp files
$tempSize = 0
$tempPaths = @("$env:TEMP", "$env:TMP", "C:\Windows\Temp")
foreach ($path in $tempPaths) {
    if (Test-Path $path) {
        $tempSize += (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | 
                      Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1MB
    }
}
if ($tempSize -gt 100) {
    $suggestions += "Temp files: $([math]::Round($tempSize, 2)) MB - Run scheduled_cleanup.ps1"
}

# Check Recycle Bin
try {
    $recycleBin = (New-Object -ComObject Shell.Application).Namespace(10)
    $recycleBinSize = ($recycleBin.Items() | Measure-Object -Property Size -Sum).Sum / 1GB
    if ($recycleBinSize -gt 1) {
        $suggestions += "Recycle Bin: $([math]::Round($recycleBinSize, 2)) GB - Empty Recycle Bin"
    }
} catch {}

# Check Windows Update cache
try {
    $wuSize = (Get-ChildItem "C:\Windows\SoftwareDistribution\Download" -Recurse -ErrorAction SilentlyContinue | 
               Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1MB
    if ($wuSize -gt 500) {
        $suggestions += "Update cache: $([math]::Round($wuSize, 2)) MB - Run scheduled_cleanup.ps1"
    }
} catch {}

if ($suggestions.Count -gt 0) {
    foreach ($suggestion in $suggestions) {
        Write-Host "  * $suggestion" -ForegroundColor Yellow
    }
} else {
    Write-Host "  No special cleanup needed, space usage is normal" -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Monitoring Complete" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan
Write-Host ""
Write-Host "[NOTE] Configuration guides saved to:" -ForegroundColor Green
Write-Host "  1. prevent_c_drive_fill_guide.md" -ForegroundColor Cyan
Write-Host "  2. configuration_checklist.md" -ForegroundColor Cyan
Write-Host "  3. scheduled_cleanup.ps1" -ForegroundColor Cyan
Write-Host ""
