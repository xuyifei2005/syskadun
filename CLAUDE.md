# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在此代码仓库中工作时提供指导。

## 仓库概述

这是一个 Windows 11 系统优化工具包，由 PowerShell 脚本、文档和实用工具组成。主要用途是系统管理、性能优化、驱动器监控和清理自动化。

**目标使用场景：**
- 编程开发（多 IDE、多项目并行）
- 视频创作（剪辑、渲染）
- 图形处理（Photoshop、Illustrator 等）
- 多任务处理场景

**系统要求：**
- Windows 11 + SSD 固态硬盘
- 32GB+ 内存（推荐 64GB）
- 大部分操作需要管理员权限

## 常用命令

### 系统优化

```powershell
# 首先创建还原点（优化前必做）
.\create-restorepoint.ps1

# 运行完整优化（所有阶段）
.\win11-optimize.ps1

# 仅运行清理阶段
.\win11-optimize.ps1 -CleanOnly

# 仅运行性能优化阶段
.\win11-optimize.ps1 -PerformanceOnly

# ROG 系统专用优化
.\rog-optimize.ps1

# 高级系统优化
.\advanced_optimization.ps1
```

### 监控

```powershell
# 实时性能监控（默认 2 秒刷新间隔）
.\performance-monitor.ps1

# 自定义监控间隔（5 秒）
.\performance-monitor.ps1 -Interval 5

# 运行指定时长（60 秒）
.\performance-monitor.ps1 -Duration 60

# 导出性能日志到 CSV
.\performance-monitor.ps1 -ExportLog

# 监控 C 盘空间使用情况
.\monitor_c_drive.ps1

# 快速系统状态检查
.\check-status.ps1
```

### 清理操作

```powershell
# 完整 C 盘清理
.\cleanup_c_drive.ps1

# 快速清理（轻量级）
.\quick_cleanup.ps1

# 定计划清理任务
.\scheduled_cleanup.ps1
```

### 专项操作

```powershell
# 安装组策略编辑器 (gpedit.msc)
.\install-gpedit.ps1

# 配置 WSL2 和 VMware 共存
.\Configure-WSL2-VMware.ps1

# 修复 VMware 性能问题
.\fix_vmware_performance.ps1

# 修复任务管理器卡顿问题
.\Fix-Taskmgr.ps1

# 优化虚拟内存设置
.\optimize_pagefile.ps1
```

### 视频下载工具

```powershell
# 下载视频（最佳质量）
python -m yt_dlp "视频链接"

# 下载到指定位置
python -m yt_dlp -o "D:/Videos/%(title)s.%(ext)s" "视频链接"

# 下载 1080p 质量
python -m yt_dlp -f "bestvideo[height<=1080]+bestaudio" "视频链接"

# 仅下载音频（MP3）
python -m yt_dlp -x --audio-format mp3 "视频链接"

# 查看可用格式
python -m yt_dlp -F "视频链接"

# 使用代理
python -m yt_dlp --proxy "http://127.0.0.1:7890" "视频链接"

# B站下载（使用 cookies）
python -m yt_dlp --cookies-from-browser chrome "B站链接"
```

### OpenCode Web 界面

```powershell
# 启动 opencode web 界面（推荐）
.\启动-opencode-web.ps1

# 或使用批处理文件
.\启动-opencode-web.bat

# Web 界面地址：http://127.0.0.1:4096/
```

## PowerShell 脚本架构

所有 PowerShell 脚本遵循一致的模式：

### 1. 权限检查

需要管理员权限的脚本包含权限验证：

```powershell
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Error "请以管理员身份运行此脚本！"
    exit 1
}
```

### 2. 参数结构

脚本使用 PowerShell 参数控制执行模式：

```powershell
param(
    [switch]$Help,
    [switch]$CleanOnly,
    [switch]$PerformanceOnly,
    [int]$Interval = 2,
    [int]$Duration = 0,
    [switch]$ExportLog
)
```

### 3. 函数组织

函数按操作类型组织：
- 系统清理函数
- 性能优化函数
- 监控函数
- 报告函数

### 4. 错误处理

脚本使用全面的错误处理：

```powershell
try {
    Stop-Service -Name wuauserv -Force -ErrorAction Stop
    # 操作
    Write-Success "操作完成"
} catch {
    Write-Warning "操作失败：$_"
}
```

### 5. 输出格式

一致的颜色编码输出：
- 青色：`[INFO]` - 信息消息
- 绿色：`[SUCCESS]` - 成功操作
- 黄色：`[WARNING]` - 警告消息
- 红色：`[ERROR]` - 关键错误

## 优化工作流架构

优化过程遵循 3 阶段架构：

### 阶段 1：系统清理
- Windows 更新缓存清理
- 临时文件删除
- 传输优化缓存清理
- 回收站清空
- Windows.old 检测和删除

### 阶段 2：性能优化
- 禁用休眠（节省 10-30GB）
- 启用卓越性能模式
- 优化虚拟内存设置
- 禁用窗口透明度
- 系统响应优先级调整
- 禁用 8.3 文件名创建
- 启用 SSD 的 TRIM 功能

### 阶段 3：启动项分析
- 列出所有启动项
- 提供禁用建议
- 分类建议

## 监控架构

### 性能监控器
- 实时 CPU、内存、磁盘指标
- Top 5 资源占用进程
- CSV 导出用于历史分析
- 可配置刷新间隔

### 驱动器监控器
- C 盘空间计算
- 基于阈值的警报（75%、85%、90%）
- Top 10 最大文件夹识别
- 使用英文输出避免编码问题

## 关键安全实践

### 任何优化之前

1. **必须首先创建还原点**
   ```powershell
   .\create-restorepoint.ps1
   ```

2. **验证管理员权限**
   - 右键点击 PowerShell → "以管理员身份运行"
   - 所有优化脚本都需要管理员权限

3. **关闭运行中的应用程序**
   - 停止正在修改的服务
   - 关闭使用正在清理文件的程序

### 恢复系统

如果优化导致问题：
1. 打开"创建还原点"（系统还原）
2. 点击"系统还原"按钮
3. 选择优化前创建的还原点
4. 将系统恢复到之前的状态

## 脚本分类

### 清理脚本
- `cleanup_c_drive.ps1` - 完整 C 盘清理
- `quick_cleanup.ps1` - 快速轻量清理
- `scheduled_cleanup.ps1` - 自动计划清理

### 优化脚本
- `win11-optimize.ps1` - 主优化脚本
- `rog-optimize.ps1` - ASUS ROG 系统优化
- `advanced_optimization.ps1` - 高级优化
- `optimize_system.ps1` - 系统级优化
- `optimize_startup.ps1` - 启动项优化

### 监控脚本
- `performance-monitor.ps1` - 性能监控
- `monitor_c_drive.ps1` - 驱动器空间监控
- `check-status.ps1` - 系统状态检查
- `benchmark_performance.ps1` - 性能基准测试

### 配置脚本
- `create-restorepoint.ps1` - 创建还原点
- `install-gpedit.ps1` - 安装组策略编辑器
- `Configure-WSL2-VMware.ps1` - WSL2/VMware 配置
- `fix_vmware_performance.ps1` - VMware 性能修复
- `Fix-Taskmgr.ps1` - 任务管理器修复
- `optimize_pagefile.ps1` - 虚拟内存优化

### 迁移脚本
- `move_pagefile_to_D.ps1` - 将虚拟内存移到 D 盘
- `move_comfyui_models.ps1` - 迁移 ComfyUI 模型
- `pagefile_instructions.ps1` - 虚拟内存配置指南

## 文档结构

### 快速入门指南
- `README-Windows11-Optimize.md` - 优化快速入门
- `README_预防性配置.md` - 预防性配置指南

### 优化指南
- `ADVANCED_SYSTEM_OPTIMIZATION.md` - 高级优化详情
- `SYSTEM_OPTIMIZATION_ANALYSIS.md` - 系统分析
- `COMPLETE_OPTIMIZATION_SUMMARY.md` - 完整总结

### 清理指南
- `C_DRIVE_CLEANUP_REPORT.md` - 清理报告
- `prevent_c_drive_fill_guide.md` - 防止 C 盘爆满

### 迁移指南
- `docker_migration_guide.md` - Docker 迁移
- `comfyui_migration_guide.md` - ComfyUI 迁移
- `app_install_location_guide.md` - 应用安装位置配置

### 配置指南
- `configuration_checklist.md` - 配置检查清单
- `WSL2_VMware共存配置指南.md` - WSL2/VMware 共存
- `组策略编辑器安装说明.md` - 组策略编辑器安装

## 视频下载器技能

video-downloader 目录包含一个 yt-dlp 技能，用于从 1200+ 平台下载视频。

**已安装版本：** 2026.02.21
**可执行文件路径：** `C:\Users\xuyif\AppData\Roaming\Python\Python314\Scripts\yt-dlp.exe`

**支持的平台：**
YouTube、B站、Twitter/X、TikTok、抖音、Instagram、Facebook、Vimeo、优酷、爱奇艺、腾讯视频等 1200+ 网站

完整使用文档见 `video-downloader/SKILL.md`。

## 开发注意事项

### 脚本执行策略

如果 PowerShell 脚本无法运行，调整执行策略：

```powershell
# 仅当前进程
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# 或永久设置（需要管理员）
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 输出模板语法

yt-dlp 使用 Python 风格的模板：
- `%(title)s` - 视频标题
- `%(ext)s` - 文件扩展名
- `%(uploader)s` - 上传者名称
- `%(id)s` - 视频 ID

### 中文编码问题

某些脚本使用英文输出以避免中文 Windows 系统上的 PowerShell 编码问题。像 `monitor_c_drive.ps1` 这样的脚本故意使用英文以确保可靠的控制台显示。

### WSL 配置

`.wslconfig-template` 提供了 WSL2 内存/CPU 限制的模板：

```ini
[wsl2]
memory=32GB
processors=8
swap=8GB
```

## 工作目录

**主路径：** `D:\syskadun\`

大多数脚本假设从此目录执行：
- 日志文件写入此处（`performance-log-*.csv`）
- 脚本在硬编码路径中引用此路径
- 文档假设此基础目录

## 文件组织

### 根目录
- PowerShell 脚本 (*.ps1)
- 批处理文件 (*.bat)
- Markdown 文档 (*.md)
- 配置模板 (.wslconfig-template)

### 子目录
- `assets/` - 文档的图片和资源
- `video-downloader/` - yt-dlp 技能
- `codeingplan/` - AI 编程工具笔记
- `image/` - 其他图片
- `Backup/` - 备份存储
- `win11电脑系统性能优化/` - 空的优化目录

## 性能基准

优化后预期效果：
- **立即见效：** C 盘空间释放 10-50GB
- **立即见效：** 启动速度提升
- **立即见效：** 多任务切换更流畅
- **长期效果：** 系统稳定性改善
- **长期效果：** 减少卡顿和延迟

## 维护计划

推荐的维护频率：
- **每日：** 运行监控脚本，关闭不用的程序
- **每周：** 运行清理脚本，检查磁盘空间
- **每月：** 清理开发缓存，检查启动项
- **每季度：** 更新驱动，Windows 更新

## 故障排除

### 脚本执行错误

**问题：** 脚本无法运行
**解决方案：** 以管理员身份运行，检查执行策略

### 编码问题

**问题：** 中文字符显示不正确
**解决方案：** 使用英文版本的脚本（如 `monitor_c_drive.ps1`）

### 性能未改善

**问题：** 优化后系统仍然缓慢
**解决方案：** 检查后台进程，验证 TRIM 已启用，运行性能基准测试

### C 盘仍然爆满

**问题：** 清理后 C 盘空间仍然不足
**解决方案：** 使用 WizTree 分析大文件，迁移 Docker/ComfyUI，检查虚拟内存位置

## 更新

更新 yt-dlp 视频下载器：
```powershell
pip install -U yt-dlp
```