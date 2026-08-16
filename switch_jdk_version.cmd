@echo off

@echo === current environment:
@echo %JAVA_HOME%
@echo.

set "java_home_base=C:\App\Env\Java\"

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
