@echo off
title Windows Update - 恢复更新
color 0E

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
echo   Windows Update - Full Restore
echo ========================================
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0恢复更新.ps1"

echo.
echo ========================================
echo   Press any key to exit...
pause >nul