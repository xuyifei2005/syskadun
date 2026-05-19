@echo off
pushd "%~dp0"
echo ========================================
echo Windows 10/11 Home GPEDIT Installer
echo ========================================
echo.
echo Searching for Group Policy packages...
dir /b %SystemRoot%\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientExtensions-Package~3*.mum >List.txt
dir /b %SystemRoot%\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientTools-Package~3*.mum >>List.txt
echo.
echo Installing Group Policy components...
echo This may take 3-5 minutes, please wait...
echo.
for /f %%i in ('findstr /i . List.txt 2^>nul') do (
    echo Installing: %%i
    dism /online /norestart /add-package:"%SystemRoot%\servicing\Packages\%%i"
)
echo.
echo ========================================
echo GPEDIT installation completed!
echo Please RESTART your computer
echo Then run gpedit.msc to verify
echo ========================================
echo.
pause
