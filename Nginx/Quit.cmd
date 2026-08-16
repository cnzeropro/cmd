@echo off
:: 优雅停止 Nginx
set "nginxCmd=nginx"

:: 检测 nginx 是否在 PATH，不在则提示输入完整路径
:locate_nginx
where "%nginxCmd%" >nul 2>&1
if not errorlevel 1 goto do_exec
set /p "nginxCmd=nginx not found in PATH. Enter full path to nginx.exe: "
if "%nginxCmd%"=="" (
    echo Error: nginx.exe path is required.
    goto locate_nginx
)
if not exist "%nginxCmd%" (
    echo Error: "%nginxCmd%" not found.
    goto locate_nginx
)

:do_exec
"%nginxCmd%" -s quit
pause
