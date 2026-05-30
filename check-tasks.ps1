Get-ScheduledTask -TaskPath '\Microsoft\Windows\UpdateOrchestrator\' -ErrorAction SilentlyContinue | Select-Object TaskName, State | Format-Table -AutoSize
Write-Host ''
Write-Host '--- Also checking WindowsUpdate tasks ---' -ForegroundColor Yellow
Get-ScheduledTask -TaskPath '\Microsoft\Windows\WindowsUpdate\' -ErrorAction SilentlyContinue | Select-Object TaskName, State | Format-Table -AutoSize
Write-Host ''
Write-Host '--- Checking all UpdateOrchestrator subfolders ---' -ForegroundColor Yellow
Get-ScheduledTask -TaskPath '\Microsoft\Windows\UpdateOrchestrator\*' -ErrorAction SilentlyContinue | Select-Object TaskName, State, TaskPath | Format-Table -AutoSize