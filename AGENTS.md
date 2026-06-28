# AGENTS.md — Windows 系统优化工具包

Windows 11 系统优化工具包，纯 PowerShell 脚本集。无构建系统、无测试框架、无包管理器。

## 目录结构

```
syskadun/
├── scripts/          # 所有 .ps1 / .bat
│   ├── cleanup/      # C 盘清理、快速清理、计划清理、AppData 分析
│   ├── optimize/     # 主优化脚本 (win11-optimize)、高级优化、ROG 优化、虚拟内存
│   ├── monitor/      # 性能监控、C 盘监控、系统状态检查、基准测试
│   ├── config-fix/   # 还原点、组策略、WSL2/VMware、任务管理器修复
│   ├── migrate/      # 开发工具/隐藏文件迁移（4 步流程）
│   └── tools/        # OpenCode Web 启动器、一键菜单、提权运行
├── docs/
│   ├── guides/       # 使用指南、迁移指南、配置清单
│   ├── reports/      # 优化报告/总结
│   └── issues/       # 问题诊断与修复方案
├── config/           # .wslconfig-template, List.txt
└── video-downloader/ # yt-dlp 使用文档 (SKILL.md)
```

## 关键注意事项

### 🔴 quick_config_menu.bat 路径已损坏

`scripts/tools/quick_config_menu.bat` 内部用 `%~dp0` 硬编码引用了散落在根目录的脚本和文档（如 `monitor_c_drive.ps1`、`scheduled_cleanup.ps1` 及各 `.md` 文件）。移动后 `%~dp0` 解析到 `scripts/tools/`，所有路径都错了。**如需修复**，需将所有 `%~dp0` 引用改为相对于 `D:\syskadun\` 的绝对路径，如 `"%~dp0..\..\scripts\monitor\monitor_c_drive.ps1"`。

### 运行脚本

```powershell
# 所有脚本必须从 D:\syskadun 根目录执行
cd D:\syskadun

# 路径前缀：.\scripts\类别\文件名
.\scripts\optimize\win11-optimize.ps1 -CleanOnly

# 大部分需要管理员权限
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```

### 安全红线

- **优化前必须先创建还原点**：`.\scripts\config-fix\create-restorepoint.ps1`
- 存在两个还原点脚本：`create-restorepoint.ps1`（新，使用 `Checkpoint-Computer`）和 `create_restore_point.ps1`（旧，使用 WMI），内容不同，都保留。

### 中文编码陷阱

PowerShell 在中文 Windows 上控制台输出中文可能乱码。`scripts/monitor/monitor_c_drive.ps1` 刻意全英文输出规避此问题。编写新脚本时注意。

### 脚本约定

所有脚本遵循一致模式：
- 函数 `Write-Info`（青色）、`Write-Success`（绿色）、`Write-Warning`（黄色）、`Write-Error`（红色）
- 管理员权限自检 `Test-Administrator`
- 参数用 `[switch]` 控制模式

### 其他

- yt-dlp 路径：`C:\Users\xuyif\AppData\Roaming\Python\Python314\Scripts\yt-dlp.exe`
- OpenCode Web 地址：`http://127.0.0.1:4096/`，启动命令：`opencode web`
- 日志文件（如 `performance-log-*.csv`）写入项目根目录
- 配置文件模板在 `config/.wslconfig-template`
- `vidoe-downloader/SKILL.md` 有完整的 yt-dlp 使用文档
