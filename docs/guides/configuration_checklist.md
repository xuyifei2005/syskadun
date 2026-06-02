# 配置完成检查清单

## ✅ 配置前检查

**执行时间**：2026-03-20  
**当前 C 盘空间**：运行监控脚本查看

```powershell
# 执行监控脚本查看当前状态
.\monitor_c_drive.ps1
```

---

## 📋 配置步骤清单

请按顺序完成以下配置，每完成一项打勾 ✓

### 第一阶段：Windows 系统配置（必须）

- [ ] **1.1 新内容保存位置**
  - 打开：设置 → 系统 → 存储 → 高级存储设置 → 保存新内容的地方
  - 将所有选项改为 **D 盘**
  - 验证：所有下拉菜单都选择 D:

- [ ] **1.2 库位置迁移**（可选但推荐）
  - 文档：右键属性 → 位置 → 移动到 `D:\Documents`
  - 图片：右键属性 → 位置 → 移动到 `D:\Pictures`
  - 视频：右键属性 → 位置 → 移动到 `D:\Videos`
  - 下载：右键属性 → 位置 → 移动到 `D:\Downloads`

- [ ] **1.3 环境变量配置**
  - 打开：Win + R → `sysdm.cpl` → 高级 → 环境变量
  - 添加用户变量：
    - `PIP_CACHE_DIR` = `D:\Cache\pip-cache`
    - `NPM_CONFIG_CACHE` = `D:\Cache\npm-cache`
  - 添加系统变量（如需要）：
    - `JAVA_HOME` = `D:\Software\Java\jdk`
    - `PYTHON_HOME` = `D:\Software\Python`

---

### 第二阶段：常用软件配置（建议）

- [ ] **2.1 Docker Desktop**
  - 检查当前 WSL 位置：`wsl -l -v`
  - 如需迁移，参考：`docker_migration_guide.md`
  - 验证：Docker 数据在 D 盘

- [ ] **2.2 浏览器**
  - Chrome/Edge：设置 → 下载 → 位置改为 `D:\Downloads`
  - 开启"下载前询问每个文件的保存位置"
  - 验证：下载文件到 D 盘

- [ ] **2.3 微信**
  - 设置 → 文件管理 → 更改到 `D:\WeChat Files`
  - 迁移历史聊天记录
  - 验证：新消息保存到 D 盘

- [ ] **2.4 QQ**（如使用）
  - 设置 → 文件管理 → 位置改为 D 盘
  - 验证：文件保存到 D 盘

---

### 第三阶段：开发工具配置（推荐）

- [ ] **3.1 VSCode/Trae IDE**
  - 配置工作区默认到 D 盘
  - 当前项目已在 D 盘：`d:\syskadun`

- [ ] **3.2 Python 环境**
  - Miniconda 已安装：3.12GB
  - 新环境创建到 D 盘：`conda create --prefix D:\Python\envs\myenv`
  - 验证：新包安装到 D 盘

- [ ] **3.3 Node.js 包管理**
  ```powershell
  # 执行以下命令配置
  npm config set prefix "D:\Software\node-global"
  npm config set cache "D:\Cache\npm-cache"
  
  # 验证配置
  npm config get prefix
  npm config get cache
  ```

- [ ] **3.4 Maven/Gradle**（如使用 Java）
  - Maven: 修改 `settings.xml` 中的 `<localRepository>` 到 D 盘
  - Gradle: 修改 `gradle.properties` 配置缓存目录

---

### 第四阶段：自动化配置（强烈推荐）

- [ ] **4.1 创建必要目录**
  ```powershell
  # 执行以下命令创建目录结构
  $dirs = @(
      "D:\Cache\pip-cache",
      "D:\Cache\npm-cache",
      "D:\Cache\maven-repo",
      "D:\Software\node-global",
      "D:\Downloads",
      "D:\Documents",
      "D:\Pictures",
      "D:\Videos"
  )
  foreach ($dir in $dirs) {
      New-Item -ItemType Directory -Path $dir -Force
  }
  Write-Host "目录创建完成！" -ForegroundColor Green
  ```

- [ ] **4.2 配置监控脚本开机启动**（可选）
  - 打开：任务计划程序
  - 创建基本任务：
    - 名称：`C 盘监控`
    - 触发器：登录时
    - 操作：启动程序
      - 程序：`PowerShell`
      - 参数：`-ExecutionPolicy Bypass -File "d:\syskadun\monitor_c_drive.ps1"`
  - 验证：下次登录时自动运行

- [ ] **4.3 配置定期清理任务**
  - 打开：任务计划程序
  - 创建基本任务：
    - 名称：`C 盘定期清理`
    - 触发器：每周，周日凌晨 2:00
    - 操作：启动程序
      - 程序：`PowerShell`
      - 参数：`-ExecutionPolicy Bypass -File "d:\syskadun\scheduled_cleanup.ps1"`
  - 验证：任务列表中显示

---

## ✅ 配置后验证

### 验证步骤

**1. 运行监控脚本**
```powershell
.\monitor_c_drive.ps1
```
- 检查 C 盘空间是否有改善
- 查看前 10 大文件夹是否有变化

**2. 测试新应用安装位置**
- 尝试安装一个小应用
- 验证是否默认安装到 D 盘

**3. 测试文件保存位置**
- 保存新文件
- 验证是否默认保存到 D 盘

**4. 检查环境变量**
```powershell
Get-ChildItem Env: | Where-Object { $_.Name -like "*CACHE*" }
```
- 验证缓存变量指向 D 盘

**5. 检查 npm 配置**
```powershell
npm config get prefix
npm config get cache
```
- 验证路径在 D 盘

---

## 📊 配置前后对比

| 项目 | 配置前 | 配置后 | 改善 |
|------|--------|--------|------|
| C 盘可用空间 | ___ GB | ___ GB | +___ GB |
| C 盘使用率 | ___% | ___% | -___% |
| 新应用默认位置 | C: | D: | ✅ |
| 下载默认位置 | C: | D: | ✅ |
| 开发缓存位置 | C: | D: | ✅ |
| 自动监控 | ❌ | ✅ | ✅ |
| 定期清理 | ❌ | ✅ | ✅ |

---

## 🔧 故障排查

### 问题 1：配置后新应用还是安装到 C 盘
**解决**：
- 某些软件会忽略 Windows 设置
- 安装时手动选择"自定义安装"，路径改为 D 盘
- 使用 Scoop/Chocolatey 包管理器

### 问题 2：脚本执行报错
**解决**：
```powershell
# 以管理员身份运行 PowerShell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# 重新执行脚本
.\monitor_c_drive.ps1
.\scheduled_cleanup.ps1
```

### 问题 3：任务计划程序不执行
**解决**：
- 检查任务是否启用
- 检查触发器时间是否正确
- 手动运行一次任务测试
- 查看任务历史记录

---

## 📝 配置记录

**配置开始时间**：_______________  
**配置完成时间**：_______________  
**配置人**：_______________

**遇到的问题**：
1. _______________
2. _______________

**解决方案**：
1. _______________
2. _______________

**备注**：
_______________

---

## 🎯 长期维护计划

**每周**：
- [ ] 查看监控脚本报告
- [ ] 清理下载文件夹

**每月**：
- [ ] 运行定期清理脚本
- [ ] 检查 Docker 镜像和容器
- [ ] 清理 IDE 缓存

**每季度**：
- [ ] 检查 D 盘空间使用
- [ ] 审查已安装软件
- [ ] 备份重要数据

---

**创建时间**：2026-03-20  
**配套文档**：
- `prevent_c_drive_fill_guide.md` - 完整配置指南
- `monitor_c_drive.ps1` - 监控脚本
- `scheduled_cleanup.ps1` - 清理脚本
- `FINAL_OPTIMIZATION_REPORT.md` - 优化总结
