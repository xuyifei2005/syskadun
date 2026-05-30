@echo off
title Windows Update - 禁用更新
color 0A

:: ========================================
:: Auto Request Administrator Privileges
:: ========================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Requesting Administrator privileges...
    powershell -Command "Start-Process -FilePath '%0' -Verb RunAs"
    exit /b
)

echo ========================================
echo   Windows Update - Force Disable
echo ========================================
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0force_disable_all.ps1"

echo.
echo ========================================
echo   Press any key to exit...
pause >nul