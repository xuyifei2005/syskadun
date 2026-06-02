# Hyper-V配置手动修复指南

## 📋 文档信息

- **创建日期**：2026-02-09
- **适用系统**：Windows 10/11 预览版（构建号 28000）
- **问题类型**：Hyper-V虚拟交换机配置损坏导致蓝屏
- **修复方式**：手动清理配置并重建

---

## 🔍 问题概述

### 症状表现
- 系统频繁蓝屏（错误代码：0x0000003b SYSTEM_SERVICE_EXCEPTION）
- 蓝屏时间：2月7日、2月8日、2月9日持续发生
- 系统日志显示Hyper-V虚拟交换机端口配置丢失
- 网络名称冲突（WORKGROUP注册失败）

### 根本原因
- Hyper-V虚拟交换机配置文件损坏
- 残留的虚拟网络适配器导致冲突
- NetBT服务持续报错（事件ID 4321）

### 影响范围
- Docker Desktop容器运行
- WSL2虚拟化环境
- 系统稳定性

---

## 🛡️ 修复前准备工作

### 1. 创建系统还原点（必须执行）

**操作步骤**：
1. 按 `Win + R` 打开运行对话框
2. 输入 `sysdm.cpl` 并回车
3. 切换到"系统保护"选项卡
4. 点击"创建"按钮
5. 输入还原点名称：`修复Hyper-V配置前备份`
6. 点击"创建"并等待完成

**验证**：
- 系统会显示"已成功创建还原点"

### 2. 备份重要数据（建议执行）

**需要备份的内容**：
- Docker容器数据（如有重要数据）
- 工作文档和代码
- 浏览器书签和配置

**备份位置**：
- 外部硬盘或云存储

### 3. 记录当前配置（可选但推荐）

**操作步骤**：
1. 以管理员身份打开PowerShell
2. 执行以下命令并截图保存：

```powershell
# 查看当前网络适配器
Get-NetAdapter | Format-Table Name, InterfaceDescription, Status -AutoSize

# 查看IP配置
Get-NetIPConfiguration | Format-Table InterfaceAlias, IPv4Address -AutoSize

# 查看Docker容器状态
docker ps -a
```

---

## 📝 详细修复步骤

### 步骤1：停止Docker和WSL2服务

#### 1.1 停止WSL2

**操作步骤**：
1. 以管理员身份打开PowerShell
2. 执行命令：

```powershell
wsl --shutdown
```

**验证**：
- 执行 `wsl --list --verbose`
- 所有WSL2实例应显示为"Stopped"

#### 1.2 停止Docker Desktop

**操作步骤**：
1. 在系统托盘找到Docker Desktop图标
2. 右键点击 -> 退出Docker Desktop
3. 等待完全退出（托盘图标消失）

**PowerShell验证**：
```powershell
Get-Service docker
```
应显示状态为"Stopped"

#### 1.3 停止Hyper-V服务

**操作步骤**：
1. 在PowerShell中执行：

```powershell
Stop-Service vmcompute -Force
```

**验证**：
```powershell
Get-Service vmcompute
```
应显示状态为"Stopped"

---

### 步骤2：备份注册表配置

**操作步骤**：
1. 在PowerShell中执行：

```powershell
# 创建备份目录
New-Item -ItemType Directory -Path "D:\syskadun\Backup" -Force

# 备份Hyper-V配置
$backupPath = "D:\syskadun\Backup\VMSMP_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
reg export "HKLM\SYSTEM\CurrentControlSet\Services\VMSMP" $backupPath

Write-Host "备份已保存到: $backupPath" -ForegroundColor Green
```

**验证**：
- 检查 `D:\syskadun\Backup` 目录
- 应该有一个 `.reg` 文件

---

### 步骤3：清理损坏的虚拟交换机配置

#### 3.1 删除SwitchList配置

**操作步骤**：
1. 在PowerShell中执行：

```powershell
# 检查SwitchList是否存在
Test-Path "HKLM:\SYSTEM\CurrentControlSet\Services\VMSMP\Parameters\SwitchList"

# 如果存在，删除它
Remove-Item "HKLM:\SYSTEM\CurrentControlSet\Services\VMSMP\Parameters\SwitchList" -Force -ErrorAction SilentlyContinue

Write-Host "SwitchList配置已清理" -ForegroundColor Green
```

#### 3.2 删除NicList配置

**操作步骤**：
1. 在PowerShell中执行：

```powershell
# 检查NicList是否存在
Test-Path "HKLM:\SYSTEM\CurrentControlSet\Services\VMSMP\Parameters\NicList"

# 如果存在，删除它
Remove-Item "HKLM:\SYSTEM\CurrentControlSet\Services\VMSMP\Parameters\NicList" -Force -ErrorAction SilentlyContinue

Write-Host "NicList配置已清理" -ForegroundColor Green
```

#### 3.3 验证清理结果

**操作步骤**：
1. 在PowerShell中执行：

```powershell
# 查看VMSMP参数目录
Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\VMSMP\Parameters" -ErrorAction SilentlyContinue | Format-Table Name, Property
```

**预期结果**：
- 不应该看到 `SwitchList` 和 `NicList` 子项

---

### 步骤4：清理残留的虚拟网络适配器

#### 4.1 打开设备管理器

**方法一：通过快捷键**
1. 按 `Win + X`
2. 选择"设备管理器（M）"

**方法二：通过运行**
1. 按 `Win + R`
2. 输入 `devmgmt.msc`
3. 点击确定

#### 4.2 显示隐藏设备

**操作步骤**：
1. 在设备管理器顶部菜单，点击"查看"
2. 勾选"显示隐藏的设备"
3. 等待设备列表刷新

#### 4.3 定位虚拟网络适配器

**操作步骤**：
1. 展开"网络适配器"类别
2. 查找以下类型的适配器：
   - Hyper-V Virtual Ethernet Adapter
   - 未知设备（带有虚拟网络标识）
   - Docker相关适配器
   - WSL相关适配器

**识别方法**：
- 右键点击适配器 -> 属性
- 切换到"详细信息"选项卡
- 查看"硬件ID"字段
- 包含 `VMBUS` 或 `Hyper-V` 的都是虚拟适配器

#### 4.4 删除虚拟网络适配器

**操作步骤**：
1. 右键点击虚拟网络适配器
2. 选择"卸载设备"
3. 勾选"删除此设备的驱动程序软件"（如果有）
4. 点击确定
5. 对所有虚拟网络适配器重复此操作

**注意事项**：
- 不要删除物理网络适配器（如Intel Wi-Fi、Realtek以太网）
- 只删除虚拟适配器
- 删除后可能需要重启才能完全清除

#### 4.5 验证清理结果

**操作步骤**：
1. 在PowerShell中执行：

```powershell
# 查看当前网络适配器
Get-NetAdapter -IncludeHidden | Format-Table Name, InterfaceDescription, Status, Hidden -AutoSize
```

**预期结果**：
- 不应该看到"Hyper-V Virtual Ethernet Adapter"
- 物理适配器应该保留

---

### 步骤5：解决网络冲突问题

#### 5.1 重启主网络适配器

**操作步骤**：
1. 在PowerShell中执行：

```powershell
# 重启WLAN适配器（您的主网络适配器）
Restart-NetAdapter -Name "WLAN" -Force

Write-Host "网络适配器已重启" -ForegroundColor Green
```

#### 5.2 刷新DNS缓存

**操作步骤**：
1. 在PowerShell中执行：

```powershell
# 清理DNS缓存
Clear-DnsClientCache

Write-Host "DNS缓存已清理" -ForegroundColor Green
```

#### 5.3 重启NetBIOS服务

**操作步骤**：
1. 在PowerShell中执行：

```powershell
# 重启NetBT服务
Restart-Service netbt -Force

Write-Host "NetBIOS服务已重启" -ForegroundColor Green
```

#### 5.4 检查网络冲突

**操作步骤**：
1. 在PowerShell中执行：

```powershell
# 查看ARP表，检查IP冲突
arp -a | findstr "192.168.1.1"
```

**如果发现冲突**：
- 记录MAC地址
- 确认是否是其他设备
- 如果是本机，继续下一步
- 如果是其他设备，更改本机IP或冲突设备IP

---

### 步骤6：重启Hyper-V服务

**操作步骤**：
1. 在PowerShell中执行：

```powershell
# 启动Hyper-V主机计算服务
Start-Service vmcompute

Write-Host "Hyper-V服务已启动" -ForegroundColor Green
```

**验证**：
```powershell
Get-Service vmcompute
```
应显示状态为"Running"

---

### 步骤7：重启系统（必须执行）

**操作步骤**：
1. 保存所有打开的文档和程序
2. 点击开始菜单 -> 电源 -> 重启
3. 等待系统重启完成

**重要提示**：
- 重启是必须的，否则配置更改不会生效
- 重启后Hyper-V会重新初始化虚拟交换机

---

### 步骤8：重新启动Docker Desktop

**操作步骤**：
1. 从开始菜单启动Docker Desktop
2. 等待Docker Desktop完全启动（托盘图标变为稳定状态）
3. 打开PowerShell，验证Docker状态：

```powershell
docker ps
```

**预期结果**：
- Docker应该能正常运行
- 容器列表应该显示正常

---

### 步骤9：启动WSL2（如果需要）

**操作步骤**：
1. 在PowerShell中执行：

```powershell
wsl
```

**验证**：
- WSL2应该能正常启动
- 可以在WSL2中执行Linux命令

---

## ✅ 验证修复结果

### 验证1：检查系统日志

**操作步骤**：
1. 以管理员身份打开PowerShell
2. 执行以下命令：

```powershell
# 检查最近1小时的Hyper-V错误
Get-WinEvent -FilterHashtable @{LogName='System'; Id=15; ProviderName='Microsoft-Windows-Hyper-V-VmSwitch'} -MaxEvents 10 | Format-List TimeCreated, Id, Message
```

**预期结果**：
- 不应该有新的Hyper-V错误
- 如果有错误，应该不是"找不到对象名"

### 验证2：检查网络冲突

**操作步骤**：
1. 在PowerShell中执行：

```powershell
# 检查NetBT错误
Get-WinEvent -FilterHashtable @{LogName='System'; Id=4321; ProviderName='NetBT'} -MaxEvents 5 | Format-List TimeCreated, Id, Message
```

**预期结果**：
- 不应该有新的NetBT错误
- 或者错误频率显著降低

### 验证3：检查Docker网络

**操作步骤**：
1. 在PowerShell中执行：

```powershell
# 查看Docker网络
docker network ls

# 查看Docker网络详细信息
docker network inspect bridge
```

**预期结果**：
- Docker网络应该正常显示
- 不应该有配置错误

### 验证4：检查系统稳定性

**操作步骤**：
1. 观察系统运行状态
2. 使用系统至少2-3小时
3. 检查是否再次蓝屏

**预期结果**：
- 系统应该稳定运行
- 不应该出现蓝屏

---

## 🔧 故障排除

### 问题1：重启后Hyper-V服务无法启动

**症状**：
```powershell
Get-Service vmcompute
```
显示状态为"Stopped"

**解决方案**：
1. 检查事件查看器中的错误日志
2. 尝试手动启动服务：
```powershell
Start-Service vmcompute -ErrorAction SilentlyContinue
```
3. 如果失败，检查Windows功能：
```powershell
Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -like "*Hyper*" }
```

### 问题2：Docker容器无法启动

**症状**：
```powershell
docker ps
```
显示错误或无容器运行

**解决方案**：
1. 完全卸载Docker Desktop
2. 重新安装最新版本的Docker Desktop
3. 重启系统

### 问题3：虚拟网络适配器仍然存在

**症状**：
设备管理器中仍然看到虚拟网络适配器

**解决方案**：
1. 重启系统（如果还没有重启）
2. 在安全模式下删除虚拟适配器
3. 使用命令行删除：

```powershell
# 以管理员身份执行
pnputil /enum-devices /class "Net"
# 找到虚拟适配器对应的INF文件
pnputil /delete-driver oemXX.inf
```

### 问题4：网络连接问题

**症状**：
重启后无法连接网络

**解决方案**：
1. 重启网络适配器：
```powershell
Restart-NetAdapter -Name "WLAN" -Force
```
2. 重置网络设置：
```powershell
netsh winsock reset
netsh int ip reset
```
3. 重启系统

### 问题5：蓝屏仍然发生

**症状**：
修复后仍然蓝屏

**解决方案**：
1. 检查蓝屏转储文件：
```powershell
Get-ChildItem "C:\Windows\Minidump" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
```
2. 使用蓝屏查看工具分析转储文件
3. 考虑使用系统还原点回滚
4. 如果问题持续，可能需要重装系统

---

## 📊 修复进度检查表

使用此检查表确保所有步骤都已完成：

| 步骤 | 描述 | 状态 | 备注 |
|------|------|------|------|
| 准备1 | 创建系统还原点 | ☐ |  |
| 准备2 | 备份重要数据 | ☐ |  |
| 准备3 | 记录当前配置 | ☐ |  |
| 步骤1 | 停止Docker和WSL2 | ☐ |  |
| 步骤2 | 备份注册表配置 | ☐ |  |
| 步骤3 | 清理虚拟交换机配置 | ☐ |  |
| 步骤4 | 清理虚拟网络适配器 | ☐ |  |
| 步骤5 | 解决网络冲突 | ☐ |  |
| 步骤6 | 重启Hyper-V服务 | ☐ |  |
| 步骤7 | 重启系统 | ☐ |  |
| 步骤8 | 重新启动Docker | ☐ |  |
| 步骤9 | 启动WSL2 | ☐ |  |
| 验证1 | 检查系统日志 | ☐ |  |
| 验证2 | 检查网络冲突 | ☐ |  |
| 验证3 | 检查Docker网络 | ☐ |  |
| 验证4 | 检查系统稳定性 | ☐ |  |

**使用说明**：
- ☐ = 待执行
- ✓ = 已完成
- ✗ = 执行失败（需要故障排除）

---

## ⚠️ 重要注意事项

### 安全提示
1. **必须创建系统还原点**：这是最重要的安全措施
2. **不要删除物理网络适配器**：只删除虚拟适配器
3. **备份重要数据**：防止意外数据丢失
4. **逐步执行**：不要跳过任何步骤

### 操作提示
1. **以管理员身份运行PowerShell**：右键 -> 以管理员身份运行
2. **仔细阅读每一步**：理解操作的目的和预期结果
3. **验证每一步的结果**：确保操作成功后再继续
4. **记录问题**：如果遇到问题，记录错误信息

### 风险提示
1. **预览版系统**：您使用的是Windows预览版，本身就不稳定
2. **Docker兼容性**：预览版中Docker可能存在兼容性问题
3. **蓝屏风险**：修复过程中可能触发蓝屏，请保存工作
4. **数据丢失风险**：虽然风险很低，但建议备份重要数据

---

## 📞 获取帮助

### 如果遇到问题

1. **查看系统日志**：
```powershell
Get-WinEvent -FilterHashtable @{LogName='System'; Level=2} -MaxEvents 50 | Format-List TimeCreated, Id, ProviderName, Message
```

2. **查看蓝屏转储文件**：
- 位置：`C:\Windows\Minidump`
- 使用BlueScreenView或WinDbg分析

3. **使用系统还原点**：
- 控制面板 -> 系统 -> 系统保护 -> 系统还原

4. **联系技术支持**：
- 记录详细的错误信息
- 提供系统配置和操作步骤
- 附带蓝屏转储文件

---

## 📝 修复日志模板

建议您在修复过程中记录以下信息：

```
修复日志
========

开始时间：YYYY-MM-DD HH:MM:SS
系统版本：Windows 10 Home China (版本 2009, 构建 28000.4)

执行步骤：
[ ] 创建系统还原点
[ ] 备份注册表配置
[ ] 清理虚拟交换机配置
[ ] 清理虚拟网络适配器
[ ] 解决网络冲突
[ ] 重启Hyper-V服务
[ ] 重启系统
[ ] 重新启动Docker
[ ] 启动WSL2

遇到的问题：
- [问题描述1]
- [问题描述2]

解决方案：
- [解决方案1]
- [解决方案2]

验证结果：
- [ ] 系统日志检查通过
- [ ] 网络冲突解决
- [ ] Docker网络正常
- [ ] 系统稳定运行

结束时间：YYYY-MM-DD HH:MM:SS
备注：
```

---

## 🎯 总结

本指南提供了完整的手动修复步骤，可以解决Hyper-V虚拟交换机配置损坏导致的蓝屏问题。

**关键要点**：
1. 必须创建系统还原点作为安全措施
2. 逐步执行每个步骤并验证结果
3. 重启系统是必须的，否则配置更改不会生效
4. 修复后需要验证系统稳定性

**预期结果**：
- Hyper-V虚拟交换机配置恢复正常
- 网络冲突问题得到解决
- 系统不再蓝屏
- Docker和WSL2正常运行

**如果问题持续**：
- 使用系统还原点回滚
- 考虑重装稳定版Windows
- 联系专业技术支持

---

**祝您修复成功！** 🎉
