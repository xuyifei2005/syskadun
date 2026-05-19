---
name: video-downloader
description: |
  使用 yt-dlp 下载各大网站视频。当用户提供视频链接需要下载时触发此技能。
  支持的平台包括：YouTube、B站、Twitter/X、TikTok、抖音、Instagram、Facebook、Vimeo 等 1200+ 网站。
  触发词：下载视频、保存视频、视频下载、download video、保存到本地、离线观看、视频链接。
---

# Video Downloader (yt-dlp)

基于 yt-dlp 的视频下载技能，支持从 1200+ 网站下载视频和音频。

## 安装状态

已安装版本：2026.02.21

可执行文件路径：
```
C:\Users\xuyif\AppData\Roaming\Python\Python314\Scripts\yt-dlp.exe
```

## 支持的平台

- **视频平台**: YouTube, B站, Twitter/X, TikTok, 抖音, Instagram, Facebook, Vimeo, 优酷, 爱奇艺, 腾讯视频等
- **完整列表**: https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md

## 快速开始

当用户提供视频链接时，直接执行下载命令：

```powershell
# 基本下载命令（使用完整路径）
& "C:\Users\xuyif\AppData\Roaming\Python\Python314\Scripts\yt-dlp.exe" "视频链接"

# 或使用 python 模块方式
python -m yt_dlp "视频链接"
```

## 常用下载命令

### 1. 下载单个视频

```powershell
# 下载最佳质量（默认）
python -m yt_dlp "视频链接"

# 指定输出目录和文件名
python -m yt_dlp -o "D:/Videos/%(title)s.%(ext)s" "视频链接"
```

### 2. 选择视频质量

```powershell
# 查看可用格式
python -m yt_dlp -F "视频链接"

# 下载最佳视频+最佳音频合并
python -m yt_dlp -f "bestvideo+bestaudio" "视频链接"

# 下载 1080p
python -m yt_dlp -f "bestvideo[height<=1080]+bestaudio" "视频链接"
```

### 3. 下载音频/音乐

```powershell
# 仅下载音频（最佳质量）
python -m yt_dlp -x --audio-format mp3 "视频链接"
```

### 4. 下载播放列表

```powershell
# 下载整个播放列表
python -m yt_dlp "播放列表链接"

# 下载播放列表中的特定视频
python -m yt_dlp --playlist-items 1,3,5 "播放列表链接"
```

### 5. 下载字幕

```powershell
# 列出可用字幕
python -m yt_dlp --list-subs "视频链接"

# 下载中文字幕
python -m yt_dlp --write-subs --sub-langs zh "视频链接"
```

## 输出模板

```powershell
# 基本模板
-o "%(title)s.%(ext)s"

# 包含上传者和标题
-o "%(uploader)s - %(title)s.%(ext)s"

# B站专用模板
-o "%(title)s [%(id)s].%(ext)s"
```

## 常用选项组合

```powershell
# 高质量下载
python -m yt_dlp -f "bestvideo+bestaudio" -o "%(title)s.%(ext)s" "视频链接"

# 代理设置
python -m yt_dlp --proxy "http://127.0.0.1:7890" "视频链接"
```

## B站下载

```powershell
# B站下载（需要登录的视频）
python -m yt_dlp --cookies-from-browser chrome "B站视频链接"
```

## 工作流程

当用户提供视频链接时：

1. **解析链接**: 确认视频平台和链接有效性
2. **询问需求**: 确认下载质量、格式、保存位置
3. **执行下载**: 使用 `python -m yt_dlp` 命令下载
4. **验证结果**: 确认文件已成功下载

## 更新

```powershell
pip install -U yt-dlp
```

## 故障排除

| 问题 | 解决方案 |
|------|---------|
| 下载失败 | 更新 yt-dlp |
| 需要登录 | 使用 cookies |
| 格式错误 | 查看可用格式 |
| 合并失败 | 安装 FFmpeg |
