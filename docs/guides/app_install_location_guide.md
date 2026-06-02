# 配置新应用默认安装到 D 盘

## 方法 1：Windows 10/11 设置（推荐）

### 步骤：
1. 打开 **设置** (Win + I)
2. 点击 **系统**
3. 点击左侧 **存储**
4. 点击 **更改新的内容保存位置**
5. 在 "新的应用将保存到" 下拉菜单中选择 **D 盘**
6. 点击 **应用**

## 方法 2：修改注册表

### 步骤：
1. 按 Win + R，输入 `regedit`，回车
2. 导航到：
   ```
   HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion
   ```
3. 修改以下键值：
   - **ProgramFilesDir**: `D:\Program Files`
   - **ProgramFilesDir (x86)**: `D:\Program Files (x86)`

### 警告：修改注册表前请备份！

## 方法 3：手动指定安装位置

对于每个要安装的应用：
1. 在安装过程中选择 **自定义安装**
2. 将安装路径改为 `D:\Program Files\AppName`
3. 或 `D:\Users\xuyif\AppData\Local\Programs\AppName`

---

## 建议

- **方法 1** 最简单，适用于 Microsoft Store 应用
- **方法 2** 需要管理员权限，可能影响系统更新
- **方法 3** 适用于手动安装的应用

---

## 补充：移动已安装的应用

如果需要移动已安装的应用到 D 盘，可以使用：

1. **Windows自带功能**（部分应用支持）：
   - 设置 → 应用 → 已安装的应用 → 选择应用 → 移动

2. **使用 mklink 符号链接**：
   - 将应用文件夹移动到 D 盘
   - 在原位置创建符号链接指向新位置
   - 需要管理员权限

---

## 示例：Steam 游戏迁移

Steam 游戏默认安装在 C 盘，可以：
1. 打开 Steam 设置
2. 选择 "下载" → "Steam 库文件夹"
3. 添加 D 盘文件夹作为新的库
4. 安装新游戏时选择 D 盘库
