# Windows 10/11 Home GPEDIT Installer
# Usage: Right-click this file and select "Run with Administrator"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Windows GPEDIT Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[ERROR] Administrator privileges required!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please follow these steps:" -ForegroundColor Yellow
    Write-Host "1. Close this window" -ForegroundColor White
    Write-Host "2. Right-click install-gpedit.ps1" -ForegroundColor White
    Write-Host "3. Select 'Run as Administrator'" -ForegroundColor White
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    exit 1
}

Write-Host "[OK] Administrator privileges confirmed!" -ForegroundColor Green
Write-Host ""

# Find GPEDIT packages
Write-Host "[1/3] Searching for Group Policy packages..." -ForegroundColor Yellow
$packages = @()
$packages += Get-ChildItem "$env:SystemRoot\servicing\Packages" -Filter "Microsoft-Windows-GroupPolicy-ClientExtensions-Package~3*.mum"
$packages += Get-ChildItem "$env:SystemRoot\servicing\Packages" -Filter "Microsoft-Windows-GroupPolicy-ClientTools-Package~3*.mum"

Write-Host "      Found $($packages.Count) packages" -ForegroundColor Green
Write-Host ""

# Install packages
Write-Host "[2/3] Installing Group Policy components..." -ForegroundColor Yellow
Write-Host "      This may take 3-5 minutes, please wait..." -ForegroundColor Yellow
Write-Host ""

$success = 0
$failed = 0

foreach ($pkg in $packages) {
    Write-Host "      Installing: $($pkg.Name)" -ForegroundColor Gray
    
    $result = Start-Process -FilePath "dism.exe" `
        -ArgumentList "/online", "/norestart", "/add-package:$($pkg.FullName)" `
        -Wait -PassThru -NoNewWindow
    
    if ($result.ExitCode -eq 0 -or $result.ExitCode -eq 3010) {
        $success++
    } else {
        $failed++
    }
}

Write-Host ""
Write-Host "[3/3] Installation complete!" -ForegroundColor Green
Write-Host "      Success: $success packages" -ForegroundColor Green
Write-Host "      Failed: $failed packages" -ForegroundColor $(if ($failed -eq 0) {"Green"} else {"Red"})
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installation Successful!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. RESTART your computer (required)" -ForegroundColor White
Write-Host "2. After restart, press Win+R and type: gpedit.msc" -ForegroundColor White
Write-Host ""

$response = Read-Host "Restart computer now? (Y/N)"
if ($response -eq 'Y' -or $response -eq 'y') {
    Write-Host "Restarting..." -ForegroundColor Yellow
    Restart-Computer -Force
} else {
    Write-Host "Please restart your computer manually later" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
