@echo off
:: Windows Sandbox 实测启动器（一键运行）
:: 自动从模板生成 wsb 配置、启动沙盒、等待测试完成并显示结果。
:: 项目目录只读挂载、沙盒无网络，测试不会影响本机。
setlocal enabledelayedexpansion

:: 定位仓库根目录（本脚本位于 <仓库>\.scripts\sandbox\）
for %%I in ("%~dp0..\..") do set "REPO_ROOT=%%~fI"
set "SELF_DIR=%~dp0"
set "OUT_DIR=%TEMP%\sandbox_test"

if not exist "%SystemRoot%\System32\WindowsSandbox.exe" (
    echo Error: Windows Sandbox is not installed.
    echo Enable the "Containers-DisposableClientVM" Windows feature and reboot first.
    pause
    exit /b 1
)

if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
del "%OUT_DIR%\status.txt" "%OUT_DIR%\out1.txt" "%OUT_DIR%\out2.txt" "%OUT_DIR%\out3.txt" 2>nul

:: 同步最新测试脚本到输出目录（沙盒从该目录执行 run_tests.cmd）
copy /Y "%SELF_DIR%run_tests.cmd" "%OUT_DIR%un_tests.cmd" >nul

:: 从模板生成 wsb（替换仓库路径与输出目录占位符）
set "WSB=%OUT_DIR%\sandbox_test.wsb"
powershell -NoProfile -Command "$t = Get-Content -Raw -LiteralPath '%SELF_DIR%sandbox_test.wsb.template'; $t = $t.Replace('__REPO_ROOT__', '%REPO_ROOT%').Replace('__OUT_DIR__', '%OUT_DIR%'); [IO.File]::WriteAllText('%WSB%', $t)"

echo Launching Windows Sandbox for testing...
echo The sandbox window will close automatically when tests finish.
start "" "%SystemRoot%\System32\WindowsSandbox.exe" "%WSB%"

:: 等待测试完成（约 10 分钟超时，详细套件含多次 PowerShell 调用）
set /a "n=0"
:wait
ping -n 6 127.0.0.1 > nul
set /a "n+=1"
if exist "%OUT_DIR%\status.txt" goto :show
if %n% GEQ 120 (
    echo Error: Timeout waiting for sandbox test results.
    goto :end
)
goto :wait

:show
echo.
echo ============ Sandbox Test Results ============
type "%OUT_DIR%\status.txt"
echo =============================================
echo.
echo Detailed outputs:
for %%F in (out1 out2 out3 out4a out4b out5 out6 out7 out8 out9 out10 reg8 reg10) do (
    if exist "%OUT_DIR%\%%F.txt" (
        echo --- %%F.txt ^(last 5 lines^) ---
        powershell -NoProfile -Command "Get-Content -LiteralPath '%OUT_DIR%\%%F.txt' -Tail 5"
    )
)
echo.

:end
pause
endlocal
