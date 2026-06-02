# C 盘防护配置指南 - 防止新应用继续占用 C 盘

## 🎯 配置目标

- 配置 Windows 新内容默认保存位置到 D 盘
- 配置常用软件安装路径到 D 盘
- 建立长期防护机制，避免 C 盘再次爆满

---

## 一、Windows 系统级配置（必须执行）

### 1.1 配置新应用默认安装位置

**Windows 设置方法**：

1. 打开 **设置** → **系统** → **存储**
2. 点击 **高级存储设置**
3. 选择 **保存新内容的地方**
4. 修改以下所有选项为 **D 盘**：
   - 新的应用将保存到：D:
   - 新的文档将保存到：D:
   - 新的音乐将保存到：D:
   - 新的图片将保存到：D:
   - 新的电影将保存到：D:
   - 新的离线地图将保存到：D:

**PowerShell 验证命令**：
```powershell
# 查看当前配置
Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" | 
Select-Object "Personal", "My Music", "My Video", "My Pictures"
```

---

## 二、常用软件配置（建议执行）

### 2.1 Docker Desktop 配置

**目标**：新镜像和容器数据默认到 D 盘

**配置方法**：
1. 打开 Docker Desktop
2. 点击右上角 **设置** ⚙️
3. 选择 **Resources** → **WSL Integration**
4. 查看当前 WSL 发行版位置
5. 如需迁移，参考 `docker_migration_guide.md`

**验证命令**：
```powershell
# 查看 Docker WSL 数据位置
wsl -l -v
# 查看 WSL 默认安装位置
wsl --status
```

### 2.2 IDE 和开发工具配置

#### VSCode
1. 打开 VSCode
2. 按 `Ctrl+,` 打开设置
3. 搜索 `extensions`
4. 修改扩展安装路径（如支持）
5. 配置工作区默认到 D 盘

#### Trae IDE
- 当前项目已在 D 盘：`d:\syskadun`
- 建议新创建的项目都放在 D 盘

#### 通义灵码
- 缓存位置：`C:\Users\xuyif\.lingma`（6.42GB）
- 建议定期清理或配置缓存到 D 盘（如支持）

### 2.3 Python 环境配置

**Miniconda/Anaconda**：
- 当前占用：3.12GB
- 建议：如需要新环境，安装到 D 盘
```powershell
# 创建环境时指定目录
conda create --prefix D:\Python\envs\myenv python=3.9
```

**pip 缓存配置**：
```powershell
# 配置 pip 缓存到 D 盘
$env:PIP_CACHE_DIR = "D:\pip-cache"
# 永久配置：添加 %PIP_CACHE_DIR% 环境变量
```

### 2.4 浏览器配置

**Chrome/Edge**：
1. 打开浏览器设置
2. 搜索 **下载**
3. 修改下载位置为 D 盘（如 `D:\Downloads`）
4. 开启 **下载前询问每个文件的保存位置**

### 2.5 微信/QQ 配置

**微信**：
1. 打开微信设置
2. 选择 **文件管理**
3. 点击 **更改**，选择 D 盘目录（如 `D:\WeChat Files`）
4. 迁移历史聊天记录

**QQ**：
1. 打开 QQ 设置
2. 选择 **文件管理**
3. 修改文件保存位置到 D 盘

---

## 三、开发环境配置（推荐）

### 3.1 项目目录规划

**建议目录结构**：
```
D:\
├── XUYIFEI\XUPROJECTS\     # 个人项目
│   ├── TDQQXM\
│   ├── syskadun\
│   └── ...
├── DevProjects\            # 开发项目
│   ├── frontend\
│   ├── backend\
│   └── ...
├── Docker\                 # Docker 数据
│   ├── wsl\
│   └── volumes\
├── ComfyUI\                # AI 模型
│   └── models\
├── Downloads\              # 下载文件
├── Software\               # 软件安装
│   ├── Python\
│   ├── NodeJS\
│   └── ...
└── Cache\                  # 缓存文件
    ├── pip-cache\
    ├── npm-cache\
    └── ...
```

### 3.2 环境变量配置

**添加 D 盘路径到环境变量**：
```powershell
# 1. 打开系统环境变量
# Win + R → sysdm.cpl → 高级 → 环境变量

# 2. 添加用户环境变量
PIP_CACHE_DIR=D:\Cache\pip-cache
NPM_CONFIG_CACHE=D:\Cache\npm-cache
NODE_MODULES=D:\Software\node_modules

# 3. 添加系统环境变量（如需要）
JAVA_HOME=D:\Software\Java\jdk
PYTHON_HOME=D:\Software\Python
```

### 3.3 包管理器配置

**npm/yarn 配置**：
```powershell
# 配置 npm 全局包安装到 D 盘
npm config set prefix "D:\Software\node-global"
npm config set cache "D:\Cache\npm-cache"

# 配置 yarn
yarn config set global-folder "D:\Software\yarn-global"
yarn config set cache-folder "D:\Cache\yarn-cache"
```

**Maven/Gradle 配置**：
```powershell
# Maven 仓库配置（settings.xml）
# D:\Software\Maven\conf\settings.xml
<localRepository>D:\Cache\maven-repo</localRepository>

# Gradle 配置（gradle.properties）
# C:\Users\xuyif\.gradle\gradle.properties
org.gradle.caching=true
org.gradle.daemon=true
```

---

## 四、监控与告警（可选但推荐）

### 4.1 创建 C 盘空间监控脚本

**文件**：`d:\syskadun\monitor_c_drive.ps1`

```powershell
# C 盘空间监控脚本
$drive = Get-PSDrive C
$freeGB = [math]::Round($drive.Free / 1GB, 2)
$totalGB = [math]::Round(($drive.Used + $drive.Free) / 1GB, 2)
$usedPercent = [math]::Round(($drive.Used / ($drive.Used + $drive.Free)) * 100, 2)

Write-Host "C 盘空间监控报告" -ForegroundColor Cyan
Write-Host "================" -ForegroundColor Cyan
Write-Host "总容量：$totalGB GB"
Write-Host "已使用：$([math]::Round($drive.Used / 1GB, 2)) GB"
Write-Host "可用空间：$freeGB GB"
Write-Host "使用率：$usedPercent%"
Write-Host ""

# 阈值告警
if ($usedPercent -gt 85) {
    Write-Host "⚠️  警告：C 盘使用率超过 85%！" -ForegroundColor Red
    Write-Host "建议立即清理或迁移文件" -ForegroundColor Yellow
} elseif ($usedPercent -gt 75) {
    Write-Host "⚡ 注意：C 盘使用率超过 75%" -ForegroundColor Yellow
    Write-Host "建议关注空间使用情况" -ForegroundColor Gray
} else {
    Write-Host "✅ C 盘空间充足" -ForegroundColor Green
}

# 显示前 5 大文件夹
Write-Host "`n前 5 大文件夹:" -ForegroundColor Cyan
Get-ChildItem -Path "C:\" -Directory -ErrorAction SilentlyContinue | 
Where-Object { $_.PSIsContainer } |
ForEach-Object {
    $size = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | 
             Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1GB
    [PSCustomObject]@{
        Name = $_.Name
        SizeGB = [math]::Round($size, 2)
    }
} | Sort-Object SizeGB -Descending | Select-Object -First 5 | 
Format-Table -AutoSize
```

**使用方法**：
```powershell
# 手动执行
.\monitor_c_drive.ps1

# 或添加到开机启动
# 任务计划程序 → 创建任务 → 触发器：登录时 → 操作：启动 PowerShell -File "d:\syskadun\monitor_c_drive.ps1"
```

### 4.2 创建定期清理任务

**文件**：`d:\syskadun\scheduled_cleanup.ps1`

```powershell
# 定期清理脚本（每周执行一次）
Write-Host "开始定期清理..." -ForegroundColor Cyan

# 1. 清理临时文件
$tempPaths = @("$env:TEMP", "$env:TMP", "C:\Windows\Temp")
foreach ($path in $tempPaths) {
    if (Test-Path $path) {
        Remove-Item $path\* -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "已清理：$path" -ForegroundColor Green
    }
}

# 2. 清理回收站
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Write-Host "已清理回收站" -ForegroundColor Green

# 3. 清理 Windows 更新缓存
Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
Start-Service wuauserv -ErrorAction SilentlyContinue
Write-Host "已清理 Windows 更新缓存" -ForegroundColor Green

# 4. 清理浏览器缓存（如需要）
# 注意：需要关闭浏览器

Write-Host "定期清理完成！" -ForegroundColor Green
```

**配置任务计划程序**：
1. 打开 **任务计划程序**
2. 点击 **创建基本任务**
3. 名称：`C 盘定期清理`
4. 触发器：**每周**，选择周日凌晨 2:00
5. 操作：**启动程序**
   - 程序：`PowerShell`
   - 参数：`-ExecutionPolicy Bypass -File "d:\syskadun\scheduled_cleanup.ps1"`
6. 完成配置

---

## 五、快速检查清单

### 5.1 配置完成检查

**执行以下检查确保配置完成**：

```powershell
# 1. 检查 Windows 存储设置
Write-Host "检查 Windows 存储设置..."
# 手动检查：设置 → 系统 → 存储 → 高级存储设置 → 保存新内容的地方

# 2. 检查 Docker 位置
Write-Host "检查 Docker 位置..."
wsl -l -v

# 3. 检查环境变量
Write-Host "检查环境变量..."
Get-ChildItem Env: | Where-Object { $_.Name -like "*CACHE*" -or $_.Name -like "*PATH*" } | 
Format-Table Name, Value -AutoSize

# 4. 检查 npm/yarn 配置
Write-Host "检查 npm 配置..."
npm config get prefix
npm config get cache

# 5. C 盘空间报告
$drive = Get-PSDrive C
$freeGB = [math]::Round($drive.Free / 1GB, 2)
Write-Host "当前 C 盘可用空间：$freeGB GB" -ForegroundColor Green
```

### 5.2 长期维护建议

**每周**：
- 运行一次 `monitor_c_drive.ps1` 检查空间
- 清理下载文件夹

**每月**：
- 运行一次 `scheduled_cleanup.ps1`
- 检查 Docker 镜像和容器，清理未使用的
- 清理 IDE 缓存（如 `.vscode`、`.lingma`）

**每季度**：
- 检查 D 盘空间使用情况
- 审查已安装软件，卸载不常用的
- 备份重要数据

---

## 六、常见问题

### Q1: 配置后新应用还是安装到 C 盘怎么办？
**A**: 某些软件会忽略 Windows 设置，强制指定安装路径。建议：
1. 安装时手动选择自定义安装，路径改为 D 盘
2. 使用绿色版/便携版软件
3. 使用 Scoop/Chocolatey 等包管理器配置安装路径

### Q2: 如何查看哪些文件夹占用 C 盘空间？
**A**: 使用以下命令：
```powershell
# 扫描 C 盘前 10 大文件夹
Get-ChildItem -Path "C:\" -Directory -ErrorAction SilentlyContinue | 
ForEach-Object {
    $size = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | 
             Measure-Object -Property Length -Sum).Sum / 1GB
    [PSCustomObject]@{
        Path = $_.FullName
        SizeGB = [math]::Round($size, 2)
    }
} | Sort-Object SizeGB -Descending | Select-Object -First 10 | 
Format-Table -AutoSize
```

### Q3: 配置会影响已有软件吗？
**A**: 不会。配置只影响新安装的应用和新创建的文件。已有软件和数据保持不变。

### Q4: 需要重启吗？
**A**: 大部分配置立即生效，但建议重启一次以确保所有环境变量和系统设置完全生效。

---

## 七、执行记录

请在完成每个配置后打勾：

- [ ] Windows 新内容保存位置配置
- [ ] Docker Desktop 配置/迁移
- [ ] 浏览器下载位置配置
- [ ] 微信/QQ 文件位置配置
- [ ] Python 环境配置（如使用）
- [ ] npm/yarn 缓存配置（如使用）
- [ ] 环境变量配置
- [ ] 监控脚本创建
- [ ] 定期清理任务配置

---

## 八、预期效果

**配置完成后**：
- ✅ 新应用默认安装到 D 盘
- ✅ 新文件默认保存到 D 盘
- ✅ 开发工具缓存配置到 D 盘
- ✅ 自动监控 C 盘空间
- ✅ 定期自动清理

**长期效果**：
- 📈 C 盘使用率稳定在 70% 以下
- 📉 避免 C 盘再次爆满
- 🔧 减少手动清理频率
- 💾 D 盘成为主要数据存储盘

---

**创建时间**：2026-03-20  
**适用系统**：Windows 11  
**预计配置时间**：30-60 分钟
