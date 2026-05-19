$ErrorActionPreference = "Continue"
$dstBase = "D:\AppData_Migrate"
$user = "C:\Users\xuyif"

New-Item -ItemType Directory -Path $dstBase -Force | Out-Null
Write-Host "Target directory: $dstBase"

$migrations = @(
    @{ Src = "$user\AppData\Roaming\Trae CN"; DstName = "Trae CN" },
    @{ Src = "$user\AppData\Roaming\Trae";       DstName = "Trae" }
)

foreach ($m in $migrations) {
    $src = $m.Src
    $dst = "$dstBase\$($m.DstName)"
    
    Write-Host "`n--- Processing: $($m.DstName) ---"
    Write-Host "  Source: $src"
    
    if (-not (Test-Path $src)) {
        Write-Host "  [SKIP] Source not found"
        continue
    }
    
    # Check if already a symlink
    $item = Get-Item $src -Force -ErrorAction SilentlyContinue
    if ($item -and $item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        Write-Host "  [SKIP] Already a symlink"
        continue
    }
    
    # Measure source size before move
    $fso = New-Object -ComObject Scripting.FileSystemObject
    try {
        $sizeBefore = [math]::Round(($fso.GetFolder($src).Size) / 1GB, 2)
        Write-Host "  Size: $sizeBefore GB"
    } catch {
        Write-Host "  [WARN] Could not measure size"
    }
    
    # Move to D drive
    Write-Host "  Moving to D drive..."
    try {
        Move-Item -Path $src -Destination $dst -Force -ErrorAction Stop
        Write-Host "  [OK] Moved to $dst"
    } catch {
        Write-Host "  [ERROR] Move failed: $_"
        continue
    }
    
    # Create symbolic link
    Write-Host "  Creating symlink..."
    $result = cmd /c mklink /D `"$src`" `"$dst`" 2>&1
    $linkResult = $result | Select-String "symbolic link|created"
    if ($linkResult) {
        Write-Host "  [OK] Symlink created!"
        
        # Verify
        $verify = Test-Path "$src\User"
        Write-Host "  Verify (User dir exists): $verify"
    } else {
        Write-Host "  [WARN] Symlink result: $result"
    }
}

Write-Host "`n========== STEP 2 COMPLETE =========="
