# ComfyUI 模型迁移指南

## 📊 当前状态

- **当前位置**: `C:\Users\xuyif\Documents\ComfyUI\models`
- **模型大小**: 约 2.46 GB
- **主要文件**:
  - checkpoints: 1.99 GB
  - sams: 0.35 GB
  - ultralytics: 0.12 GB

## 📋 迁移步骤

### 方法 1：手动复制（推荐）

1. **在 D 盘创建目标文件夹**
   ```
   D:\ComfyUI\models
   ```

2. **复制模型文件**
   - 打开文件资源管理器
   - 导航到 `C:\Users\xuyif\Documents\ComfyUI\models`
   - 全选所有文件 (Ctrl+A)
   - 复制到 `D:\ComfyUI\models`

3. **验证复制完成**
   - 确认 D 盘文件夹大小约 2.46GB

4. **删除原文件夹**
   - 删除 `C:\Users\xuyif\Documents\ComfyUI\models`

5. **创建符号链接**（以管理员身份运行 PowerShell）
   ```powershell
   New-Item -ItemType SymbolicLink -Path "C:\Users\xuyif\Documents\ComfyUI\models" -Value "D:\ComfyUI\models"
   ```

### 方法 2：修改 ComfyUI 配置

如果 ComfyUI 支持配置文件指定模型路径：

1. 找到 ComfyUI 配置文件
2. 修改模型路径为 `D:\ComfyUI\models`
3. 移动模型文件到 D 盘

---

## 🎯 预期效果

- **释放 C 盘空间**: 约 2.46 GB
- **ComfyUI 使用不受影响**: 符号链接确保程序仍从原路径访问

---

## ⚠️ 注意事项

- 符号链接需要管理员权限创建
- 如果不想创建符号链接，可以直接修改 ComfyUI 启动参数（如果支持）

---

**生成时间**: 2026-03-20
