# Docker 数据迁移到 D 盘指南

## 📊 当前 Docker 状态

- **Docker 模式**: WSL2 后端
- **发行版名称**: docker-desktop
- **当前占用**: 约 122GB 镜像 + 13.55GB 卷 + 17.78GB 构建缓存
- **可回收空间**: 约 51.56GB 镜像 + 5.176GB 卷

## ⚠️ 迁移方案说明

Docker Desktop 使用 WSL2 虚拟化技术，数据存储在其虚拟磁盘中。由于您正在使用 Docker Desktop，**迁移到 D 盘需要以下步骤**：

---

## 📋 迁移方案（推荐方案）

### 方案 1：先清理 Docker 空间（立即可执行，无需迁移）

**执行命令**：
```powershell
docker system prune -a -f --volumes
```

**说明**：
- 清理所有未使用的镜像（不只是悬空镜像）
- 清理所有未使用的卷
- 清理构建缓存
- **预计可释放**: 50-70GB 空间

**注意**：这会删除未使用的镜像，需要时重新下载

---

### 方案 2：迁移 WSL Docker 数据到 D 盘（需要重启 Docker）

**步骤**：

1. **停止 Docker Desktop**
   ```powershell
   wsl --terminate docker-desktop
   wsl --shutdown
   ```

2. **导出 Docker 数据**
   ```powershell
   # 导出到 D 盘临时位置
   wsl --export docker-desktop D:\docker-desktop-backup.tar
   ```

3. **注销当前 Docker 发行版**
   ```powershell
   wsl --unregister docker-desktop
   ```

4. **导入到 D 盘**
   ```powershell
   # 在 D 盘创建 Docker 数据目录
   New-Item -ItemType Directory -Path "D:\WSL\Docker" -Force
   
   # 导入到 D 盘
   wsl --import docker-desktop D:\WSL\Docker D:\docker-desktop-backup.tar --version 2
   
   # 删除临时备份文件
   Remove-Item D:\docker-desktop-backup.tar
   ```

5. **重启 Docker Desktop**

**预计可释放**: C 盘约 100-150GB 空间

---

### 方案 3：配置 Docker 数据根目录（Docker Desktop 4.25+）

如果您使用的是 Docker Desktop 4.25 或更高版本：

1. 打开 Docker Desktop 设置
2. 进入 **General** 选项卡
3. 找到 **Data Directory** 设置
4. 点击 **Browse** 选择 D 盘的新位置
5. 点击 **Apply & Restart**

---

## 🎯 推荐操作顺序

1. **先执行方案 1** - 立即清理 Docker 空间（约 50-70GB）
2. **考虑方案 2 或 3** - 如果需要更多空间，迁移 Docker 数据到 D 盘

---

## 📝 执行清理命令（推荐先执行）

```powershell
# 清理 Docker 悬空资源（安全）
docker system prune -f

# 清理所有未使用资源（会删除未使用的镜像）
# 注意：执行此命令前请确认不需要的镜像
docker system prune -a -f --volumes
```

---

## ⚠️ 注意事项

1. **方案 1** 会删除：
   - 所有已停止容器的镜像
   - 所有未使用的卷
   - 构建缓存
   
2. **方案 2** 会：
   - 完全迁移 Docker 数据到 D 盘
   - 需要重启 Docker Desktop
   - 不影响正在运行的容器配置

3. **方案 3** 仅适用于：
   - Docker Desktop 4.25+ 版本
   - 最简单的迁移方式

---

## 📞 需要您确认

请选择您想要执行的方案：
- [ ] 方案 1：立即清理 Docker 空间（推荐先执行）
- [ ] 方案 2：迁移 Docker 数据到 D 盘（需要重启 Docker）
- [ ] 方案 3：使用 Docker Desktop 设置迁移（如果版本支持）

---

**生成时间**: 2026-03-20  
**适用系统**: Docker Desktop with WSL2 backend
