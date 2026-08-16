@echo off
:: 启动 Nginx（新窗口运行）
set "nginxCmd=nginx"

:: 检测 nginx 是否在 PATH，不在则提示输入完整路径
:locate_nginx
where "%nginxCmd%" >nul 2>&1
if not errorlevel 1 goto do_exec
set /p "nginxCmd=nginx not found in PATH. Enter full path to nginx.exe: "
:: 非交互运行（stdin 已关闭）时 set /p 返回 errorlevel 1，直接报错退出避免死循环
if errorlevel 1 (
    echo Error: nginx.exe not found in PATH and no input available.
    exit /b 1
)
if "%nginxCmd%"=="" (
    echo Error: nginx.exe path is required.
    goto locate_nginx
)
if not exist "%nginxCmd%" (
    echo Error: "%nginxCmd%" not found.
    goto locate_nginx
)

:do_exec
start "" "%nginxCmd%"
pause
