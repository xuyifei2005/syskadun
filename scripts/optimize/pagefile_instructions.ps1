# 虚拟内存配置指南
# 由于需要管理员权限，请手动执行以下步骤

Write-Host "========== 虚拟内存手动配置指南 ==========" -ForegroundColor Cyan
Write-Host ""
Write-Host "由于修改虚拟内存需要管理员权限，请按以下步骤手动操作：" -ForegroundColor Yellow
Write-Host ""
Write-Host "方法 1：通过图形界面（推荐）" -ForegroundColor Green
Write-Host "1. 右键点击 '此电脑' → '属性'"
Write-Host "2. 点击 '高级系统设置'"
Write-Host "3. 在 '高级' 选项卡，点击 '性能' 下的 '设置'"
Write-Host "4. 点击 '高级' 选项卡"
Write-Host "5. 点击 '虚拟内存' 下的 '更改'"
Write-Host "6. 取消勾选 '自动管理所有驱动器的分页文件大小'"
Write-Host "7. 选择 C 盘 → 选择 '无分页文件' → 点击 '设置'"
Write-Host "8. 选择 D 盘 → 选择 '系统管理的大小' 或 '自定义大小'"
Write-Host "   - 初始大小：4096 MB (4GB)"
Write-Host "   - 最大值：8192 MB (8GB)"
Write-Host "9. 点击 '设置' → '确定'"
Write-Host "10. 重启计算机"
Write-Host ""
Write-Host "方法 2：使用管理员权限运行 PowerShell" -ForegroundColor Green
Write-Host "1. 右键点击 PowerShell → '以管理员身份运行'"
Write-Host "2. 执行以下命令："
Write-Host ""
Write-Host "   powershell -ExecutionPolicy Bypass -File `"d:\syskadun\move_pagefile_to_D.ps1`""
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
