# CLAUDE.md — Windows 系统优化工具包

纯 PowerShell 脚本集。无构建系统、无测试框架、无包管理器。

## 运行脚本

```powershell
cd D:\syskadun

# 路径前缀：.\scripts\类别\文件名
.\scripts\optimize\win11-optimize.ps1 -CleanOnly

# 大部分需要管理员权限
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```

## 常用命令

| 用途 | 命令 |
|------|------|
| 还原点（优化前必做） | `.\scripts\config-fix\create-restorepoint.ps1` |
| 完整优化 | `.\scripts\optimize\win11-optimize.ps1` |
| 仅清理 | `.\scripts\optimize\win11-optimize.ps1 -CleanOnly` |
| 仅性能优化 | `.\scripts\optimize\win11-optimize.ps1 -PerformanceOnly` |
| ROG 优化 | `.\scripts\optimize\rog-optimize.ps1` |
| 高级优化 | `.\scripts\optimize\advanced_optimization.ps1` |
| 性能监控 | `.\scripts\monitor\performance-monitor.ps1` |
| C 盘监控 | `.\scripts\monitor\monitor_c_drive.ps1` |
| 系统状态 | `.\scripts\monitor\check-status.ps1` |
| 完整清理 | `.\scripts\cleanup\cleanup_c_drive.ps1` |
| 快速清理 | `.\scripts\cleanup\quick_cleanup.ps1` |
| 计划清理 | `.\scripts\cleanup\scheduled_cleanup.ps1` |
| 组策略安装 | `.\scripts\config-fix\install-gpedit.ps1` |
| WSL2/VMware 共存 | `.\scripts\config-fix\Configure-WSL2-VMware.ps1` |
| 任务管理器修复 | `.\scripts\config-fix\Fix-Taskmgr.ps1` |
| OpenCode Web | `.\scripts\tools\启动-opencode-web.ps1` |

## 关键注意事项

- **优化前必须先创建还原点** (`scripts/config-fix/create-restorepoint.ps1`)；另有旧版 `create_restore_point.ps1`（WMI 方式），两者不同，都保留
- `scripts/tools/quick_config_menu.bat` 内的 `%~dp0` 路径已损坏，因脚本移入子目录后硬编码路径失效
- `monitor_c_drive.ps1` 刻意全英文输出，规避中文 Windows 控制台乱码
- 日志文件（如 `performance-log-*.csv`）写入项目根目录
- 配置文件模板在 `config/.wslconfig-template`
- 存在两个还原点脚本，内容不同

## 脚本约定

所有脚本遵循一致模式：
- `Write-Info`（青色）、`Write-Success`（绿色）、`Write-Warning`（黄色）、`Write-Error`（红色）
- 管理员自检 `Test-Administrator` + 参数用 `[switch]` 控制模式

## 参考

- `video-downloader/SKILL.md` — yt-dlp 完整使用文档
- yt-dlp 路径：`C:\Users\xuyif\AppData\Roaming\Python\Python314\Scripts\yt-dlp.exe`
- OpenCode Web：`http://127.0.0.1:4096/`（命令：`opencode web`）
