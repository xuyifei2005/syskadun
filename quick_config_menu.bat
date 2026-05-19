@echo off
chcp 65001 >nul
color 0A
title System Optimization - Quick Menu

echo ================================================
echo   System Optimization - Quick Menu
echo   Created: 2026-03-20
echo ================================================
echo.

:MENU
echo Select operation:
echo.
echo [1] Run C: Drive Monitor (check status)
echo [2] Run Cleanup Script (clean cache)
echo [3] Run System Optimization (all-in-one)
echo [4] Open Configuration Guide
echo [5] Open Configuration Checklist
echo [6] Open Summary Report
echo [7] Open Docker Migration Guide
echo [8] Open Pagefile Configuration
echo [9] Open ComfyUI Migration Guide
echo [A] Open System Experience Optimization Guide
echo [B] Run Advanced Optimization (performance tuning)
echo [C] Open Advanced Optimization Guide
echo [D] Fix VMware Performance (resolve lag)
echo [0] Exit
echo.
set /p choice=Enter choice (0-9, A-D): 

if "%choice%"=="1" goto MONITOR
if "%choice%"=="2" goto CLEANUP
if "%choice%"=="3" goto OPTIMIZE
if "%choice%"=="4" goto GUIDE
if "%choice%"=="5" goto CHECKLIST
if "%choice%"=="6" goto SUMMARY
if "%choice%"=="7" goto DOCKER
if "%choice%"=="8" goto PAGEFILE
if "%choice%"=="9" goto COMFYUI
if /i "%choice%"=="A" goto EXPERIENCE
if /i "%choice%"=="B" goto ADVANCED_OPT
if /i "%choice%"=="C" goto ADVANCED_GUIDE
if /i "%choice%"=="D" goto VMWARE_FIX
if "%choice%"=="0" goto END
goto MENU

:MONITOR
echo.
echo Running C: Drive Monitor...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0monitor_c_drive.ps1"
echo.
pause
goto MENU

:CLEANUP
echo.
echo WARNING: This will clean system cache and temp files!
echo Confirm to continue?
set /p confirm=Enter Y to confirm: 
if /i "%confirm%"=="Y" (
    echo.
    echo Running cleanup script...
    echo.
    powershell -ExecutionPolicy Bypass -File "%~dp0scheduled_cleanup.ps1"
    echo.
) else (
    echo.
    echo Cleanup cancelled
    echo.
)
pause
goto MENU

:OPTIMIZE
echo.
echo WARNING: This will optimize system performance!
echo Confirm to continue?
set /p confirm=Enter Y to confirm: 
if /i "%confirm%"=="Y" (
    echo.
    echo Running system optimization...
    echo.
    powershell -ExecutionPolicy Bypass -File "%~dp0optimize_system.ps1"
    echo.
) else (
    echo.
    echo Optimization cancelled
    echo.
)
pause
goto MENU

:GUIDE
echo.
echo Opening Configuration Guide...
start "" "%~dp0prevent_c_drive_fill_guide.md"
echo Opened: prevent_c_drive_fill_guide.md
echo.
pause
goto MENU

:CHECKLIST
echo.
echo Opening Configuration Checklist...
start "" "%~dp0configuration_checklist.md"
echo Opened: configuration_checklist.md
echo.
pause
goto MENU

:SUMMARY
echo.
echo Opening Summary Report...
start "" "%~dp0PREVENTIVE_OPTIMIZATION_SUMMARY.md"
echo Opened: PREVENTIVE_OPTIMIZATION_SUMMARY.md
echo.
pause
goto MENU

:DOCKER
echo.
echo Opening Docker Migration Guide...
start "" "%~dp0docker_migration_guide.md"
echo Opened: docker_migration_guide.md
echo.
pause
goto MENU

:PAGEFILE
echo.
echo Opening Pagefile Configuration...
start "" "%~dp0pagefile_instructions.ps1"
echo Opened: pagefile_instructions.ps1
echo.
pause
goto MENU

:COMFYUI
echo.
echo Opening ComfyUI Migration Guide...
start "" "%~dp0comfyui_migration_guide.md"
echo Opened: comfyui_migration_guide.md
echo.
pause
goto MENU

:EXPERIENCE
echo.
echo Opening System Experience Optimization Guide...
start "" "%~dp0SYSTEM_EXPERIENCE_OPTIMIZATION.md"
echo Opened: SYSTEM_EXPERIENCE_OPTIMIZATION.md
echo.
pause
goto MENU

:ADVANCED_OPT
echo.
echo WARNING: This will apply advanced performance optimizations!
echo This includes CPU, memory, network, and SSD optimizations.
echo Confirm to continue?
set /p confirm=Enter Y to confirm: 
if /i "%confirm%"=="Y" (
    echo.
    echo Running advanced optimization...
    echo.
    powershell -ExecutionPolicy Bypass -File "%~dp0advanced_optimization.ps1"
    echo.
) else (
    echo.
    echo Advanced optimization cancelled
    echo.
)
pause
goto MENU

:ADVANCED_GUIDE
echo.
echo Opening Advanced Optimization Guide...
start "" "%~dp0ADVANCED_SYSTEM_OPTIMIZATION.md"
echo Opened: ADVANCED_SYSTEM_OPTIMIZATION.md
echo.
pause
goto MENU

:VMWARE_FIX
echo.
echo WARNING: This will fix VMware performance issues!
echo This will adjust WSL2 configuration to resolve conflicts with VMware.
echo Confirm to continue?
set /p confirm=Enter Y to confirm: 
if /i "%confirm%"=="Y" (
    echo.
    echo Running VMware performance fix...
    echo.
    powershell -ExecutionPolicy Bypass -File "%~dp0fix_vmware_performance.ps1"
    echo.
) else (
    echo.
    echo VMware fix cancelled
    echo.
)
pause
goto MENU

:END
echo.
echo Thank you, goodbye!
echo.
timeout /t 2 >nul
exit
