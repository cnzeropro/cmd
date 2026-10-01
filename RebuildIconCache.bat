@echo off
setlocal
title Rebuild Icon Cache

echo ==========================================
echo   Rebuild Windows Icon Cache
echo ==========================================
echo.

echo [1/4] Stopping Explorer...
taskkill /f /im explorer.exe >nul 2>&1

echo [2/4] Deleting icon cache files...
del /a /f /q "%LOCALAPPDATA%\IconCache.db" >nul 2>&1
del /a /f /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache*.db" >nul 2>&1

echo [3/4] Restarting Explorer...
start explorer.exe

echo [4/4] Refreshing icon cache...
timeout /t 1 /nobreak >nul
ie4uinit.exe -show >nul 2>&1

echo.
echo Done.
echo If some icons are still missing, press F5 on the desktop.
echo.
pause
endlocal