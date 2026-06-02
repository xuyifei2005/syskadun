$ErrorActionPreference = "Continue"
$dstBase = "D:\AppData_Migrate"
$user = "C:\Users\xuyif"
$fso = New-Object -ComObject Scripting.FileSystemObject
New-Item -ItemType Directory -Path $dstBase -Force | Out-Null

function Migrate-Folder($src, $dstName) {
    $dst = "$dstBase\$dstName"
    Write-Host "`n--- $dstName ---"
    if (-not (Test-Path $src)) { Write-Host "  [SKIP] Not found"; return }
    $item = Get-Item $src -Force -ErrorAction SilentlyContinue
    if ($item -and ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) { Write-Host "  [SKIP] Already linked"; return }
    try { $sz = [math]::Round(($fso.GetFolder($src).Size)/1GB,2); Write-Host "  Size: $sz GB" } catch {}
    robocopy "$src" "$dst" /E /MOVE /R:1 /W:1 /NFL /NDL /NJH | Out-Null
    if (Test-Path $src) {
        Get-ChildItem $src -Recurse -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA SilentlyContinue
        Remove-Item $src -Recurse -Force -EA SilentlyContinue
    }
    try { New-Item -ItemType Junction -Path $src -Target $dst -Force -ErrorAction Stop | Out-Null; Write-Host "  [OK] Junction" } catch { Write-Host "  [PARTIAL] Moved to D, symlink failed (locked)" }
}

Write-Host "===== STEP 4 ====="
Migrate-Folder "$user\AppData\Roaming\LarkShell" "LarkShell"
Migrate-Folder "$user\AppData\Roaming\Python" "Python_Roaming"
Migrate-Folder "$user\AppData\Roaming\Code" "VSCode"
Migrate-Folder "$user\AppData\Roaming\kingsoft" "WPS_kingsoft"

Write-Host "`n===== STEP 5 ====="
Migrate-Folder "$user\AppData\Roaming\Qoder" "Qoder"
Migrate-Folder "$user\AppData\Roaming\Tencent" "Tencent"
Migrate-Folder "$user\AppData\Local\npm-cache" "npm-cache_Local"
Migrate-Folder "$user\AppData\Roaming\Lingma" "Lingma"
Migrate-Folder "$user\AppData\Local\ms-playwright" "ms-playwright"
Migrate-Folder "$user\AppData\Local\stm32cube" "stm32cube"
Migrate-Folder "$user\AppData\Local\ESRI" "ESRI"
Migrate-Folder "$user\AppData\Roaming\npm" "npm_Roaming"
Migrate-Folder "$user\AppData\Roaming\Figma" "Figma"
Migrate-Folder "$user\AppData\Roaming\Shandianshuo" "Shandianshuo"
Migrate-Folder "$user\AppData\Local\nvm" "nvm"
Migrate-Folder "$user\AppData\Local\Everything" "Everything"
Migrate-Folder "$user\AppData\Local\Google" "Google"
Migrate-Folder "$user\AppData\Local\JetBrains" "JetBrains"
Migrate-Folder "$user\AppData\Local\AnthropicClaude" "AnthropicClaude"

Write-Host "`n===== DONE ====="
