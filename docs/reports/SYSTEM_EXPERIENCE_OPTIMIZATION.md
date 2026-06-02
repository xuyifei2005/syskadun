# 系统体验优化分析报告

**生成时间**: 2026-03-20 19:30  
**系统**: Windows 11 Home China (Build 29550)  
**设备**: Intel Core Ultra 9 275HX + 64GB RAM

---

## 🖥️ 系统硬件配置

### 处理器
- **型号**: Intel Core Ultra 9 275HX
- **核心数**: 24 核心
- **线程数**: 24 线程
- **基础频率**: 2.7 GHz

### 内存
- **总容量**: 64 GB (32GB × 2)
- **类型**: DDR5
- **频率**: 5600 MHz
- **制造商**: Micron Technology
- **配置**: 双通道

### 存储
| 盘符 | 标签 | 总容量 | 已用 | 剩余 | 使用率 | 类型 |
|------|------|--------|------|------|--------|------|
| C: | OS | 924 GB | 825 GB | 99 GB | **89.3%** 🔴 | NVMe SSD |
| D: | DATES | 1863 GB | 1638 GB | 225 GB | **87.9%** ⚠️ | NVMe SSD |
| F: | DATA2 | 1863 GB | 1228 GB | 635 GB | 65.9% | NVMe SSD |
| E: | UEFI_NTFS | - | - | - | - | USB3.0 |

### 网络
- **类型**: WiFi (5G 频段)
- **网络类别**: 专用网络
- **连接状态**: 已连接互联网

---

## 📊 当前系统状态

### 运行时间
- **系统启动时间**: 需要检查
- **建议**: 如超过 7 天，建议重启释放内存

### 内存使用
- **Docker WSL2**: 4.9 GB
- **系统压缩**: 3.09 GB
- **Obsidian**: 1.91 GB
- **Trae**: ~3.2 GB

### 启动项 (17 个)
- CC Switch
- Claude
- Docker Desktop
- Everything
- Feishu (飞书)
- Figma Agent
- GameViewer
- ldremote (雷电模拟器)
- MuMuNxMain (MuMu 模拟器)
- NVIDIA Broadcast
- Ollama
- QQNT
- SecurityHealth
- sysdiag (火绒)
- Virtual Pet (华硕)
- 闪电说
- 网易邮箱大师

---

## 🎯 体验优化建议

### 【性能优化】⭐⭐⭐⭐⭐

#### 1. 电源模式优化
**当前**: 未知  
**建议**: 高性能模式

**操作步骤**:
```powershell
# 查看当前电源计划
powercfg /list

# 设置为高性能模式
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
```

**预期效果**: 
- CPU 性能提升 10-15%
- 响应速度更快
- 功耗增加

---

#### 2. 虚拟内存优化
**当前**: C 盘（未知大小）  
**建议**: 迁移到 D 盘，设置固定大小

**配置建议**:
- **初始大小**: 8192 MB (8GB)
- **最大值**: 16384 MB (16GB)
- **位置**: D:\pagefile.sys

**操作步骤**:
1. 系统属性 → 高级 → 性能 → 设置
2. 高级 → 虚拟内存 → 更改
3. 取消"自动管理"
4. C 盘：无分页文件
5. D 盘：系统管理的大小 或 自定义 8-16GB

**预期效果**:
- C 盘释放 4-8GB
- 系统更稳定
- 减少 C 盘碎片

---

#### 3. 启动项优化
**当前**: 17 个启动项  
**建议**: 禁用不常用的，保留必要的

**建议保留**:
- ✅ SecurityHealth (Windows 安全)
- ✅ sysdiag (火绒安全)
- ✅ Docker Desktop (如常用)
- ✅ Everything (如常用)

**建议禁用**:
- ❌ GameViewer (不常用)
- ❌ MuMuNxMain (模拟器，占用资源)
- ❌ ldremote (雷电模拟器)
- ❌ Virtual Pet (华硕宠物)
- ❌ 网易邮箱大师 (可手动启动)
- ❌ 闪电说 (不常用)

**操作步骤**:
1. 任务管理器 (Ctrl+Shift+Esc)
2. 启动 选项卡
3. 右键禁用不需要的

**预期效果**:
- 启动速度提升 5-10 秒
- 开机内存占用减少 500MB-1GB
- CPU 空闲时更安静

---

### 【存储优化】⭐⭐⭐⭐⭐

#### 4. C 盘紧急清理
**当前**: 89.3% 使用率 (99GB 剩余)  
**目标**: 降至 75% 以下 (至少 150GB 剩余)

**立即执行**:
```powershell
# 运行快速清理脚本
.\quick_cleanup.ps1
```

**预期效果**: 释放 60-70GB

---

#### 5. D 盘整理
**当前**: 87.9% 使用率 (225GB 剩余)  
**建议**: 迁移非关键数据到 F 盘

**可迁移项目**:
- 下载文件夹
- 文档/图片/视频
- 项目文件
- Docker 数据

**操作步骤**:
```powershell
# 创建目录结构
New-Item -ItemType Directory -Path "F:\Backup\Documents" -Force
New-Item -ItemType Directory -Path "F:\Backup\Downloads" -Force
New-Item -ItemType Directory -Path "F:\Docker" -Force
```

---

#### 6. 存储感知配置
**建议**: 开启 Windows 存储感知

**操作步骤**:
1. 设置 → 系统 → 存储
2. 开启"存储感知"
3. 配置:
   - 临时文件：删除
   - 回收站：30 天后删除
   - 下载文件夹：60 天后删除

**预期效果**: 自动清理，保持空间

---

### 【系统优化】⭐⭐⭐⭐

#### 7. Windows 更新优化
**当前**: Build 29550 (Insider Preview)  
**建议**: 配置更新时间

**操作步骤**:
1. 设置 → Windows 更新
2. 高级选项 → 活动时间
3. 设置为非工作时间（如 2:00-6:00）

**建议**: 暂停更新 7 天（如需要稳定性）

---

#### 8. 后台应用优化
**建议**: 禁用不必要的后台应用

**操作步骤**:
1. 设置 → 隐私 → 后台应用
2. 关闭不需要的应用

**预期效果**:
- 减少内存占用
- 延长电池寿命（笔记本）
- CPU 更安静

---

#### 9. 游戏模式优化
**建议**: 开启游戏模式（即使不玩游戏）

**操作步骤**:
1. 设置 → 游戏 → 游戏模式
2. 开启

**预期效果**:
- 优先分配 CPU/GPU 资源
- 减少后台干扰
- 提升响应速度

---

### 【网络优化】⭐⭐⭐⭐

#### 10. DNS 优化
**当前**: 运营商默认 DNS  
**建议**: 使用公共 DNS

**推荐 DNS**:
- **阿里云**: 223.5.5.5 / 223.6.6.6
- **腾讯云**: 119.29.29.29
- **Google**: 8.8.8.8 / 8.8.4.4
- **Cloudflare**: 1.1.1.1

**操作步骤**:
```powershell
# 设置 DNS 为阿里云
Set-DnsClientServerAddress -InterfaceIndex (Get-NetAdapter).ifIndex -ServerAddresses ("223.5.5.5", "223.6.6.6")
```

**预期效果**:
- 域名解析更快
- 网页打开速度提升
- 更稳定

---

#### 11. 网络适配器优化
**建议**: 配置 WiFi 适配器

**操作步骤**:
1. 设备管理器 → 网络适配器
2. 右键 WiFi 适配器 → 属性
3. 高级选项卡:
   - 漫游倾向：1. 最低
   - 传输功率：5. 最高
   - 802.11n/ac/ax 模式：启用

**预期效果**: WiFi 更稳定、更快

---

### 【开发环境优化】⭐⭐⭐⭐⭐

#### 12. Docker 优化
**当前**: 34 个镜像，49GB  
**建议**: 
1. 立即清理未使用的
2. 配置资源限制
3. 迁移到 D 盘

**配置资源限制**:
```powershell
# 创建/编辑 .wslconfig
notepad $env:USERPROFILE\.wslconfig
```

**添加内容**:
```ini
[wsl2]
memory=16GB
processors=12
swap=8GB
localhostForwarding=true
```

**预期效果**:
- 限制内存使用
- 避免占用所有资源
- 系统更流畅

---

#### 13. IDE 优化
**建议**: 配置 IDE 缓存位置

**VSCode/Trae**:
```json
// settings.json
{
  "extensions.autoUpdate": false,
  "extensions.autoCheckUpdates": false,
  "telemetry.enableTelemetry": false
}
```

**预期效果**:
- 减少自动更新干扰
- 保护隐私
- 减少磁盘占用

---

#### 14. Git 优化
**建议**: 配置 Git 缓存和性能

**操作步骤**:
```powershell
# 配置 Git 缓存
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999

# 启用多核压缩
git config --global core.compression 0
git config --global core.packedGitLimit 512m
git config --global core.packedGitWindowSize 512m

# 启用缓存
git config --global feature.manyFiles true
```

**预期效果**:
- Git 操作更快
- 大仓库性能提升
- 减少内存使用

---

### 【安全优化】⭐⭐⭐⭐

#### 15. 防火墙规则优化
**建议**: 审查入站规则

**操作步骤**:
```powershell
# 查看入站规则
Get-NetFirewallRule -Direction Inbound | 
Where-Object Enabled -Eq True | 
Select-Object DisplayName, Description, Enabled | 
Format-Table -AutoSize
```

**建议**: 禁用不需要的规则

---

#### 16. Windows Defender 排除项
**建议**: 排除开发文件夹

**操作步骤**:
```powershell
# 添加排除项（需要管理员权限）
Add-MpPreference -ExclusionPath "D:\XUYIFEI\XUPROJECTS"
Add-MpPreference -ExclusionPath "D:\syskadun"
```

**预期效果**:
- 扫描更快
- 避免误报
- 开发更流畅

---

### 【用户体验优化】⭐⭐⭐

#### 17. 任务栏优化
**建议**: 精简任务栏

**操作步骤**:
1. 右键任务栏 → 任务栏设置
2. 关闭不需要的图标
3. 固定常用的

---

#### 18. 文件资源管理器优化
**建议**: 配置快速访问

**操作步骤**:
1. 文件资源管理器 → 查看 → 选项
2. 常规选项卡:
   - 打开文件资源管理器时：此电脑
   - 快速访问：取消"最近使用的文件"

---

#### 19. 通知优化
**建议**: 关闭不必要的通知

**操作步骤**:
1. 设置 → 系统 → 通知
2. 关闭不需要的应用通知

**预期效果**: 减少干扰

---

#### 20. 睡眠/休眠优化
**当前**: 已禁用休眠  
**建议**: 配置睡眠模式

**操作步骤**:
```powershell
# 配置电源按钮
powercfg /setacvalueindex 381b4222-f694-41f0-9685-ff5bb260df2e 4f971e89-eebd-4455-a8de-9e59040e7347 a7066653-8d6c-40a8-910e-a1f54b84c7e5 001

# 15 分钟后睡眠
powercfg /setacvalueindex 381b4222-f694-41f0-9685-ff5bb260df2e 238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da 900
```

---

## 📋 执行优先级

### 紧急（立即执行）
1. ✅ C 盘紧急清理（运行 `quick_cleanup.ps1`）
2. ⭐ 启动项优化（禁用不常用的）
3. ⭐ Docker 清理（`docker system prune -a -f`）

### 高优先级（今天完成）
4. 虚拟内存迁移到 D 盘
5. 电源模式设置为高性能
6. DNS 优化

### 中优先级（本周完成）
7. Docker 资源限制配置
8. Git 优化配置
9. Windows Defender 排除项
10. 存储感知配置

### 低优先级（可选）
11. 后台应用优化
12. 游戏模式开启
13. 任务栏/通知优化
14. 文件资源管理器优化

---

## 🚀 一键优化脚本

创建文件：`optimize_system.ps1`

```powershell
Write-Host "开始系统优化..." -ForegroundColor Cyan

# 1. 设置高性能电源模式
Write-Host "`n[1/8] 设置高性能电源模式..." -ForegroundColor Yellow
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# 2. 清理系统缓存
Write-Host "`n[2/8] 清理系统缓存..." -ForegroundColor Yellow
$cachePaths = @("$env:USERPROFILE\.cache", "$env:USERPROFILE\.claude\cache")
foreach ($path in $cachePaths) {
    if (Test-Path $path) {
        Remove-Item $path -Recurse -Force
    }
}

# 3. Docker 清理
Write-Host "`n[3/8] Docker 清理..." -ForegroundColor Yellow
docker system prune -a -f --volumes

# 4. 创建 WSL 配置文件
Write-Host "`n[4/8] 配置 WSL 资源限制..." -ForegroundColor Yellow
$wslConfig = @"
[wsl2]
memory=16GB
processors=12
swap=8GB
localhostForwarding=true
"@
$wslConfig | Out-File -FilePath "$env:USERPROFILE\.wslconfig" -Encoding UTF8

# 5. 配置 Git 优化
Write-Host "`n[5/8] 配置 Git 优化..." -ForegroundColor Yellow
git config --global http.postBuffer 524288000
git config --global feature.manyFiles true

# 6. 开启游戏模式
Write-Host "`n[6/8] 开启游戏模式..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 1
Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1

# 7. 配置 DNS
Write-Host "`n[7/8] 配置 DNS..." -ForegroundColor Yellow
Set-DnsClientServerAddress -InterfaceIndex (Get-NetAdapter).ifIndex -ServerAddresses ("223.5.5.5", "223.6.6.6")

# 8. 开启存储感知
Write-Host "`n[8/8] 开启存储感知..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 1

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  系统优化完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "`n[提示] 建议重启系统以应用所有更改" -ForegroundColor Yellow
Write-Host ""
```

执行:
```powershell
.\optimize_system.ps1
```

---

## 📊 预期效果总结

### 性能提升
- **启动速度**: +5-10 秒
- **系统响应**: +10-15%
- **内存空闲**: +500MB-1GB
- **CPU 空闲**: 更安静

### 存储释放
- **C 盘**: 60-70GB (立即) + 4-8GB (虚拟内存) = **64-78GB**
- **D 盘**: 50-100GB (Docker 迁移后)
- **总计**: **114-178GB**

### 使用体验
- ✅ 系统更流畅
- ✅ 网络更稳定
- ✅ 开发环境更优化
- ✅ 自动维护机制
- ✅ 减少干扰

---

## 💡 长期维护建议

### 每天
- 运行 `monitor_c_drive.ps1` 监控 C 盘

### 每周
- 运行 `scheduled_cleanup.ps1` 清理系统

### 每月
- 检查启动项
- 清理 Docker
- 审查已安装软件

### 每季度
- 系统健康检查
- 备份重要数据
- 更新驱动程序

---

## ⚠️ 注意事项

### 执行前
1. 备份重要数据
2. 关闭正在运行的程序
3. 确保电源充足（笔记本）

### 执行后
1. 重启系统
2. 验证所有功能正常
3. 运行 `monitor_c_drive.ps1` 查看效果

---

**创建时间**: 2026-03-20 19:30  
**适用系统**: Windows 11  
**预计执行时间**: 30-60 分钟  
**预期总效果**: 释放 114-178GB 空间，提升 10-15% 性能
