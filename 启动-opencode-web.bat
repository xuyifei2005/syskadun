@echo off
chcp 65001 >nul
echo ========================================
echo   启动 opencode Web 界面
echo ========================================
echo.
echo 正在启动 opencode web 服务器...
echo Web 界面地址: http://127.0.0.1:4096/
echo.
echo 请在浏览器中打开上面的地址
echo 按 Ctrl+C 可以停止服务器
echo ========================================
echo.
opencode web
