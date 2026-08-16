@ECHO off
:: 设置服务名
set "serviceName=Redis"
:: 设置窗口字体颜色
color 0a
:: 设置窗口标题
title %serviceName% Manager by Zero
cls

:: 执行需要管理员权限的命令（有权限返回0，无权限返回5）
>nul 2>&1 "%SYSTEMROOT%\system32\icacls.exe" "%SYSTEMROOT%\system32\config\system"
if "%ERRORLEVEL%" NEQ "0" (
    goto getAdmin
) else (
    goto getStart
)

:: 无权限尝试获取权限
:getAdmin
:: 创建提权VBS脚本并运行（文件名带随机数，避免并发冲突）
set "VBS=%TEMP%\getadmin_%RANDOM%.vbs"
echo Set UAC = CreateObject^("Shell.Application"^) > "%VBS%"
echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%VBS%"
"%VBS%"
exit /B

:: 有权限继续执行
:getStart
if exist "%VBS%" ( del "%VBS%" )
goto checkService

:: 菜单
:menu
cls
echo.
echo.=-=-=-=- Please select the operation you want to perform on %serviceName% -=-=-=-=-
echo.
echo.1: Startup %serviceName%
echo.
echo.2: Shutdown %serviceName%
echo.
echo.3: Reboot %serviceName%
echo.
echo.4: Exit
echo.
echo.=-=-=-=- Please enter the item number you want to select -=-=-=-
set /p id=
if "%id%"=="1" (
    call :startup
    goto quit
) else if "%id%"=="2" (
    call :shutdown
    goto quit
) else if "%id%"=="3" (
    call :reboot
    goto quit
) else if "%id%"=="4" (
    exit
) else (
    echo Warning: Wrong item number!
    :: 暂停3秒
    ping -n 3 127.0.0.1 > nul
    goto menu
)

:: 启动
:startup
echo.
call :checkState 1
echo.Startup %serviceName%...
net start %serviceName%
echo.%serviceName% started successfully!
exit /B

:: 停止
:shutdown
echo.
call :checkState 2
echo.Shutdown %serviceName%...
net stop %serviceName%
echo.%serviceName% stopped successfully!
exit /B

:: 重启
:reboot
call :shutdown
ping -n 5 127.0.0.1 > nul
call :startup
exit /B

:: 退出到菜单
:quit
pause
goto menu

:: 检查服务是否存在
:checkService
sc query %serviceName% > nul
if not ERRORLEVEL 1 (
    goto menu
) else (
    echo ERROR: %serviceName% Service does not exist!
    pause
    exit
)

:: 检查服务运行状态（参数: 1=启动前检查 2=停止前检查）
:: 使用 sc query 而非 tasklist，避免进程名子串误匹配
:: （例如 mysqld 会同时匹配 MySQL57 与 MySQL80 的进程）
:checkState
sc query %serviceName% | find /i "RUNNING" > nul
if "%1"=="1" (
    if not errorlevel 1 (
        echo Warning: %serviceName% started
        goto quit
    )
)
if "%1"=="2" (
    if errorlevel 1 (
        echo Warning: %serviceName% is not started
        goto quit
    )
)
exit /B
