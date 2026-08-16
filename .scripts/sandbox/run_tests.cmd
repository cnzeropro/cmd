@echo off
:: 沙盒内自动化测试：全部使用非交互模式（< nul），验证脚本不会卡死且行为正确
cd /d C:\test

echo [Test1] init_dev_env.cmd --dry-run (non-interactive) > C:\test\status.txt
call C:\repo\init_dev_env.cmd --dry-run < nul > C:\test\out1.txt 2>&1
echo [Test1] exit code: %errorlevel% >> C:\test\status.txt

echo [Test2] Nginx Reload - nginx not in PATH, EOF branch >> C:\test\status.txt
call C:\repo\Nginx\Reload.cmd < nul > C:\test\out2.txt 2>&1
echo [Test2] exit code: %errorlevel% >> C:\test\status.txt

echo [Test3] switch_jdk_version.cmd - EOF branch (must exit, not loop) >> C:\test\status.txt
call C:\repo\switch_jdk_version.cmd < nul > C:\test\out3.txt 2>&1
echo [Test3] exit code: %errorlevel% >> C:\test\status.txt

echo [DONE] >> C:\test\status.txt
shutdown /s /t 5
