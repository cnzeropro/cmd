@echo off
:: 沙盒内全分支覆盖测试套件 v3
:: 模式: 每用例独立 call + 文件重定向输入（字节精确，无尾空格）
:: 单选择后依赖脚本的 EOF 防护退出（pause 与菜单 set /p 在 EOF 立即返回）
setlocal
cd /d C:\test

:: ===== 准备环境：假服务与假目录树 =====
sc create MySQL57 binPath= "C:\Windows\System32\snmptrap.exe" start= demand >nul
sc create Redis binPath= "C:\Windows\System32\snmptrap.exe" start= demand >nul
sc create VisualSVNServer binPath= "C:\Windows\System32\snmptrap.exe" start= demand >nul
sc create OracleServiceXE binPath= "C:\Windows\System32\snmptrap.exe" start= demand >nul
sc create OracleXETNSListener binPath= "C:\Windows\System32\snmptrap.exe" start= demand >nul
mkdir C:\test\env\Git\git-2.40.0\bin 2>nul
mkdir C:\test\env\Git\git-2.41.1\bin 2>nul
mkdir C:\test\env\maven-3.9.6\bin 2>nul
mkdir C:\test\env\oracle-jdk-17.0.10\bin 2>nul
mkdir C:\test\java\jdk-17 2>nul
mkdir C:\test\fake 2>nul
> C:\test\fake\nginx.cmd echo @echo off
>> C:\test\fake\nginx.cmd echo echo fake nginx invoked: %%*

> C:\test\status.txt echo [SETUP] done

goto :tests

:: ===== 断言: call :assert <文件> <期望字符串> <测试名> =====
:assert
findstr /C:"%~2" "%~1" >nul
if not errorlevel 1 (
    >> C:\test\status.txt echo [%~3] PASS
) else (
    >> C:\test\status.txt echo [%~3] FAIL - expected "%~2" not found
)
exit /b

:: ===== 反向断言 =====
:assert_absent
findstr /C:"%~2" "%~1" >nul
if errorlevel 1 (
    >> C:\test\status.txt echo [%~3] PASS
) else (
    >> C:\test\status.txt echo [%~3] FAIL - unexpected "%~2" found
)
exit /b

:tests
:: ============ MySQL57 全分支 ============
echo [M1] start service >> status.txt
call C:\repo\MySQL57.cmd < C:\test\inputs\m1.txt > out_m1.txt 2>&1
echo [M1] exit code: %errorlevel% >> status.txt
call :assert out_m1.txt "MySQL57 started successfully" M1-start
ping -n 4 127.0.0.1 > nul

echo [M2] reboot service >> status.txt
call C:\repo\MySQL57.cmd < C:\test\inputs\m2.txt > out_m2.txt 2>&1
echo [M2] exit code: %errorlevel% >> status.txt
call :assert out_m2.txt "stopped successfully" M2a-stop
call :assert out_m2.txt "started successfully" M2b-start
ping -n 4 127.0.0.1 > nul

echo [M3] duplicate start warning >> status.txt
call C:\repo\MySQL57.cmd < C:\test\inputs\m3.txt > out_m3.txt 2>&1
echo [M3] exit code: %errorlevel% >> status.txt
call :assert out_m3.txt "Warning: MySQL57 started" M3-warning

echo [M4] stop service >> status.txt
call C:\repo\MySQL57.cmd < C:\test\inputs\m4.txt > out_m4.txt 2>&1
echo [M4] exit code: %errorlevel% >> status.txt
call :assert out_m4.txt "MySQL57 stopped successfully" M4-stop
ping -n 3 127.0.0.1 > nul

echo [M5] stop warning when not running >> status.txt
call C:\repo\MySQL57.cmd < C:\test\inputs\m5.txt > out_m5.txt 2>&1
echo [M5] exit code: %errorlevel% >> status.txt
call :assert out_m5.txt "Warning: MySQL57 is not started" M5-warning

echo [M6] invalid menu choice loops back >> status.txt
call C:\repo\MySQL57.cmd < C:\test\inputs\m6.txt > out_m6.txt 2>&1
echo [M6] exit code: %errorlevel% >> status.txt
call :assert out_m6.txt "Warning: Wrong item number" M6-invalid

echo [M7] menu EOF guard exits >> status.txt
call C:\repo\MySQL57.cmd < nul > out_m7.txt 2>&1
echo [M7] exit code: %errorlevel% >> status.txt
call :assert_absent out_m7.txt "Wrong item number" M7-eof

:: ============ MySQL80: 服务不存在 ============
echo [X1] service missing guard >> status.txt
call C:\repo\MySQL80.cmd < nul > out_x1.txt 2>&1
echo [X1] exit code: %errorlevel% >> status.txt
call :assert out_x1.txt "Service does not exist" X1-missing

:: ============ Redis ============
echo [R1] start >> status.txt
call C:\repo\Redis.cmd < C:\test\inputs\r1.txt > out_r1.txt 2>&1
echo [R1] exit code: %errorlevel% >> status.txt
call :assert out_r1.txt "Redis started successfully" R1-start
ping -n 4 127.0.0.1 > nul

echo [R2] stop >> status.txt
call C:\repo\Redis.cmd < C:\test\inputs\r2.txt > out_r2.txt 2>&1
echo [R2] exit code: %errorlevel% >> status.txt
call :assert out_r2.txt "Redis stopped successfully" R2-stop

echo [R3] EOF guard >> status.txt
call C:\repo\Redis.cmd < nul > out_r3.txt 2>&1
echo [R3] exit code: %errorlevel% >> status.txt
call :assert_absent out_r3.txt "Wrong item number" R3-eof

:: ============ SVN ============
echo [V1] start >> status.txt
call C:\repo\SVN.cmd < C:\test\inputs\v1.txt > out_v1.txt 2>&1
echo [V1] exit code: %errorlevel% >> status.txt
call :assert out_v1.txt "VisualSVNServer started successfully" V1-start
ping -n 4 127.0.0.1 > nul

echo [V2] stop >> status.txt
call C:\repo\SVN.cmd < C:\test\inputs\v2.txt > out_v2.txt 2>&1
echo [V2] exit code: %errorlevel% >> status.txt
call :assert out_v2.txt "VisualSVNServer stopped successfully" V2-stop

echo [V3] EOF guard >> status.txt
call C:\repo\SVN.cmd < nul > out_v3.txt 2>&1
echo [V3] exit code: %errorlevel% >> status.txt
call :assert_absent out_v3.txt "Wrong item number" V3-eof

:: ============ Oracle 全分支 ============
echo [O1] stop guard when not running >> status.txt
call C:\repo\Oracle.cmd < C:\test\inputs\o1.txt > out_o1.txt 2>&1
echo [O1] exit code: %errorlevel% >> status.txt
call :assert out_o1.txt "Warning: OracleServiceXE is not started" O1-guard

echo [O2] start flow (oradim expected to fail in sandbox) >> status.txt
call C:\repo\Oracle.cmd < C:\test\inputs\o2.txt > out_o2.txt 2>&1
echo [O2] exit code: %errorlevel% >> status.txt
call :assert out_o2.txt "Oracle started successfully" O2-start
ping -n 4 127.0.0.1 > nul

echo [O3] stop flow when running >> status.txt
call C:\repo\Oracle.cmd < C:\test\inputs\o3.txt > out_o3.txt 2>&1
echo [O3] exit code: %errorlevel% >> status.txt
call :assert out_o3.txt "Oracle stopped successfully" O3-stop

echo [O4] custom SID shown in menu >> status.txt
call C:\repo\Oracle.cmd < C:\test\inputs\o4.txt > out_o4.txt 2>&1
echo [O4] exit code: %errorlevel% >> status.txt
call :assert out_o4.txt "SID: TESTSID" O4-custom-sid

echo [O5] missing service guard >> status.txt
call C:\repo\Oracle.cmd < C:\test\inputs\o5.txt > out_o5.txt 2>&1
echo [O5] exit code: %errorlevel% >> status.txt
call :assert out_o5.txt "Service does not exist" O5-missing

echo [O6] EOF guard >> status.txt
call C:\repo\Oracle.cmd < nul > out_o6.txt 2>&1
echo [O6] exit code: %errorlevel% >> status.txt
call :assert out_o6.txt "Please select the operation" O6-menu
call :assert_absent out_o6.txt "Wrong item number" O6-eof

:: ============ Nginx 全分支 ============
:: EOF 分支在设置 PATH 之前（PATH 含 fake 时 where 成功，不进 EOF 分支）
echo [N7] Reload EOF >> status.txt
call C:\repo\Nginx\Reload.cmd < nul > out_n7.txt 2>&1
echo [N7] exit code: %errorlevel% >> status.txt
call :assert out_n7.txt "no input available" N7-eof

echo [N8] Stop EOF >> status.txt
call C:\repo\Nginx\Stop.cmd < nul > out_n8.txt 2>&1
echo [N8] exit code: %errorlevel% >> status.txt
call :assert out_n8.txt "no input available" N8-eof

echo [N5] custom path input >> status.txt
call C:\repo\Nginx\Reload.cmd < C:\test\inputs\n5.txt > out_n5.txt 2>&1
echo [N5] exit code: %errorlevel% >> status.txt
call :assert out_n5.txt "fake nginx invoked: -s reload" N5-custom-path

echo [N6] invalid path loops then valid >> status.txt
call C:\repo\Nginx\Reload.cmd < C:\test\inputs\n6.txt > out_n6.txt 2>&1
echo [N6] exit code: %errorlevel% >> status.txt
call :assert out_n6.txt "not found" N6a-loop
call :assert out_n6.txt "fake nginx invoked: -s reload" N6b-success

:: 模拟 nginx 已在 PATH
set "PATH=C:\test\fake;%PATH%"

echo [N1] Reload via PATH >> status.txt
call C:\repo\Nginx\Reload.cmd < nul > out_n1.txt 2>&1
echo [N1] exit code: %errorlevel% >> status.txt
call :assert out_n1.txt "fake nginx invoked: -s reload" N1-path

echo [N2] Stop via PATH >> status.txt
call C:\repo\Nginx\Stop.cmd < nul > out_n2.txt 2>&1
echo [N2] exit code: %errorlevel% >> status.txt
call :assert out_n2.txt "fake nginx invoked: -s stop" N2-path

echo [N3] Quit via PATH >> status.txt
call C:\repo\Nginx\Quit.cmd < nul > out_n3.txt 2>&1
echo [N3] exit code: %errorlevel% >> status.txt
call :assert out_n3.txt "fake nginx invoked: -s quit" N3-path

echo [N4] Start via PATH >> status.txt
call C:\repo\Nginx\Start.cmd < nul > out_n4.txt 2>&1
echo [N4] exit code: %errorlevel% >> status.txt
call :assert_absent out_n4.txt "Error" N4-start

:: ============ init_dev_env 全分支 ============
echo [I1] EOF dry-run >> status.txt
call C:\repo\init_dev_env.cmd --dry-run < nul > out_i1.txt 2>&1
echo [I1] exit code: %errorlevel% >> status.txt
call :assert out_i1.txt "Script completed" I1a-complete
call :assert out_i1.txt "No changes to PATH" I1b-no-change

echo [I2] interactive dry-run + latest version pick >> status.txt
call C:\repo\init_dev_env.cmd < C:\test\inputs\i2.txt > out_i2.txt 2>&1
echo [I2] exit code: %errorlevel% >> status.txt
call :assert out_i2.txt "GIT_HOME=C:\test\env\Git\git-2.41.1" I2-latest
call :assert out_i2.txt "Added to PATH" I2-path

echo [I3] single-quote rejection >> status.txt
call C:\repo\init_dev_env.cmd < C:\test\inputs\i3.txt > out_i3.txt 2>&1
echo [I3] exit code: %errorlevel% >> status.txt
call :assert out_i3.txt "must not contain single quotes" I3-reject
call :assert out_i3.txt "GIT_HOME=C:\test\env\Git\git-2.41.1" I3-retry

echo [I4] nonexistent path re-prompt >> status.txt
call C:\repo\init_dev_env.cmd < C:\test\inputs\i4.txt > out_i4.txt 2>&1
echo [I4] exit code: %errorlevel% >> status.txt
call :assert out_i4.txt "Directory not found - C:\nope" I4a-warn
call :assert out_i4.txt "GIT_HOME=C:\test\env\Git\git-2.41.1" I4b-retry

echo [I5] trailing backslash normalized >> status.txt
call C:\repo\init_dev_env.cmd < C:\test\inputs\i5.txt > out_i5.txt 2>&1
echo [I5] exit code: %errorlevel% >> status.txt
call :assert out_i5.txt "GIT_HOME=C:\test\env\Git\git-2.41.1" I5-normalized

echo [I6] apply writes registry >> status.txt
call C:\repo\init_dev_env.cmd < C:\test\inputs\i6.txt > out_i6.txt 2>&1
echo [I6] exit code: %errorlevel% >> status.txt
call :assert out_i6.txt "PATH updated successfully" I6a-path
reg query "HKCU\Environment" /v GIT_HOME > reg_i6.txt 2>&1
call :assert reg_i6.txt "git-2.41.1" I6b-registry

echo [I7] default mode choice applies >> status.txt
call C:\repo\init_dev_env.cmd < C:\test\inputs\i7.txt > out_i7.txt 2>&1
echo [I7] exit code: %errorlevel% >> status.txt
call :assert out_i7.txt "Set environment variable: GIT_HOME=C:\test\env\Git\git-2.41.1" I7-default-apply

echo [I8] quiet mode suppresses logs >> status.txt
call C:\repo\init_dev_env.cmd --dry-run --quiet < nul > out_i8.txt 2>&1
echo [I8] exit code: %errorlevel% >> status.txt
call :assert out_i8.txt "Script completed" I8a-complete
call :assert_absent out_i8.txt "Current user PATH" I8b-quiet

echo [I9] verbose mode shows detail >> status.txt
call C:\repo\init_dev_env.cmd --dry-run --verbose < nul > out_i9.txt 2>&1
echo [I9] exit code: %errorlevel% >> status.txt
call :assert out_i9.txt "Calling add_to_path with parameters" I9-verbose

echo [I10] unknown argument reported >> status.txt
call C:\repo\init_dev_env.cmd --bogus --dry-run < nul > out_i10.txt 2>&1
echo [I10] exit code: %errorlevel% >> status.txt
call :assert out_i10.txt "Unknown argument: --bogus" I10-unknown

echo [I11] apply EOF with default path >> status.txt
call C:\repo\init_dev_env.cmd --apply < nul > out_i11.txt 2>&1
echo [I11] exit code: %errorlevel% >> status.txt
call :assert out_i11.txt "No changes to PATH" I11-no-change

echo [T13] list mode shows resolution details >> status.txt
call C:\repo\init_dev_env.cmd --list < nul > out_i12.txt 2>&1
echo [T13] exit code: %errorlevel% >> status.txt
call :assert out_i12.txt "Processing tool" T13-list-verbose
call :assert out_i12.txt "Script completed" T13-list-complete

echo [T14] restore rollback >> status.txt
call C:\repo\init_dev_env.cmd --restore < nul > out_i13.txt 2>&1
echo [T14] exit code: %errorlevel% >> status.txt
call :assert out_i13.txt "PATH restored from backup" T14-restore-path
reg query "HKCU\Environment" /v GIT_HOME > reg_i13.txt 2>&1
call :assert_absent reg_i13.txt "GIT_HOME" T14-var-removed

:: ============ switch_jdk 全分支 ============
echo [S1] EOF exits without writing >> status.txt
call C:\repo\switch_jdk_version.cmd < nul > out_s1.txt 2>&1
echo [S1] exit code: %errorlevel% >> status.txt
call :assert out_s1.txt "JDK version is required" S1-eof

echo [S2] success + registry write >> status.txt
call C:\repo\switch_jdk_version.cmd < C:\test\inputs\s2.txt > out_s2.txt 2>&1
echo [S2] exit code: %errorlevel% >> status.txt
call :assert out_s2.txt "new environment" S2a-output
reg query "HKCU\Environment" /v JAVA_HOME > reg_s2.txt 2>&1
call :assert reg_s2.txt "jdk-17" S2b-registry

echo [S3] nonexistent base re-prompt >> status.txt
call C:\repo\switch_jdk_version.cmd < C:\test\inputs\s3.txt > out_s3.txt 2>&1
echo [S3] exit code: %errorlevel% >> status.txt
call :assert out_s3.txt "C:\nope" S3a-warn
call :assert out_s3.txt "new environment" S3b-retry

echo [S4] nonexistent version re-prompt >> status.txt
call C:\repo\switch_jdk_version.cmd < C:\test\inputs\s4.txt > out_s4.txt 2>&1
echo [S4] exit code: %errorlevel% >> status.txt
call :assert out_s4.txt "Please try again" S4a-retry
call :assert out_s4.txt "new environment" S4b-success

echo [S5] empty version rejected >> status.txt
call C:\repo\switch_jdk_version.cmd < C:\test\inputs\s5.txt > out_s5.txt 2>&1
echo [S5] exit code: %errorlevel% >> status.txt
call :assert out_s5.txt "JDK version is required" S5-required

echo [S6] q cancels >> status.txt
call C:\repo\switch_jdk_version.cmd < C:\test\inputs\s6.txt > out_s6.txt 2>&1
echo [S6] exit code: %errorlevel% >> status.txt
call :assert out_s6.txt "Cancelled" S6-cancel

echo [S7] trailing backslash appended >> status.txt
call C:\repo\switch_jdk_version.cmd < C:\test\inputs\s7.txt > out_s7.txt 2>&1
echo [S7] exit code: %errorlevel% >> status.txt
call :assert out_s7.txt "new environment" S7-normalized

:: T12: PowerShell 提权路径可用性验证（管理员沙盒中 RunAs 直接成功，无 UAC 弹窗）
echo [T12] PowerShell elevation >> status.txt
powershell -NoProfile -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/c exit' -Verb RunAs -Wait" > C:\test\out_ps.txt 2>&1
if errorlevel 1 (
    >> status.txt echo [T12-elevate] FAIL
    type C:\test\out_ps.txt >> status.txt
) else (
    >> status.txt echo [T12-elevate] PASS
)

echo [DONE] >> status.txt
endlocal
shutdown /s /t 5
