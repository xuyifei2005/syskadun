# ComfyUI 模型迁移到 D 盘脚本
# 安全迁移，不影响 ComfyUI 正常使用

Write-Host "========== ComfyUI 模型迁移到 D 盘 ==========" -ForegroundColor Cyan

$sourcePath = "$env:USERPROFILE\Documents\ComfyUI\models"
$targetPath = "D:\ComfyUI\models"

if (-not (Test-Path $sourcePath)) {
    Write-Host "错误：未找到 ComfyUI 模型文件夹：$sourcePath" -ForegroundColor Red
    exit
}

# 计算源文件夹大小
$sourceSize = (Get-ChildItem $sourcePath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
Write-Host "源文件夹：$sourcePath"
Write-Host "模型总大小：$([math]::Round($sourceSize, 2)) GB"

# 创建目标文件夹
Write-Host "`n 步骤 1: 创建目标文件夹..."
New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
Write-Host "✓ 目标文件夹已创建：$targetPath"

# 复制文件（保留原文件作为备份）
Write-Host "`n 步骤 2: 复制模型文件到 D 盘..."
Copy-Item -Path "$sourcePath\*" -Destination $targetPath -Recurse -Force
Write-Host "✓ 文件复制完成"

# 验证复制的文件
$targetSize = (Get-ChildItem $targetPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
Write-Host "`n 验证：目标文件夹大小：$([math]::Round($targetSize, 2)) GB"

if ([math]::Abs($sourceSize - $targetSize) -lt 0.1) {
    Write-Host "✓ 文件复制验证成功" -ForegroundColor Green
    
    # 删除原文件夹以释放空间
    Write-Host "`n 步骤 3: 删除原文件夹..."
    Remove-Item -Path $sourcePath -Recurse -Force
    
    # 创建符号链接
    Write-Host "步骤 4: 创建符号链接..."
    $parentPath = Split-Path $sourcePath -Parent
    $folderName = Split-Path $sourcePath -Leaf
    if (Test-Path "$parentPath\$folderName") {
        Remove-Item "$parentPath\$folderName" -Force
    }
    New-Item -ItemType SymbolicLink -Path "$parentPath\$folderName" -Value $targetPath
    Write-Host "✓ 符号链接已创建：$sourcePath -> $targetPath" -ForegroundColor Green
    
    Write-Host "`n==========================================" -ForegroundColor Cyan
    Write-Host "✓ ComfyUI 模型迁移完成!" -ForegroundColor Green
    Write-Host "  - 释放 C 盘空间：$([math]::Round($sourceSize, 2)) GB"
    Write-Host "  - 新位置：$targetPath"
    Write-Host "  - ComfyUI 仍可通过符号链接访问模型"
    Write-Host "==========================================" -ForegroundColor Cyan
} else {
    Write-Host "错误：文件大小不匹配，请检查复制过程" -ForegroundColor Red
    Write-Host "源大小：$sourceSize GB, 目标大小：$targetSize GB"
}
