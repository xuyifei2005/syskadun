# Windows 11 系统更新优化方案

> **文档版本**: v1.0  
> **创建日期**: 2026-03-16  
> **适用系统**: Windows 11 (所有版本)  
> **优化目标**: 提升系统性能、增强安全性、优化用户体验

---

## 📋 目录

- [一、系统更新策略](#一系统更新策略)
- [二、性能优化方案](#二性能优化方案)
- [三、启动项优化](#三启动项优化)
- [四、存储清理与优化](#四存储清理与优化)
- [五、网络优化](#五网络优化)
- [六、电源管理优化](#六电源管理优化)
- [七、安全性加固](#七安全性加固)
- [八、隐私设置优化](#八隐私设置优化)
- [九、游戏性能优化](#九游戏性能优化)
- [十、维护计划](#十维护计划)

---

## 〇、家庭版特别说明

### 0.1 组策略编辑器缺失问题

**问题**：运行 `gpedit.msc` 提示找不到文件

**原因**：Windows 10/11 家庭版默认不包含组策略编辑器

**解决方案**：

1. **使用提供的安装脚本**（推荐）
   - 文件位置：`d:\syskadun\enable-gpedit.bat`
   - 操作步骤：
     - 右键点击 `enable-gpedit.bat`
     - 选择【以管理员身份运行】
     - 等待 3-5 分钟完成安装
     - 重启电脑
     - 按 Win+R，输入 `gpedit.msc` 验证

2. **手动安装步骤**
   ```batch
   @echo off
   pushd "%~dp0"
   dir /b %SystemRoot%\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientExtensions-Package~3*.mum >List.txt
   dir /b %SystemRoot%\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientTools-Package~3*.mum >>List.txt
   for /f %%i in ('findstr /i . List.txt 2^>nul') do dism /online /norestart /add-package:"%SystemRoot%\servicing\Packages\%%i"
   pause
   ```

3. **替代方案**（无需安装）
   - 使用注册表编辑器（`regedit`）手动修改
   - 使用第三方工具：Policy Plus（开源免费）

---

## 一、系统更新策略

### 1.1 Windows Update 配置

```powershell
# 检查当前 Windows 更新状态
Get-WindowsUpdateLog

# 查看待安装的更新
Get-WindowsUpdate -MicrosoftUpdate

# 安装所有可用更新（需确认）
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot
```

### 1.2 更新优化建议

- ✅ **启用自动更新**：保持系统安全性
- ✅ **延迟功能更新**：企业/专业版可延迟 365 天
- ✅ **保留驱动程序更新**：避免手动更新导致的兼容性问题
- ⚠️ **创建系统还原点**：重大更新前必须执行

### 1.3 更新前准备清单

```markdown
- [ ] 备份重要数据到外部存储
- [ ] 创建系统还原点
- [ ] 确保磁盘空间充足（至少 20GB 可用）
- [ ] 连接稳定电源（笔记本电量 > 50%）
- [ ] 记录已安装的关键软件版本
```

---

## 二、性能优化方案

### 2.1 视觉效果优化

```powershell
# 调整为最佳性能（牺牲部分视觉效果）
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
Set-ItemProperty -Path $regPath -Name "VisualFXSetting" -Value 2

# 或自定义：保留平滑屏幕字体和 ClearType
# 控制面板 > 系统 > 高级系统设置 > 性能 > 自定义
```

### 2.2 虚拟内存优化

```powershell
# 查看当前虚拟内存设置
wmic pagefile list /format:list

# 建议配置：
# 初始大小 = 物理内存 × 1.5
# 最大值 = 物理内存 × 3
# 或设置为系统管理的大小
```

### 2.3 磁盘碎片整理（仅限 HDD）

```powershell
# 分析磁盘碎片
Optimize-Volume -DriveLetter C -Analyze -Verbose

# 执行优化（SSD 会自动执行 TRIM）
Optimize-Volume -DriveLetter C -ReTrim -Verbose
```

### 2.4 系统服务优化

```powershell
# 禁用不必要的服务（谨慎操作）
# 打印后台处理程序（无打印机时）
Stop-Service -Name "Spooler" -Force
Set-Service -Name "Spooler" -StartupType Disabled

# 远程注册表（安全风险）
Stop-Service -Name "RemoteRegistry" -Force
Set-Service -Name "RemoteRegistry" -StartupType Disabled

# Xbox 相关服务（不玩游戏时）
Get-Service -Name "Xbl*","Xbox*" | Stop-Service -Force
Get-Service -Name "Xbl*","Xbox*" | Set-Service -StartupType Disabled
```

---

## 三、启动项优化

### 3.1 查看启动项

```powershell
# 查看所有启动项
Get-CimInstance -ClassName Win32_StartupCommand | 
  Select-Object Name, Command, Location, User | 
  Format-Table -AutoSize

# 或使用任务管理器查看
taskmgr
```

### 3.2 禁用不必要的启动项

```powershell
# 禁用 OneDrive 自动启动
Stop-Process -Name "OneDrive" -Force
$onedrivePath = "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
# 在任务管理器 > 启动 中禁用

# 禁用 Cortana 启动
$registryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Set-ItemProperty -Path $registryPath -Name "ShowCortanaButton" -Value 0
```

### 3.3 启动项优化清单

```markdown
建议禁用的启动项：
- [ ] OneDrive（如不使用云同步）
- [ ] Cortana
- [ ] Microsoft Edge（后台预加载）
- [ ] Skype
- [ ] Teams
- [ ] 第三方软件的自动更新程序
- [ ] 不常用的硬件厂商工具

必须保留的启动项：
- [x] 杀毒软件
- [x] 输入法
- [x] 音频驱动相关
```

---

## 四、存储清理与优化

### 4.1 磁盘清理工具

```powershell
# 使用内置磁盘清理工具
cleanmgr /d C

# 或使用 PowerShell 清理 Windows 更新缓存
Stop-Service -Name "wuauserv" -Force
Remove-Item -Path "$env:windir\SoftwareDistribution\Download\*" -Recurse -Force
Start-Service -Name "wuauserv"
```

### 4.2 临时文件清理

```powershell
# 清理临时文件夹
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# 清理 Windows 临时文件
Remove-Item -Path "$env:windir\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
```

### 4.3 存储感知配置

```powershell
# 启用存储感知
Start-Process "ms-settings:storagesense"

# 或通过设置 > 系统 > 存储 > 存储感知
# 建议配置：
# - 每天运行
# - 删除 30 天以上的临时文件
# - 删除 30 天以上的回收站文件
```

### 4.4 大文件查找

```powershell
# 查找大于 1GB 的文件
Get-ChildItem -Path C:\ -Recurse -ErrorAction SilentlyContinue | 
  Where-Object { $_.Length -gt 1GB } | 
  Select-Object FullName, @{Name="Size(GB)";Expression={[math]::Round($_.Length/1GB,2)}} | 
  Sort-Object "Size(GB)" -Descending | 
  Select-Object -First 20
```

---

## 五、网络优化

### 5.1 DNS 优化

```powershell
# 查看当前 DNS 设置
Get-DnsClientServerAddress | Select-Object InterfaceAlias, ServerAddresses

# 设置 DNS 为 Cloudflare（1.1.1.1）
Set-DnsClientServerAddress -InterfaceAlias "以太网" -ServerAddresses ("1.1.1.1", "1.0.0.1")

# 或使用 Google DNS
# Set-DnsClientServerAddress -InterfaceAlias "以太网" -ServerAddresses ("8.8.8.8", "8.8.4.4")
```

### 5.2 TCP/IP 优化

```powershell
# 重置 TCP/IP 栈
netsh int ip reset
netsh winsock reset

# 优化 TCP 窗口大小
netsh int tcp set global autotuninglevel=normal

# 启用 TCP Fast Open
netsh int tcp set global fastopenfallback=enabled
```

### 5.3 网络适配器优化

```powershell
# 查看网卡高级设置
Get-NetAdapterAdvancedProperty

# 建议配置（针对 Intel 网卡）：
# - 流量控制：关闭
# - 节能以太网：关闭
# - 大型发送卸载：启用
# - 接收端缩放：启用
```

---

## 六、电源管理优化

### 6.1 电源计划配置

```powershell
# 查看可用电源计划
powercfg /list

# 启用卓越性能模式（Windows 10/11 专业版及以上）
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61

# 设置为高性能模式
powercfg -setactive SCHEME_MIN
```

### 6.2 高级电源设置

```powershell
# 导出当前电源计划
powercfg /export "C:\power-plan-backup.pow"

# 修改处理器电源管理
powercfg /setacvalueindex SCHEME_MIN SUB_PROCESSOR PROCTHROTTLEMAX 100
powercfg /setacvalueindex SCHEME_MIN SUB_PROCESSOR PROCTHROTTLEMIN 5

# 应用更改
powercfg -setactive SCHEME_MIN
```

### 6.3 睡眠与休眠优化

```powershell
# 查看睡眠状态支持
powercfg /a

# 禁用休眠（节省磁盘空间）
powercfg /h off

# 或启用快速启动（推荐）
# powercfg /h on
# 控制面板 > 电源选项 > 选择电源按钮的功能 > 启用快速启动
```

### 6.4 电池优化（笔记本）

```powershell
# 查看电池报告
powercfg /batteryreport /output "C:\battery-report.html"

# 优化电池充电阈值（部分品牌支持）
# Lenovo: Lenovo Vantage
# Dell: Dell Power Manager
# ASUS: MyASUS
```

---

## 七、安全性加固

### 7.1 Windows Defender 配置

```powershell
# 查看 Defender 状态
Get-MpComputerStatus

# 启用实时保护
Set-MpPreference -DisableRealtimeMonitoring $false

# 启用云保护
Set-MpPreference -MAPSReporting 2

# 配置排除项（谨慎使用）
# Set-MpPreference -ExclusionPath "C:\TrustedFolder"
```

### 7.2 防火墙配置

```powershell
# 查看防火墙状态
Get-NetFirewallProfile | Select-Object Name, Enabled

# 确保所有配置文件启用
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# 查看入站规则
Get-NetFirewallRule -Direction Inbound | Where-Object Enabled -Eq True
```

### 7.3 BitLocker 加密

```powershell
# 查看 BitLocker 状态
Get-BitLockerVolume

# 启用 BitLocker（需要 TPM 芯片）
# Enable-BitLocker -MountPoint "C:" -EncryptionMethod Aes256 -TpmProtector

# 备份恢复密钥
# Add-BitLockerKeyProtector -MountPoint "C:" -RecoveryPasswordProtector
```

### 7.4 安全基线检查

```powershell
# 使用 Microsoft Safety Scanner
# 下载：https://docs.microsoft.com/en-us/windows/security/threat-protection/intelligence/safety-scanner-download

# 运行系统文件检查
sfc /scannow

# 运行 DISM 修复
DISM /Online /Cleanup-Image /RestoreHealth
```

---

## 八、隐私设置优化

### 8.1 关闭遥测数据

```powershell
# 设置遥测级别为最低（安全）
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
if (!(Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force
}
Set-ItemProperty -Path $registryPath -Name "AllowTelemetry" -Value 0

# 禁用诊断跟踪服务
Stop-Service -Name "DiagTrack" -Force
Set-Service -Name "DiagTrack" -StartupType Disabled
```

### 8.2 关闭广告 ID

```powershell
# 禁用广告 ID
$registryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
Set-ItemProperty -Path $registryPath -Name "Enabled" -Value 0
```

### 8.3 隐私设置清单

```powershell
# 通过设置界面配置
start ms-settings:privacy

# 建议关闭：
# - [ ] 位置（按需）
# - [ ] 摄像头（按需）
# - [ ] 麦克风（按需）
# - [ ] 通知（按需）
# - [ ] 诊断数据（设为必需）
# - [ ] 墨迹书写和键入
# - [ ] 诊断数据查看器
# - [ ] 个性化广告
```

---

## 九、游戏性能优化

### 9.1 游戏模式配置

```powershell
# 启用游戏模式
# 设置 > 游戏 > 游戏模式 > 开启

# 启用硬件加速 GPU 计划
# 设置 > 系统 > 显示 > 图形设置 > 硬件加速 GPU 计划 > 开启
```

### 9.2 Xbox Game Bar 优化

```powershell
# 禁用 Xbox Game Bar（不使用时）
$registryPath = "HKCU:\System\GameConfigStore"
Set-ItemProperty -Path $registryPath -Name "GameDVR_Enabled" -Value 0

# 或通过设置 > 游戏 > Xbox Game Bar > 关闭
```

### 9.3 显卡驱动优化

```powershell
# NVIDIA 显卡：
# - 使用 GeForce Experience 更新驱动
# - 控制面板 > 管理 3D 设置 > 首选最大性能

# AMD 显卡：
# - 使用 AMD Software 更新驱动
# - 启用 Radeon Anti-Lag

# Intel 显卡：
# - 使用 Intel Driver & Support Assistant
```

---

## 十、维护计划

### 10.1 日常维护清单

```markdown
每日：
- [ ] 检查 Windows 更新状态
- [ ] 监控系统资源使用（任务管理器）
- [ ] 清理临时文件（可选）

每周：
- [ ] 运行磁盘清理
- [ ] 检查启动项
- [ ] 更新第三方软件
- [ ] 检查安全软件状态

每月：
- [ ] 运行系统文件检查（sfc /scannow）
- [ ] 运行 DISM 修复
- [ ] 检查磁盘健康状态
- [ ] 清理下载文件夹
- [ ] 备份重要数据

每季度：
- [ ] 创建系统还原点
- [ ] 检查电源计划设置
- [ ] 审查已安装程序
- [ ] 更新硬件驱动
- [ ] 运行完整病毒扫描
```

### 10.2 自动化维护脚本

```powershell
# 创建自动化维护脚本
$script = @'
# Windows 11 系统维护脚本
Write-Host "开始系统维护..." -ForegroundColor Green

# 1. 清理临时文件
Write-Host "清理临时文件..." -ForegroundColor Yellow
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

# 2. 清理 Windows 更新缓存
Write-Host "清理更新缓存..." -ForegroundColor Yellow
Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:windir\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue

# 3. 运行磁盘清理
Write-Host "运行磁盘清理..." -ForegroundColor Yellow
cleanmgr /d C /VERYLOWDISK

# 4. 系统文件检查
Write-Host "运行系统文件检查..." -ForegroundColor Yellow
sfc /scannow

# 5. DISM 修复
Write-Host "运行 DISM 修复..." -ForegroundColor Yellow
DISM /Online /Cleanup-Image /ScanHealth

Write-Host "系统维护完成！" -ForegroundColor Green
'@

# 保存脚本
$script | Out-File -FilePath "C:\Scripts\SystemMaintenance.ps1" -Encoding UTF8

# 创建计划任务（每周运行一次）
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Scripts\SystemMaintenance.ps1"
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 2am
Register-ScheduledTask -TaskName "系统维护" -Action $action -Trigger $trigger -Description "每周自动系统维护"
```

### 10.3 性能监控

```powershell
# 创建性能监控仪表板
perfmon

# 或使用资源监视器
resmon

# 关键监控指标：
# - CPU 使用率（< 70% 正常）
# - 内存使用率（< 80% 正常）
# - 磁盘使用率（SSD < 80%，HDD < 90%）
# - 网络延迟（< 50ms 正常）
# - 温度（CPU < 85°C）
```

---

## 📊 优化前后对比表

| 优化项 | 优化前 | 优化后 | 提升幅度 |
|--------|--------|--------|----------|
| 启动时间 | - | - | 预计 30-50% |
| 可用内存 | - | - | 预计 10-20% |
| 磁盘空间 | - | - | 预计 5-20GB |
| 网络延迟 | - | - | 预计 10-30% |
| 电池续航 | - | - | 预计 15-25% |

---

## ⚠️ 注意事项

1. **备份优先**：执行任何优化前，请确保重要数据已备份
2. **逐步实施**：建议逐项实施，每项完成后观察系统稳定性
3. **还原点**：重大修改前创建系统还原点
4. **兼容性**：部分优化可能影响特定软件，请根据实际需求调整
5. **专业版功能**：部分功能仅专业版及以上版本支持

---

## 📞 故障排除

### 常见问题

**Q1: 优化后系统不稳定**
- 使用系统还原点恢复
- 逐项排查最近的修改
- 检查事件查看器日志

**Q2: 某些功能无法使用**
- 确认 Windows 版本支持
- 检查相关服务是否被禁用
- 重新启用被优化的设置

**Q3: 性能反而下降**
- 恢复默认电源计划
- 重新启用被禁用的服务
- 检查是否有冲突的第三方软件

---

## 🔧 推荐工具

1. **系统清理**
   - Windows 内置磁盘清理
   - BleachBit（开源）
   - CCleaner（谨慎使用）

2. **驱动管理**
   - 驱动精灵
   - Driver Booster
   - 官方驱动工具

3. **性能监控**
   - 任务管理器
   - 资源监视器
   - HWMonitor
   - MSI Afterburner

4. **安全工具**
   - Windows Defender（内置）
   - Malwarebytes
   - HitmanPro

---

## 📝 执行记录

| 日期 | 优化项 | 执行人 | 备注 |
|------|--------|--------|------|
| 2026-03-16 | 初始方案制定 | - | 待执行 |
| - | - | - | - |

---

**文档更新日期**: 2026-03-16  
**下次审查日期**: 2026-06-16
