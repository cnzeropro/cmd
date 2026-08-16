@echo off

@echo === current environment:
@echo %JAVA_HOME%
@echo.

set "java_home_base=C:\App\Env\Java\"

:: ========== 提示确认 JDK 根目录 ==========
:: 回车使用默认值；输入不存在的路径时重新询问
:input_base
set "java_home_base=C:\App\Env\Java\"
set /p "java_home_base=Enter JDK home base [default: C:\App\Env\Java\]: "
:: 确保路径以反斜杠结尾，便于后续拼接
if not "%java_home_base:~-1%"=="\" set "java_home_base=%java_home_base%\"
if not exist "%java_home_base%" (
    @echo Warning: Directory not found - "%java_home_base%"
    goto input_base
)

:select_version
@echo -=-=-=- Please enter the jdk version (q to quit) -=-=-=-
dir "%java_home_base%" /AD /B
set /p "version=version: "

if /i "%version%"=="q" (
    @echo Cancelled.
    pause
    exit /b 0
)

if exist "%java_home_base%%version%" (
    setx JAVA_HOME "%java_home_base%%version%"
    @echo.
    @echo === new environment:
    @echo %java_home_base%%version%
    @echo [Note: Restart terminal for changes to take effect]
) else (
    @echo.
    @echo Error: Directory not found - "%java_home_base%%version%"
    @echo Please try again.
    @echo.
    goto select_version
)

pause
