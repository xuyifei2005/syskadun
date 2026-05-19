#!/usr/bin/env pwsh
# Windows 11 性能监控脚本
# 实时监控 CPU、内存、磁盘和网络使用情况

param(
    [int]$Interval = 2,  # 刷新间隔（秒）
    [int]$Duration = 0,  # 运行时长（0=持续运行）
    [switch]$ExportLog   # 导出日志
)

# 设置控制台
$Host.UI.RawUI.WindowTitle = "Windows 11 性能监控"
$Host.UI.RawUI.BackgroundColor = "Black"
Clear-Host

# 日志文件
$logFile = "d:\syskadun\performance-log-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

function Write-Monitor {
    param($Message, $Color = "White")
    Write-Host $Message -ForegroundColor $Color -NoNewline
}

function Get-SystemMetrics {
    # CPU 使用率
    $cpu = Get-Counter '\Processor(_Total)\% Processor Time' | Select-Object -ExpandProperty CounterSamples
    $cpuPercent = [math]::Round($cpu.CookedValue, 2)
    
    # 内存使用
    $memory = Get-CimInstance Win32_OperatingSystem
    $totalMemory = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
    $freeMemory = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)
    $usedMemory = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 2)
    $memoryPercent = [math]::Round(($usedMemory / $totalMemory) * 100, 2)
    
    # 磁盘使用率（C 盘）
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskPercent = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 2)
    $diskFree = [math]::Round($disk.FreeSpace / 1GB, 2)
    $diskTotal = [math]::Round($disk.Size / 1GB, 2)
    
    # 进程数
    $processCount = (Get-Process).Count
    
    return @{
        CPUPercent = $cpuPercent
        MemoryUsed = $usedMemory
        MemoryTotal = $totalMemory
        MemoryPercent = $memoryPercent
        DiskPercent = $diskPercent
        DiskFree = $diskFree
        DiskTotal = $diskTotal
        ProcessCount = $processCount
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }
}

function Get-TopProcesses {
    Get-Process | 
        Sort-Object CPU -Descending | 
        Select-Object -First 5 |
        Select-Object Name, 
            @{N='CPU(s)';E={[math]::Round($_.CPU,2)}}, 
            @{N='Memory(MB)';E={[math]::Round($_.WorkingSet/1MB,2)}}
}

function Draw-Gauge {
    param(
        [string]$Label,
        [double]$Percent,
        [int]$Width = 30
    )
    
    $filled = [int]($Percent / 100 * $Width)
    $empty = $Width - $filled
    
    $gauge = "[" + ("█" * $filled) + ("░" * $empty) + "]"
    $color = if ($Percent -lt 70) { "Green" }
             elseif ($Percent -lt 90) { "Yellow" }
             else { "Red" }
    
    Write-Host "$($Label.PadRight(12)) " -NoNewline
    Write-Monitor $gauge $color
    Write-Host " $([math]::Round($Percent, 1))%"
}

# 主循环
Write-Host "Windows 11 性能监控" -ForegroundColor Cyan
Write-Host "=" * 70
Write-Host "间隔：${Interval}s | 时长：$(if($Duration -eq 0){'持续'}else{"$Duration 秒"}) | 日志：$(if($ExportLog){$logFile} else {'关闭'})"
Write-Host "按 Ctrl+C 停止监控"
Write-Host "=" * 70

$startTime = Get-Date
$logData = @()

try {
    while ($true) {
        # 检查运行时长
        if ($Duration -gt 0) {
            $elapsed = (Get-Date) - $startTime
            if ($elapsed.TotalSeconds -ge $Duration) {
                break
            }
        }
        
        # 清空屏幕
        Clear-Host
        
        # 获取指标
        $metrics = Get-SystemMetrics
        
        # 显示时间
        Write-Host "`n 系统性能监控 - $($metrics.Timestamp)" -ForegroundColor Cyan
        Write-Host "=" * 70
        
        # 显示仪表
        Draw-Gauge "CPU" $metrics.CPUPercent
        Draw-Gauge "内存" $metrics.MemoryPercent
        Draw-Gauge "磁盘 C" $metrics.DiskPercent
        
        # 详细信息
        Write-Host "`n详细信息:" -ForegroundColor Yellow
        Write-Host "  CPU:         $($metrics.CPUPercent)%"
        Write-Host "  内存：       $($metrics.MemoryUsed) GB / $($metrics.MemoryTotal) GB ($($metrics.MemoryPercent)%)"
        Write-Host "  磁盘 C:      $($metrics.DiskFree) GB 可用 / $($metrics.DiskTotal) GB ($($metrics.DiskPercent)% 已用)"
        Write-Host "  进程数：     $($metrics.ProcessCount)"
        
        # 顶部进程
        Write-Host "`n资源占用 Top 5 进程:" -ForegroundColor Yellow
        $topProcesses = Get-TopProcesses
        $topProcesses | Format-Table -AutoSize | Out-String | Write-Host
        
        # 记录日志
        if ($ExportLog) {
            $logData += [PSCustomObject]@{
                Timestamp = $metrics.Timestamp
                CPU_Percent = $metrics.CPUPercent
                Memory_Used_GB = $metrics.MemoryUsed
                Memory_Percent = $metrics.MemoryPercent
                Disk_Percent = $metrics.DiskPercent
                Disk_Free_GB = $metrics.DiskFree
                Process_Count = $metrics.ProcessCount
            }
        }
        
        # 等待间隔
        Start-Sleep -Seconds $Interval
    }
}
catch [System.Management.Automation.RuntimeException] {
    # Ctrl+C 中断
    Write-Host "`n`n监控已停止" -ForegroundColor Yellow
}
finally {
    # 导出日志
    if ($ExportLog -and $logData.Count -gt 0) {
        Write-Host "`n正在导出日志到：$logFile" -ForegroundColor Cyan
        $logData | Export-Csv -Path $logFile -NoTypeInformation -Encoding UTF8
        Write-Host "日志导出成功！" -ForegroundColor Green
    }
}
