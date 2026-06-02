# GPEDIT 安装进度监控脚本

Write-Host "Checking GPEDIT installation status..." -ForegroundColor Cyan
Write-Host ""

# Check if gpedit.msc exists
$gpeditPath = "$env:SystemRoot\system32\gpedit.msc"
if (Test-Path $gpeditPath) {
    Write-Host "[SUCCESS] gpedit.msc is already installed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can run it by pressing Win+R and typing: gpedit.msc" -ForegroundColor Yellow
} else {
    Write-Host "[INFO] gpedit.msc not found yet." -ForegroundColor Yellow
    Write-Host "Installation may still be in progress." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Checking Group Policy packages..." -ForegroundColor Cyan
$packages = @()
$packages += Get-ChildItem "$env:SystemRoot\servicing\Packages" -Filter "Microsoft-Windows-GroupPolicy-ClientExtensions-Package~3*.mum"
$packages += Get-ChildItem "$env:SystemRoot\servicing\Packages" -Filter "Microsoft-Windows-GroupPolicy-ClientTools-Package~3*.mum"

Write-Host "Found $($packages.Count) Group Policy packages" -ForegroundColor Green
foreach ($pkg in $packages) {
    Write-Host "  - $($pkg.Name)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
