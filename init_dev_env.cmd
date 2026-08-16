@echo off
setlocal enabledelayedexpansion

:: ========== 变量初始化 ==========
set "TOOL_COUNT=0"
set "USER_PATH="
set "NEW_PATH="
set "TEMP_FILE=%TEMP%\add_env_path_%RANDOM%%RANDOM%%TIME:~0,2%%TIME:~3,2%.txt"
set "RESOLVED_FILE=%TEMP%\resolved_paths_%RANDOM%%RANDOM%.txt"
set "PATH_TO_WRITE="
set "PATH_LEN=0"
set "RUN_MODE="
set "MODE_SOURCE=prompt"
set "VERBOSE=0"
set "QUIET=0"
set "BASE_PATH=C:\App\Env"

:: ========== 工具配置 ==========
:: 格式: call :add_tool "目录名" "前缀" "环境变量名" "子路径"
:: 特殊: call :add_tool_extra "额外路径" "额外环境变量名" (紧跟在有额外路径的工具后)
:: 禁用工具: 在行首添加 :: 即可

call :add_tool "Git" "git-" "GIT_HOME" "\bin"
call :add_tool "Maven" "maven-" "MVN_HOME" "\bin"
call :add_tool "mvnd" "mvnd-" "MVND_HOME" "\bin"
call :add_tool "Gradle" "gradle-" "GRADLE_HOME" "\bin"
call :add_tool "Java" "oracle-jdk-" "JAVA_HOME" "\bin"
call :add_tool "NVM" "nvm-" "NVM_HOME" ""
call :add_tool_extra "%BASE_PATH%\NVM\nodejs" "NVM_SYMLINK"
call :add_tool "Go" "go-" "GO_HOME" "\bin"
call :add_tool "PHP" "php-" "PHP_HOME" ""
call :add_tool "ffmpeg" "ffmpeg-" "FFMPEG_HOME" "\bin"
call :add_tool "Tomcat" "tomcat-" "TOMCAT_HOME" "\bin"
:: Node（默认禁用，避免与 NVM 冲突）
:: call :add_tool "Node" "node-v" "NODE_HOME" ""
:: Python（默认禁用，使用系统 Python）
:: call :add_tool "Python" "python-" "PYTHON_HOME" ""
:: PowerShell（默认禁用）
:: call :add_tool "PowerShell" "PowerShell-" "POWERSHELL_HOME" ""

:: ========== 参数解析 ==========
:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="--dry-run" (
    set "RUN_MODE=dry-run"
    set "MODE_SOURCE=arg"
    shift
    goto :parse_args
)
if /i "%~1"=="--apply" (
    set "RUN_MODE=apply"
    set "MODE_SOURCE=arg"
    shift
    goto :parse_args
)
if /i "%~1"=="--quiet" (
    set "QUIET=1"
    set "VERBOSE=0"
    shift
    goto :parse_args
)
if /i "%~1"=="-q" (
    set "QUIET=1"
    set "VERBOSE=0"
    shift
    goto :parse_args
)
if /i "%~1"=="--verbose" (
    set "VERBOSE=1"
    set "QUIET=0"
    shift
    goto :parse_args
)
if /i "%~1"=="-v" (
    set "VERBOSE=1"
    set "QUIET=0"
    shift
    goto :parse_args
)
echo Unknown argument: %~1
shift
goto :parse_args

:args_done
if "!RUN_MODE!"=="" (
    set /p "USER_CHOICE=Select mode: [1] Apply  [2] Dry-run (default 1): "
    if "!USER_CHOICE!"=="2" (
        set "RUN_MODE=dry-run"
    ) else (
        set "RUN_MODE=apply"
    )
    set "MODE_SOURCE=prompt"
)

call :log "Run mode: !RUN_MODE! (source: !MODE_SOURCE!)"

:: ========== 读取当前用户 PATH ==========
for /f "tokens=* delims=" %%I in ('powershell -NoProfile -Command "((Get-Item 'HKCU:\Environment').GetValue('PATH', '', 'DoNotExpandEnvironmentNames'))" 2^>nul') do (
    set "USER_PATH=%%I"
)
if not defined USER_PATH (
    call :log "Warning: Failed to read user PATH from registry or PATH is empty"
) else (
    call :log "Current user PATH: %USER_PATH%"
)
echo "%USER_PATH%">"%TEMP_FILE%"

:: ========== 批量检测所有工具目录 ==========
call :log "Resolving tool directories..."
call :resolve_all_dirs
if not exist "%RESOLVED_FILE%" (
    call :log "Warning: Batch resolution failed, falling back to individual resolution"
    del "%RESOLVED_FILE%" 2>nul
)

:: ========== 处理每个工具 ==========
for /L %%i in (1,1,%TOOL_COUNT%) do (
    set "TOOL_DIR=!TOOL_%%i_DIR!"
    set "TOOL_PREFIX=!TOOL_%%i_PREFIX!"
    set "TOOL_ENV=!TOOL_%%i_ENV!"
    set "TOOL_SUB=!TOOL_%%i_SUB!"
    
    call :log_verbose "Processing tool: !TOOL_DIR! (env: !TOOL_ENV!)"
    
    :: 从批量检测结果读取路径，如果没有则单独检测
    set "RESOLVED_HOME="
    if exist "%RESOLVED_FILE%" (
        for /f "tokens=1,* delims==" %%A in ('findstr /B "TOOL_%%i_PATH=" "%RESOLVED_FILE%" 2^>nul') do (
            set "RESOLVED_HOME=%%B"
        )
    )
    if "!RESOLVED_HOME!"=="" (
        call :resolve_latest_dir "%BASE_PATH%\!TOOL_DIR!" "!TOOL_PREFIX!"
    )
    
    call :add_to_path "!TOOL_ENV!" "!RESOLVED_HOME!" "!TOOL_SUB!"
    
    :: 处理额外路径（如 NVM_SYMLINK）
    set "TOOL_EXTRA=!TOOL_%%i_EXTRA!"
    if "!TOOL_EXTRA!"=="1" (
        set "EXTRA_PATH=!TOOL_%%i_EXTRA_PATH!"
        set "EXTRA_ENV=!TOOL_%%i_EXTRA_ENV!"
        call :log_verbose "Adding extra path: !EXTRA_ENV! = !EXTRA_PATH!"
        call :add_to_path "!EXTRA_ENV!" "!EXTRA_PATH!" ""
    )
)

:: ========== 清理批量检测结果文件 ==========
if exist "%RESOLVED_FILE%" del "%RESOLVED_FILE%" >nul 2>&1

:: ========== 写入 PATH ==========
call :log "Adding user PATH with new PATH: !NEW_PATH!"
if "!NEW_PATH!"=="" (
    call :log "No changes to PATH"
) else (
    if "!USER_PATH!"=="" (
        set "PATH_TO_WRITE=!NEW_PATH!"
    ) else (
        set "PATH_TO_WRITE=!USER_PATH!;!NEW_PATH!"
    )
    for /f %%L in ('powershell -NoProfile -Command "$s=$env:PATH_TO_WRITE; if($null -eq $s){0}else{$s.Length}"') do (
        set "PATH_LEN=%%L"
    )
    call :log "Target PATH length: !PATH_LEN!"
    if /i "!RUN_MODE!"=="dry-run" (
        call :log "[DRY-RUN] Would set PATH to: !PATH_TO_WRITE!"
        if !PATH_LEN! GTR 1024 (
            call :log "[DRY-RUN] PATH is too long for safe setx write."
        )
    ) else (
        if !PATH_LEN! GTR 1024 (
            call :log "PATH is too long for safe setx write. Skip writing PATH."
        ) else (
            setx PATH "!PATH_TO_WRITE!" >nul
            if !errorlevel! neq 0 (
                call :log "Failed to write PATH by setx."
            ) else (
                call :log "PATH updated successfully."
            )
        )
    )
)
goto :end

:: ========== 函数：批量检测所有目录 ==========
:resolve_all_dirs
set "ps_script="
set "ps_script=%ps_script% $basePath='%BASE_PATH%'; $results = @();"
for /L %%i in (1,1,%TOOL_COUNT%) do (
    set "TOOL_DIR=!TOOL_%%i_DIR!"
    set "TOOL_PREFIX=!TOOL_%%i_PREFIX!"
    set "ps_script=!ps_script! $dir='!TOOL_DIR!'; $prefix='!TOOL_PREFIX!'; $idx=%%i;"
    set "ps_script=!ps_script! $searchRoot=Join-Path $basePath $dir;"
    set "ps_script=!ps_script! if(Test-Path $searchRoot){"
    set "ps_script=!ps_script!   $bestPath=''; $bestVer=[version]'0.0.0.0';"
    set "ps_script=!ps_script!   foreach($d in (Get-ChildItem -Path $searchRoot -Directory -ErrorAction SilentlyContinue)){"
    set "ps_script=!ps_script!     if($d.Name.StartsWith($prefix,[System.StringComparison]::OrdinalIgnoreCase)){"
    set "ps_script=!ps_script!       $raw=$d.Name.Substring($prefix.Length);"
    set "ps_script=!ps_script!       $norm=($raw -replace '[^0-9]+','.').Trim('.');"
    set "ps_script=!ps_script!       if([string]::IsNullOrWhiteSpace($norm)){ $norm='0.0.0.0' };"
    set "ps_script=!ps_script!       $parts=$norm.Split('.');"
    set "ps_script=!ps_script!       if($parts.Count -lt 4){ $parts += @('0','0','0','1') };"
    set "ps_script=!ps_script!       if($parts.Count -gt 4){ $parts=$parts[0..3] };"
    set "ps_script=!ps_script!       try{ $v=[version]::new([int]$parts[0],[int]$parts[1],[int]$parts[2],[int]$parts[3]);"
    set "ps_script=!ps_script!         if($v -ge $bestVer){ $bestVer=$v; $bestPath=$d.FullName }"
    set "ps_script=!ps_script!       }catch{}"
    set "ps_script=!ps_script!     }"
    set "ps_script=!ps_script!   };"
    set "ps_script=!ps_script!   if($bestPath){ $results += \"TOOL_${idx}_PATH=$bestPath\" }"
    set "ps_script=!ps_script! };"
)
set "ps_script=!ps_script! $results -join \"`n\""

powershell -NoProfile -Command "!ps_script!" > "%RESOLVED_FILE%" 2>nul
if !errorlevel! neq 0 (
    del "%RESOLVED_FILE%" 2>nul
    exit /b 1
)
exit /b 0

:: ========== 函数：单独检测最大版本目录（fallback） ==========
:resolve_latest_dir
set "search_root=%~1"
set "name_prefix=%~2"
set "RESOLVED_HOME="
if not exist "%search_root%" (
    call :log "Directory not found: %search_root%"
    exit /b
)
for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command "$root='%search_root%'; $prefix='%name_prefix%'; $bestPath=''; $bestVer=[version]'0.0.0.0'; foreach($d in (Get-ChildItem -Path $root -Directory)){ if($d.Name.StartsWith($prefix,[System.StringComparison]::OrdinalIgnoreCase)){ $raw=$d.Name.Substring($prefix.Length); $norm=($raw -replace '[^0-9]+','.').Trim('.'); if([string]::IsNullOrWhiteSpace($norm)){ $norm='0.0.0.0' }; $parts=$norm.Split('.'); if($parts.Count -lt 4){ $parts += @('0','0','0','0') }; if($parts.Count -gt 4){ $parts=$parts[0..3] }; $v=[version]::new([int]$parts[0],[int]$parts[1],[int]$parts[2],[int]$parts[3]); if($v -ge $bestVer){ $bestVer=$v; $bestPath=$d.FullName } } }; if($bestPath){ $bestPath }"`) do (
    set "RESOLVED_HOME=%%~fI"
)
if "!RESOLVED_HOME!"=="" (
    call :log "No matched directory: %search_root%\%name_prefix%*"
) else (
    call :log "Resolved latest: !RESOLVED_HOME!"
)
exit /b

:: ========== 函数：添加到 PATH ==========
:add_to_path
call :log_verbose "Calling add_to_path with parameters: env_name=%~1, env_home=%~2, env_sub_path=%~3"
set "env_name=%~1"
set "env_home=%~2"
set "env_sub_path=%~3"
if "!env_home!"=="" (
    call :log_verbose "Skipped empty env_home"
    call :log_verbose ""
    exit /b
)
if not exist "!env_home!" (
    call :log "Directory not found for env_home: !env_home!"
    call :log_verbose ""
    exit /b
)
if "%env_name%"=="" (
    set "env_path=%env_home%%env_sub_path%"
) else (
    set "env_path=%%%env_name%%%%env_sub_path%"
    if /i "!RUN_MODE!"=="dry-run" (
        call :log "[DRY-RUN] Would set environment variable: %env_name%=%env_home%"
    ) else (
        setx %env_name% "%env_home%" >nul
        call :log "Set environment variable: %env_name%=%env_home%"
    )
)
if "!env_path!"=="" (
    call :log_verbose "Skipped empty path"
    call :log_verbose ""
    exit /b
)
call :log_verbose "Checking if !env_path! exists in PATH..."
findstr /L /C:"!env_path!" "%TEMP_FILE%" >nul
if !errorlevel! neq 0 (
    if "!NEW_PATH!"=="" (
        set "NEW_PATH=!env_path!"
    ) else (
        set "NEW_PATH=!NEW_PATH!;!env_path!"
    )
    call :log "Added to PATH: !env_path!"
) else (
    call :log "Already exists in PATH: !env_path!"
)
call :log_verbose ""
exit /b

:: ========== 函数：添加工具配置 ==========
:add_tool
set /a "TOOL_COUNT+=1"
set "TOOL_%TOOL_COUNT%_DIR=%~1"
set "TOOL_%TOOL_COUNT%_PREFIX=%~2"
set "TOOL_%TOOL_COUNT%_ENV=%~3"
set "TOOL_%TOOL_COUNT%_SUB=%~4"
set "TOOL_%TOOL_COUNT%_EXTRA=0"
exit /b

:add_tool_extra
set /a "last=%TOOL_COUNT%"
set "TOOL_%last%_EXTRA=1"
set "TOOL_%last%_EXTRA_PATH=%~1"
set "TOOL_%last%_EXTRA_ENV=%~2"
exit /b

:: ========== 函数：输出控制 ==========
:log
if "%QUIET%"=="1" exit /b
echo %~1
exit /b

:log_verbose
if "%VERBOSE%"=="0" exit /b
if "%~1"=="" exit /b
echo %~1
exit /b

:: ========== 结束 ==========
:end
if exist "%TEMP_FILE%" del "%TEMP_FILE%" >nul 2>&1
echo Script completed
endlocal
pause
