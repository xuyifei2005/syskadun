$ErrorActionPreference = "Continue"
$dstBase = "D:\AppData_Migrate"
$user = "C:\Users\xuyif"
$fso = New-Object -ComObject Scripting.FileSystemObject

New-Item -ItemType Directory -Path $dstBase -Force | Out-Null

function Migrate-Folder($src, $dstName) {
    $dst = "$dstBase\$dstName"
    Write-Host "`n--- Processing: $dstName ---"
    
    if (-not (Test-Path $src)) { Write-Host "  [SKIP] Not found: $src"; return }
    
    $item = Get-Item $src -Force -ErrorAction SilentlyContinue
    if ($item -and $item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        Write-Host "  [SKIP] Already symlinked"; return
    }
    
    try { $sizeGB = [math]::Round(($fso.GetFolder($src).Size)/1GB, 2); Write-Host "  Size: $sizeGB GB" } catch {}
    
    # Use robocopy for reliable move (handles large trees better)
    Write-Host "  Moving via robocopy..."
    robocopy "$src" "$dst" /E /MOVE /R:1 /W:1 /NFL /NDL /NJH | Out-Null
    
    # Check if source dir is now empty or gone
    if (-not (Test-Path $src)) {
        New-Item -ItemType Directory -Path $src -Force | Out-Null
    }
    
    # Create symlink
    $result = cmd /c mklink /D `"$src`" `"$dst`" 2>&1
    if ($result -match "symbolic link") {
        Write-Host "  [OK] Symlink created!"
        $verify = Test-Path $src; Write-Host "  Verify: $verify"
    } else {
        Write-Host "  [WARN] Symlink: $result"
    }
}

# Step 3: Huawei + Programs + JianyingPro
Write-Host "========== STEP 3: Huawei + Programs + JianyingPro =========="
Migrate-Folder "$user\AppData\Local\Huawei"      "Huawei"
Migrate-Folder "$user\AppData\Local\Programs"     "Programs"
Migrate-Folder "$user\AppData\Local\JianyingPro"  "JianyingPro"

Write-Host "`n========== STEP 3 COMPLETE =========="
