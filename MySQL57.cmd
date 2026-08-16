@ECHO off
:: 设置服务名
set "serviceName=MySQL57"
:: 设置进程名
set "processName=mysqld"
:: 设置窗口字体颜色
color 0a 
:: 设置窗口标题
title %serviceName% Manager by Zero
cls

@ECHO off
@REM 执行需要管理员权限的命令
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
@REM 有权限执行会返回0，没有权限返回5
if '%ERRORLEVEL%' NEQ '0' (
    goto getAdmin
) else (
    goto getStart
)

:: 无权限尝试获取权限
:getAdmin
@REM 创建提权VBS脚本并运行
echo Set UAC = CreateObject^("Shell.Application"^) > "%TEMP%\getadmin.vbs"
echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%TEMP%\getadmin.vbs"
"%TEMP%\getadmin.vbs"
exit /B

:: 有权限继续执行
:getStart
if exist "%TEMP%\getadmin.vbs" ( del "%TEMP%\getadmin.vbs" )
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
    @REM 暂停3秒
    ping -n 3 127.0.0.1 > nul
    goto menu
)

:: 启动
:startup
echo.
call :checkProcess 1
echo.Startup %serviceName%...
net start %serviceName%
echo.%serviceName% started successfully!
exit /B
 
:: 停止
:shutdown
echo.
call :checkProcess 2
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

:: 检查进程是否存在
:checkProcess
set /a flag=0
for /f "tokens=1 delims= " %%i in ('tasklist /nh ^| find /i "%processName%"') do (set /a flag+=1)
if %flag% neq 0 if "%1" equ "1" (
  echo Warning: %serviceName% started
  goto quit
)
if %flag% equ 0 if "%1" equ "2" (
  echo Warning: %serviceName% is not started
  goto quit
)
