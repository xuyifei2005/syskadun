$fso = New-Object -ComObject Scripting.FileSystemObject
$userPath = "C:\Users\xuyif\AppData"

Write-Host "=== AppData\Local Top Space Consumers ==="
$localPath = "$userPath\Local"
$localResults = @()
$dirs = Get-ChildItem $localPath -Directory -ErrorAction SilentlyContinue
Write-Host "Found $($dirs.Count) top-level directories in Local"
foreach ($dir in $dirs) {
    try {
        $folder = $fso.GetFolder($dir.FullName)
        $sizeGB = [math]::Round($folder.Size / 1GB, 2)
        if ($sizeGB -ge 0.05) {
            $localResults += [PSCustomObject]@{ Name = $dir.Name; SizeGB = $sizeGB; Path = $dir.FullName }
            Write-Host "  $($dir.Name) : $sizeGB GB"
        }
    } catch { Write-Host "  $($dir.Name) : ERROR - $_" }
}
$localResults = $localResults | Sort-Object SizeGB -Descending
Write-Host "`nLocal Total (scanned >50MB): $([math]::Round(($localResults | Measure-Object -Property SizeGB -Sum).Sum, 2)) GB"

Write-Host "`n=== AppData\Roaming Top Space Consumers ==="
$roamingPath = "$userPath\Roaming"
$roamResults = @()
$roamDirs = Get-ChildItem $roamingPath -Directory -ErrorAction SilentlyContinue
Write-Host "Found $($roamDirs.Count) top-level directories in Roaming"
foreach ($dir in $roamDirs) {
    try {
        $folder = $fso.GetFolder($dir.FullName)
        $sizeGB = [math]::Round($folder.Size / 1GB, 2)
        if ($sizeGB -ge 0.05) {
            $roamResults += [PSCustomObject]@{ Name = $dir.Name; SizeGB = $sizeGB; Path = $dir.FullName }
            Write-Host "  $($dir.Name) : $sizeGB GB"
        }
    } catch {}
}
$roamResults = $roamResults | Sort-Object SizeGB -Descending
Write-Host "`nRoaming Total (scanned >50MB): $([math]::Round(($roamResults | Measure-Object -Property SizeGB -Sum).Sum, 2)) GB"

Write-Host "`n========== TOP 15 LOCAL =========="
$localResults | Select-Object -First 15 | ForEach-Object { Write-Host "  $($_.SizeGB) GB  -> $($_.Name)" }

Write-Host "`n========== TOP 15 ROAMING =========="
$roamResults | Select-Object -First 15 | ForEach-Object { Write-Host "  $($_.SizeGB) GB  -> $($_.Name)" }
