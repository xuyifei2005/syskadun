# P0: DevTools + P1: Hidden Dirs Migration
$ErrorActionPreference = "Continue"
$user = $env:USERPROFILE
$fso = New-Object -ComObject Scripting.FileSystemObject

$dstBase = "D:\DevTools"
New-Item -ItemType Directory -Path $dstBase -Force | Out-Null

function Get-FolderSizeGB($path) {
    try { return [math]::Round(($fso.GetFolder($path).Size)/1GB, 2) } catch { return 0 }
}

function Migrate-Dir($src, $dst, $createJunction = $true) {
    if (-not (Test-Path $src)) { Write-Host "  [SKIP] not found: $src"; return }
    
    $item = Get-Item $src -Force -EA SilentlyContinue
    if ($item -and ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
        Write-Host "  [SKIP] already linked: $src"; return }
    
    $sz = Get-FolderSizeGB $src
    Write-Host "  Moving: $src ($sz GB) -> $dst ..."
    
    robocopy $src $dst /E /MOVE /R:1 /W:1 /NFL /NDL /NJH /NP | Out-Null
    
    if (Test-Path $src) {
        Get-ChildItem $src -Recurse -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA SilentlyContinue
        Remove-Item $src -Recurse -Force -EA SilentlyContinue
    }
    
    if ($createJunction -and (Test-Path $dst)) {
        try {
            New-Item -ItemType Junction -Path $src -Target $dst -Force -ErrorAction Stop | Out-Null
            Write-Host "  [OK] Junction created"
        } catch {
            Write-Host "  [PARTIAL] moved to D but junction failed (locked)" }
    } else {
        Write-Host "  [OK] Moved to: $dst" }
}


Write-Host ""
Write-Host "============================================"
Write-Host "  P0: Dev Tools Migration"
Write-Host "============================================"

# --- 1. npm ---
Write-Host "`n[1/8] npm global + cache..."
$npmGlobalSrc = "$user\AppData\Roaming\npm"
$npmCacheSrc = "$user\AppData\Local\npm-cache"
$npmGlobalDst = "$dstBase\npm-global"
$npmCacheDst = "$dstBase\npm-cache"

Migrate-Dir $npmGlobalSrc $npmGlobalDst
Migrate-Dir $npmCacheSrc $npmCacheDst

npm config set prefix $npmGlobalDst 2>$null
npm config set cache $npmCacheDst 2>$null
Write-Host "  npm config updated: prefix=$npmGlobalDst cache=$npmCacheDst"

$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
$npmBin = $npmGlobalDst
if ($currentPath -notlike "*$npmBin*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$npmBin", "User")
    Write-Host "  [OK] Added to user PATH: $npmBin" }

# --- 2. nvm ---
Write-Host "`n[2/8] nvm..."
$nvmSrc = "$user\AppData\Local\nvm"
$nvmDst = "$dstBase\nvm"
Migrate-Dir $nvmSrc $nvmDst
nvm list > "$dstBase\nvm-versions-backup.txt" 2>$null
Write-Host "  Node versions backed up to nvm-versions-backup.txt"

# --- 3. pip/Python ---
Write-Host "`n[3/8] pip/Python user data..."
$pipUserSrc = "$user\AppData\Roaming\Python"
$pipCacheSrc = "$user\AppData\Local\pip"
$pipUserDst = "$dstBase\python-user"
$pipCacheDst = "$dstBase\pip-cache"

if (Test-Path $pipUserSrc) { Migrate-Dir $pipUserSrc $pipUserDst }
if (Test-Path $pipCacheSrc) { Migrate-Dir $pipCacheSrc $pipCacheDst }

pip config set global.target $pipUserDst 2>$null
pip config set global.cache-dir $pipCacheDst 2>$null
Write-Host "  pip config updated"

# --- 4. Cargo/Rustup ---
Write-Host "`n[4/8] Cargo/Rustup..."
$cargoSrc = "$user\.cargo"
$rustupSrc = "$user\.rustup"
$cargoDst = "$dstBase\.cargo"
$rustupDst = "$dstBase\.rustup"

Migrate-Dir $cargoSrc $cargoDst
Migrate-Dir $rustupSrc $rustupDst

[Environment]::SetEnvironmentVariable("CARGO_HOME", $cargoDst, "User")
[Environment]::SetEnvironmentVariable("RUSTUP_HOME", $rustupDst, "User")
Write-Host "  [OK] CARGO_HOME=$cargoDst RUSTUP_HOME=$rustupDst"

# --- 5. GOPATH ---
Write-Host "`n[5/8] GOPATH..."
$goSrc = "$user\go"
$goDst = "$dstBase\go"
Migrate-Dir $goSrc $goDst
[Environment]::SetEnvironmentVariable("GOPATH", $goDst, "User")
Write-Host "  [OK] GOPATH=$goDst"

# --- 6. Bun ---
Write-Host "`n[6/8] Bun..."
$bunSrc = "$user\.bun"
$bunDst = "$dstBase\bun"
Migrate-Dir $bunSrc $bunDst
[Environment]::SetEnvironmentVariable("BUN_INSTALL", $bunDst, "User")
Write-Host "  [OK] BUN_INSTALL=$bunDst"

# --- 7. Maven .m2 ---
Write-Host "`n[7/8] Maven (.m2)..."
$m2Src = "$user\.m2"
$m2Dst = "$dstBase\.m2"
Migrate-Dir $m2Src $m2Dst

# --- 8. Gradle ---
Write-Host "`n[8/8] Gradle..."
$gradleSrc = "$user\.gradle"
$gradleDst = "$dstBase\.gradle"
Migrate-Dir $gradleSrc $gradleDst
[Environment]::SetEnvironmentVariable("GRADLE_USER_HOME", $gradleDst, "User")
Write-Host "  [OK] GRADLE_USER_HOME=$gradleDst"


Write-Host ""
Write-Host "============================================"
Write-Host "  P1: Hidden Directories Batch Migration"
Write-Host "============================================"

$hiddenDirsBase = "D:\UserProfile_Migrate"
New-Item -ItemType Directory -Path $hiddenDirsBase -Force | Out-Null

$hiddenDirs = @(
    ".lingma",
    ".codex",
    ".mult-fetch-mcp-server",
    ".docker",
    ".trae-cn",
    ".qoder",
    ".vscode",
    ".trae",
    ".claude",
    ".local",
    "clawd",
    ".agents",
    ".gemini",
    "projects",
    ".antigravity",
    ".cc-switch",
    ".cherrystudio",
    ".cursor",
    ".hvigor"
)

foreach ($dirName in $hiddenDirs) {
    Write-Host "`n  [$dirName]"
    Migrate-Dir "$user\$dirName" "$hiddenDirsBase\$dirName" }


Write-Host ""
Write-Host "============================================"
Write-Host "  P3: Config Backup"
Write-Host "============================================"

$configBackupDir = "D:\ConfigBackup"
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$destConfig = "$configBackupDir\$timestamp"
New-Item -ItemType Directory -Path $destConfig -Force | Out-Null

$configItems = @(
    @{ Src = "$user\.ssh";           Dst = "ssh" },
    @{ Src = "$user\.gitconfig";      Dst = "gitconfig" },
    @{ Src = "$user\.git-credentials";Dst = "git-credentials" },
    @{ Src = "$user\.npmrc";          Dst = "npmrc" },
    @{ Src = "$user\.wslconfig";      Dst = "wslconfig" },
    @{ Src = "$user\Documents\PowerShell"; Dst = "PowerShellProfile" }
)

foreach ($item in $configItems) {
    if (Test-Path $item.Src) {
        Copy-Item $item.Src "$destConfig\$($item.Dst)" -Recurse -Force
        Write-Host "  [BACKUP] $($item.Dst)" }
}

$wtSettings = Get-ChildItem "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal*" -ErrorAction SilentlyContinue
if ($wtSettings) {
    $wtFile = "$($wtSettings.FullName)\LocalState\settings.json"
    if (Test-Path $wtFile) {
        Copy-Item $wtFile "$destConfig\windows-terminal-settings.json" -Force
        Write-Host "  [BACKUP] windows-terminal-settings" }
}


# ========== Final Verification ==========
Write-Host ""
Write-Host "============================================"
Write-Host "  Final Verification"
Write-Host "============================================"

$linkCount = 0
$noLinkCount = 0

$allTargets = @(
    @{ Path = $npmGlobalSrc; Label = "npm-global" },
    @{ Path = $npmCacheSrc; Label = "npm-cache" },
    @{ Path = $nvmSrc; Label = "nvm" },
    @{ Path = $pipUserSrc; Label = "python-user" },
    @{ Path = $pipCacheSrc; Label = "pip-cache" },
    @{ Path = $cargoSrc; Label = "cargo" },
    @{ Path = $rustupSrc; Label = "rustup" },
    @{ Path = $goSrc; Label = "go" },
    @{ Path = $bunSrc; Label = "bun" },
    @{ Path = $m2Src; Label = "maven" },
    @{ Path = $gradleSrc; Label = "gradle" }
) + ($hiddenDirs | ForEach-Object { @{ Path = "$user\$_"; Label = $_ } })

Write-Host ""
Write-Host ("{0,-24} {1,-8} {2}" -f "Directory", "Size(GB)", "Status")
Write-Host ("-" * 55)

foreach ($t in $allTargets) {
    if (-not (Test-Path $t.Path)) { continue }
    $item = Get-Item $t.Path -Force -EA SilentlyContinue
    $isLink = $false
    $szStr = "-"
    
    if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        $isLink = $true
        $linkCount++
        $target = $item.Target
        if (Test-Path $target) {
            try { $szStr = "{0:N1}" -f (Get-FolderSizeGB $target) } catch {} }
    } else {
        try { $szStr = "{0:N1}" -f (Get-FolderSizeGB $t.Path) } catch {}
        $noLinkCount++ }
    
    $status = if ($isLink) { "[LINK OK]" } else { "[NO LINK]" }
    Write-Host ("{0,-24} {1,-8} {2}" -f $t.Label, $szStr, $status) }

$devToolsTotal = 0
if (Test-Path $dstBase) {
    Get-ChildItem $dstBase -Directory -EA SilentlyContinue | ForEach-Object {
        try { $devToolsTotal += $fso.GetFolder($_.FullName).Size } catch {} }}
$userProfileTotal = 0
if (Test-Path $hiddenDirsBase) {
    Get-ChildItem $hiddenDirsBase -Directory -EA SilentlyContinue | ForEach-Object {
        try { $userProfileTotal += $fso.GetFolder($_.FullName).Size } catch {} }}

$grandTotalGB = [math]::Round(($devToolsTotal + $userProfileTotal)/1GB, 1)

Write-Host ""
Write-Host ("=" * 55)
Write-Host " DevTools migrated : $([math]::Round($devToolsTotal/1GB, 1)) GB"
Write-Host " UserProfile migrated: $([math]::Round($userProfileTotal/1GB, 1)) GB"
Write-Host " Total freed from C: $grandTotalGB GB"
Write-Host " Links OK: $linkCount"
Write-Host " No link (locked): $noLinkCount"
Write-Host ""
Write-Host " DONE! Backup at: $destConfig"
