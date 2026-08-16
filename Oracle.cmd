cls
@echo off
color 0a
title Oracle Manager by Zero

@echo off
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%ERRORLEVEL%' NEQ '0' (
    goto getAdmin
) else (
    goto getStart
)

:getAdmin
echo Set UAC = CreateObject^("Shell.Application"^) > "%TEMP%\getadmin.vbs"
echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%TEMP%\getadmin.vbs"
"%TEMP%\getadmin.vbs"
exit /B

:getStart
if exist "%TEMP%\getadmin.vbs" ( del "%TEMP%\getadmin.vbs" )
@echo off
for /f "skip=3 tokens=4" %%i in ('sc query OracleServiceXE') do set "state=%%i" & goto next

:next
if /i "%state%"=="RUNNING" (
    echo service has been found running
    echo now stopping the service...
    net stop OracleXETNSListener
    net stop OracleServiceXE
) else if /i "%state%"=="STOPPED" (
    echo service has been detected to be stopped
    echo now starting the service...
    net start OracleXETNSListener
    net start OracleServiceXE
    @oradim -startup -sid XE -starttype inst
) else (
    echo The service was not found
)
pause
exit
