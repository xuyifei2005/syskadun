# WSL2与VMware共存配置指南

## 一、当前系统状态

### WSL2配置
- 发行版：Ubuntu-24.04 + Docker Desktop
- 网络模式：Mirrored（已配置）
- 配置文件位置：C:\Users\xuyif\.wslconfig

### VMware配置
- VMware NAT Service：运行中
- 网络适配器：VMnet1 (192.168.107.1) + VMnet8 (192.168.58.1)
- 状态：自动启动

### 系统虚拟化
- Hyper-V：已启用（WSL2依赖）
- 虚拟网卡：vEthernet (FSE HostVnic) 运行中

## 二、WSL2与VMware共存配置方案

### 方案A：优化WSL2配置（推荐）

#### 1. 更新WSL2配置文件

编辑 `C:\Users\xuyif\.wslconfig`，添加以下配置：

```ini
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
```

#### 2. 配置说明

| 参数 | 说明 | 推荐值 |
|------|------|---------|
| networkingMode | 网络模式 | mirrored（减少网络冲突） |
| memory | WSL2内存限制 | 16GB（根据系统总内存调整） |
| processors | CPU核心数 | 8（根据CPU核心数调整） |
| swap | 交换文件大小 | 4GB |
| nestedVirtualization | 嵌套虚拟化 | true（VMware需要） |
| firewall | 防火墙 | false（减少网络冲突） |
| hostAddressLoopback | 主机回环访问 | true |
| autoMemoryReclaim | 自动内存回收 | gradual |
| sparseVhd | 稀疏虚拟磁盘 | true（节省磁盘空间） |

### 方案B：配置VMware网络避免冲突

#### 1. VMware网络模式选择

**推荐使用桥接模式（Bridged）**，避免与WSL2网络冲突：

1. 打开VMware Workstation
2. 编辑 → 虚拟网络编辑器
3. 将VMnet8改为桥接模式
4. 选择物理网卡（如WLAN）

#### 2. 禁用VMware NAT服务（可选）

如果不需要VMware的NAT功能，可以禁用：

```powershell
# 以管理员身份运行PowerShell
Set-Service -Name "VMware NAT Service" -StartupType Manual

# 临时停止服务
Stop-Service -Name "VMware NAT Service" -Force
```

### 方案C：使用WSL1替代WSL2（最稳定）

如果WSL2与VMware冲突严重，可以切换到WSL1：

```powershell
# 1. 备份当前WSL2发行版
wsl --export Ubuntu-24.04 D:\backup\ubuntu24-backup.tar

# 2. 注销当前WSL2实例
wsl --unregister Ubuntu-24.04

# 3. 重新导入为WSL1
wsl --import Ubuntu-24.04 D:\WSL\Ubuntu24 D:\backup\ubuntu24-backup.tar --version 1

# 4. 验证版本
wsl --list --verbose
```

## 三、虚拟化性能优化

### 1. BIOS设置

确保BIOS中启用以下虚拟化选项：
- Intel VT-x / AMD-V
- Intel VT-d / AMD IOMMU
- Hyper-V（如果需要）

### 2. Windows功能

启用/禁用相关Windows功能（需要重启）：

```powershell
# 查看当前虚拟化状态
systeminfo | Select-String "Hyper-V"

# 如果需要禁用Hyper-V（仅用于VMware）
bcdedit /set hypervisorlaunchtype off
# 重启后生效

# 重新启用Hyper-V（用于WSL2）
bcdedit /set hypervisorlaunchtype auto
# 重启后生效
```

### 3. 内存管理

```powershell
# 调整虚拟内存页面文件大小
# 控制面板 → 系统 → 高级系统设置 → 性能 → 虚拟内存
# 建议设置为系统管理的驱动器
```

## 四、日常使用建议

### 启动顺序

1. **推荐顺序**：
   - 启动WSL2：`wsl`
   - 启动VMware虚拟机

2. **避免同时进行大量网络操作**：
   - WSL2和VMware网络操作错峰进行
   - 避免同时下载大文件

### 监控工具

```powershell
# 监控WSL2资源使用
wsl --status

# 监控虚拟化进程
Get-Process | Where-Object {$_.ProcessName -like '*vmware*' -or $_.ProcessName -like '*vmmem*'}

# 监控网络连接
Get-NetTCPConnection | Where-Object {$_.State -eq 'Established'}
```

### 故障排除

#### 问题1：蓝屏重启

**症状**：系统蓝屏，错误代码与虚拟化相关

**解决方案**：
1. 检查事件查看器中的蓝屏日志
2. 暂时禁用VMware或WSL2
3. 更新显卡驱动和虚拟化驱动
4. 检查BIOS虚拟化设置

#### 问题2：网络连接失败

**症状**：WSL2或VMware无法联网

**解决方案**：
1. 重启网络适配器
2. 检查防火墙设置
3. 重启WSL2：`wsl --shutdown`
4. 重启VMware网络服务

#### 问题3：性能下降

**症状**：系统运行缓慢，CPU占用高

**解决方案**：
1. 检查内存使用情况
2. 调整WSL2和VMware的内存分配
3. 关闭不必要的虚拟机
4. 检查后台进程

## 五、配置验证

### 验证WSL2配置

```powershell
# 查看WSL2配置
Get-Content $env:USERPROFILE\.wslconfig

# 查看WSL2状态
wsl --status

# 查看WSL2网络
wsl hostname -I
```

### 验证VMware配置

```powershell
# 查看VMware服务
Get-Service | Where-Object {$_.Name -like '*vmware*'}

# 查看VMware网络适配器
Get-NetAdapter | Where-Object {$_.InterfaceDescription -like '*VMware*'}

# 查看VMware进程
Get-Process | Where-Object {$_.ProcessName -like '*vmware*'}
```

## 六、紧急恢复方案

如果配置后出现严重问题：

1. **恢复WSL2默认配置**：
   - 删除或重命名 `C:\Users\xuyif\.wslconfig`
   - 重启WSL2：`wsl --shutdown`

2. **恢复VMware默认配置**：
   - 使用VMware虚拟网络编辑器恢复默认设置
   - 重启VMware服务

3. **系统还原**：
   - 使用系统还原点还原到配置前
   - 或使用系统备份恢复

## 七、参考资源

- [WSL2官方文档](https://docs.microsoft.com/en-us/windows/wsl/)
- [VMware Workstation文档](https://docs.vmware.com/en/VMware-Workstation-Pro/)
- [Windows虚拟化文档](https://docs.microsoft.com/en-us/virtualization/)

## 八、配置检查清单

- [ ] WSL2配置文件已更新
- [ ] VMware网络模式已配置为桥接
- [ ] BIOS虚拟化选项已启用
- [ ] 显卡驱动已更新到最新版本
- [ ] 系统防火墙已配置
- [ ] 内存和CPU分配已优化
- [ ] WSL2和VMware可以同时启动
- [ ] 网络连接正常
- [ ] 性能测试通过
- [ ] 已创建系统还原点

---

**最后更新**：2026-02-03
**配置版本**：1.0
**适用系统**：Windows 11 + WSL2 + VMware Workstation
