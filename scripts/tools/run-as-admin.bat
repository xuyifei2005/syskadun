@echo off
echo ========================================
echo Starting GPEDIT Installation...
echo ========================================
echo.
echo This will request administrator privileges.
echo Please click "Yes" when prompted.
echo.
echo Installing Group Policy Editor for Windows Home Edition...
echo.

powershell -ExecutionPolicy Bypass -Command "Start-Process PowerShell -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0install-gpedit.ps1\"' -Verb RunAs"

echo.
echo Installation script started!
echo Please check the new PowerShell window for progress.
echo.
pause
