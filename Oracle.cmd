cls
@echo off
color 0a
title Oracle Manager by Zero

:: 执行需要管理员权限的命令（有权限返回0，无权限返回5）
>nul 2>&1 "%SYSTEMROOT%\system32\icacls.exe" "%SYSTEMROOT%\system32\config\system"
if "%ERRORLEVEL%" NEQ "0" (
    goto getAdmin
) else (
    goto getStart
)

:: 无权限尝试获取权限
:getAdmin
:: 使用 PowerShell 请求提权（VBScript 在新版 Windows 11 已弃用，可能无脚本引擎）
powershell -NoProfile -Command "Start-Process -FilePath '%~s0' -Verb RunAs"
exit /B

:: 有权限继续执行
:getStart

:: 服务名与 SID 配置（默认 XE 版），回车使用默认值
:: 在提权之后询问，避免提权重启后重复输入
set "serviceName=OracleServiceXE"
set "listenerName=OracleXETNSListener"
set "oracleSid=XE"
set /p "serviceName=Enter Oracle service name [default: %serviceName%]: "
set /p "listenerName=Enter Oracle listener service name [default: %listenerName%]: "
set /p "oracleSid=Enter Oracle SID [default: %oracleSid%]: "

goto checkService

:: 菜单
:menu
cls
echo.
echo.=-=-=-=- Please select the operation you want to perform on Oracle (SID: %oracleSid%) -=-=-=-=-
echo.
echo.1: Startup Oracle
echo.
echo.2: Shutdown Oracle
echo.
echo.3: Reboot Oracle
echo.
echo.4: Exit
echo.
echo.=-=-=-=- Please enter the item number you want to select -=-=-=-
set /p id=
:: 非交互运行（stdin 已关闭）时直接退出，避免菜单死循环
if errorlevel 1 exit /b
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
    exit /b 0
) else (
    echo Warning: Wrong item number!
    :: 暂停3秒
    ping -n 3 127.0.0.1 > nul
    goto menu
)

:: 启动（XE 版需 oradim 显式启动数据库实例）
:startup
echo.
call :checkState 1
echo.Startup Oracle services...
net start %listenerName%
net start %serviceName%
if errorlevel 1 (
    echo ERROR: Failed to start Oracle services.
    exit /B 1
)
oradim -startup -sid %oracleSid% -starttype inst
echo.Oracle started successfully!
exit /B

:: 停止
:shutdown
echo.
call :checkState 2
echo.Shutdown Oracle services...
net stop %listenerName%
net stop %serviceName%
if errorlevel 1 (
    echo ERROR: Failed to stop Oracle services.
    exit /B 1
)
echo.Oracle stopped successfully!
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
    exit /b 1
)

:: 检查服务运行状态（参数: 1=启动前检查 2=停止前检查）
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
