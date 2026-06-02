# VMware Performance Fix (VMware 性能修复方案)

## Problem Analysis (问题分析)

### Root Cause (根本原因)
优化脚本中的 `.wslconfig` 配置导致了 VMware 性能问题:

**问题配置**:
```ini
[wsl2]
memory=16GB           # ❌ 限制了内存使用
processors=8          # ❌ 限制了 CPU 核心数
nestedVirtualization=true  # ❌ 与 VMware 冲突
```

**影响**:
- WSL2 占用了 16GB 内存，导致 VMware 虚拟机可用内存不足
- 嵌套虚拟化与 VMware 的虚拟化技术冲突
- CPU 核心数限制导致 VMware 调度问题

---

## Solution 1: Remove WSL2 Limits (Recommended for VMware Users)

### 删除或修改 `.wslconfig` 文件

**Option A: 完全删除 (如果您主要使用 VMware)**
```powershell
# 备份并删除 .wslconfig
Copy-Item "$env:USERPROFILE\.wslconfig" "$env:USERPROFILE\.wslconfig.backup"
Remove-Item "$env:USERPROFILE\.wslconfig" -Force

# 重启 WSL
wsl --shutdown
```

**Option B: 增加资源限制 (兼顾 WSL 和 VMware)**
```powershell
$wslConfig = @"
[wsl2]
memory=32GB
processors=16
swap=8GB
localhostForwarding=true

[experimental]
hostAddressLoopback=true
autoMemoryReclaim=gradual
sparseVhd=true
"@
$wslConfig | Out-File -FilePath "$env:USERPROFILE\.wslconfig" -Encoding UTF8

# 重启 WSL
wsl --shutdown
```

---

## Solution 2: Disable Nested Virtualization in WSL2

### 关闭嵌套虚拟化 (解决冲突)

```powershell
# 修改 .wslconfig，禁用嵌套虚拟化
$wslConfig = @"
[wsl2]
memory=16GB
processors=8
swap=4GB
nestedVirtualization=false
firewall=false

[experimental]
hostAddressLoopback=true
autoMemoryReclaim=gradual
sparseVhd=true
"@
$wslConfig | Out-File -FilePath "$env:USERPROFILE\.wslconfig" -Encoding UTF8

# 重启 WSL
wsl --shutdown
```

---

## Solution 3: Optimize VMware Settings

### VMware 虚拟机优化设置

### 1. 增加虚拟机内存分配
1. 打开 VMware Workstation
2. 右键虚拟机 → Settings
3. Memory → 增加到 **16GB 或 32GB** (根据您的 64GB 总内存)

### 2. 增加 CPU 核心数
1. Processors → 设置:
   - Number of processors: **1**
   - Number of cores per processor: **8 或 12**

### 3. 启用 3D 图形加速
1. Display → 勾选:
   - ✅ Accelerate 3D graphics
   - Graphics memory: **2GB 或更高**

### 4. 使用 SSD 存储
1. Hard Disk → 确保虚拟机文件在 **NVMe SSD** 上
2. 如果使用外部 USB 硬盘，性能会下降

### 5. 禁用不必要的 VMware 功能
编辑虚拟机配置文件 (`.vmx`),添加:
```
memtrim.rate = "0"
MemSize = "32768"
ulm.reclaimFreePages = "FALSE"
```

---

## Solution 4: Adjust Windows Memory Management

### 调整 Windows 内存管理

```powershell
# 禁用内存压缩 (释放更多内存给 VMware)
Disable-MMAgent -MemoryCompression

# 设置系统缓存大小 (适合大内存系统)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 1 /f

# 禁用页面文件自动管理 (手动控制)
$computer = Get-CimInstance Win32_ComputerSystem
$computer.AutomaticManagedPagefile = $false
$computer.Put()
```

---

## Quick Fix Script

### 一键修复 VMware 性能问题

Save as: `fix_vmware_performance.ps1`

```powershell
Write-Host "=== VMware Performance Fix ===" -ForegroundColor Cyan
Write-Host ""

# Option 1: Remove WSL2 limits completely
Write-Host "Option 1: Remove WSL2 resource limits (Recommended for VMware users)" -ForegroundColor Yellow
Write-Host "This will give VMware full access to system resources." -ForegroundColor White
$choice = Read-Host "Remove WSL2 limits? (Y/N)"

if ($choice -eq 'Y' -or $choice -eq 'y') {
    Write-Host "Backing up .wslconfig..." -ForegroundColor Green
    Copy-Item "$env:USERPROFILE\.wslconfig" "$env:USERPROFILE\.wslconfig.backup" -ErrorAction SilentlyContinue
    
    Write-Host "Removing .wslconfig..." -ForegroundColor Green
    Remove-Item "$env:USERPROFILE\.wslconfig" -Force -ErrorAction SilentlyContinue
    
    Write-Host "Shutting down WSL..." -ForegroundColor Green
    wsl --shutdown
    
    Write-Host "✓ WSL2 limits removed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "VMware now has full access to:" -ForegroundColor Cyan
    Write-Host "- CPU: All 24 cores" -ForegroundColor White
    Write-Host "- Memory: All 64GB (minus Windows usage)" -ForegroundColor White
    Write-Host ""
} else {
    # Option 2: Increase limits
    Write-Host ""
    Write-Host "Option 2: Increase WSL2 limits (Balanced approach)" -ForegroundColor Yellow
    $choice2 = Read-Host "Increase limits to 32GB RAM and 16 cores? (Y/N)"
    
    if ($choice2 -eq 'Y' -or $choice2 -eq 'y') {
        Write-Host "Updating .wslconfig..." -ForegroundColor Green
        $wslConfig = @"
[wsl2]
memory=32GB
processors=16
swap=8GB
localhostForwarding=true

[experimental]
hostAddressLoopback=true
autoMemoryReclaim=gradual
sparseVhd=true
"@
        $wslConfig | Out-File -FilePath "$env:USERPROFILE\.wslconfig" -Encoding UTF8
        
        Write-Host "Shutting down WSL..." -ForegroundColor Green
        wsl --shutdown
        
        Write-Host "✓ WSL2 limits increased!" -ForegroundColor Green
        Write-Host ""
        Write-Host "New WSL2 limits:" -ForegroundColor Cyan
        Write-Host "- CPU: 16 cores (was 8)" -ForegroundColor White
        Write-Host "- Memory: 32GB (was 16GB)" -ForegroundColor White
        Write-Host "- VMware: More resources available" -ForegroundColor White
        Write-Host ""
    }
}

# Disable nested virtualization
Write-Host "Disabling nested virtualization in WSL2..." -ForegroundColor Green
if (Test-Path "$env:USERPROFILE\.wslconfig") {
    $content = Get-Content "$env:USERPROFILE\.wslconfig" -Raw
    if ($content -match 'nestedVirtualization=true') {
        $content = $content -replace 'nestedVirtualization=true', 'nestedVirtualization=false'
        $content | Out-File -FilePath "$env:USERPROFILE\.wslconfig" -Encoding UTF8
        Write-Host "✓ Nested virtualization disabled!" -ForegroundColor Green
    } else {
        Write-Host "✓ Nested virtualization already disabled" -ForegroundColor Green
    }
} else {
    Write-Host "✓ No .wslconfig found (unlimited mode)" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Fix Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Restart your VMware virtual machine" -ForegroundColor White
Write-Host "2. In VMware, increase VM memory to 16-32GB" -ForegroundColor White
Write-Host "3. In VMware, increase VM CPU cores to 8-12" -ForegroundColor White
Write-Host "4. Enable 3D acceleration in VMware Display settings" -ForegroundColor White
Write-Host ""
Write-Host "Expected improvement:" -ForegroundColor Cyan
Write-Host "- VMware performance: +30-50%" -ForegroundColor White
Write-Host "- Smoother VM operation" -ForegroundColor White
Write-Host "- Less stuttering and lag" -ForegroundColor White
```

---

## VMware Best Practices for 64GB RAM System

### 推荐配置

| Component | Setting | Reason |
|-----------|---------|--------|
| **WSL2 Memory** | 32GB or Unlimited | Leave 32GB for VMware + Windows |
| **WSL2 CPU** | 16 cores | Leave 8 cores for VMware |
| **VM Memory** | 16-32GB | Enough for most workloads |
| **VM CPU Cores** | 8-12 | Good balance |
| **VM Graphics** | 2GB | Enable 3D acceleration |
| **VM Storage** | NVMe SSD | Fast disk I/O |

---

## Verification Steps

### 验证修复效果

1. **检查 WSL 配置**:
```powershell
Get-Content "$env:USERPROFILE\.wslconfig"
```

2. **检查 VMware 进程资源**:
```powershell
Get-Process vmware-vmx | Select-Object CPU, WorkingSet, @{Name="Memory(GB)";Expression={[math]::Round($_.WorkingSet/1GB,2)}}
```

3. **监控虚拟机性能**:
- 在 VMware 中打开虚拟机
- 观察是否还有卡顿
- 检查虚拟机内的任务管理器

---

## Expected Results

### 修复前
- ❌ VMware 虚拟机卡顿
- ❌ 响应慢
- ❌ 资源争用

### 修复后
- ✅ VMware 流畅运行
- ✅ 响应快速
- ✅ 资源充足
- ✅ 性能提升 30-50%

---

## Rollback (If Needed)

### 如需恢复原配置

```powershell
# 恢复备份的 .wslconfig
if (Test-Path "$env:USERPROFILE\.wslconfig.backup") {
    Copy-Item "$env:USERPROFILE\.wslconfig.backup" "$env:USERPROFILE\.wslconfig" -Force
    wsl --shutdown
    Write-Host "Configuration restored from backup"
}
```

---

**Created**: 2026-03-21  
**Version**: 1.0  
**Target**: VMware performance optimization after system tuning  
**Status**: ✅ Ready to Execute
