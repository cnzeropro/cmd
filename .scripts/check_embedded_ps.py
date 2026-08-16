# -*- coding: utf-8 -*-
"""重建 init_dev_env.cmd 中动态拼接的 PowerShell 代码，做纯语法解析（不执行）
模拟 :resolve_all_dirs 的拼接逻辑 + 转录 :resolve_latest_dir 的内嵌 PS，
交给 PowerShell Parser::ParseInput 校验语法。
"""
import re
import sys
import os
import base64
import subprocess

# 强制 UTF-8 输出，避免 Windows CI 默认代码页（cp1252）无法编码中文而崩溃
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

# 基于脚本自身位置定位仓库根目录下的 init_dev_env.cmd
SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'init_dev_env.cmd')

# 1) 提取 add_tool 配置
tools = []
add_tool_re = re.compile(r'^call :add_tool "([^"]*)" "([^"]*)" "([^"]*)" "([^"]*)"')
with open(SRC, encoding='utf-8') as f:
    for l in f:
        m = add_tool_re.match(l.rstrip('\r\n').strip())
        if m:
            tools.append(m.groups())
print(f'Extracted {len(tools)} tool configs')

# 2) 模拟 :resolve_all_dirs 拼接（BASE_PATH 用默认值）
BASE = 'C:\\App\\Env'
ps = [f" $basePath='{BASE}'; $results = @();"]
for idx, (d, p, e, s) in enumerate(tools, 1):
    ps.append(f" $dir='{d}'; $prefix='{p}'; $idx={idx};")
    ps.append(" $searchRoot=Join-Path $basePath $dir;")
    ps.append(" if(Test-Path $searchRoot){")
    ps.append("   $bestPath=''; $bestVer=[version]'0.0.0.0';")
    ps.append("   foreach($d in (Get-ChildItem -Path $searchRoot -Directory -ErrorAction SilentlyContinue)){")
    ps.append("     if($d.Name.StartsWith($prefix,[System.StringComparison]::OrdinalIgnoreCase)){")
    ps.append("       $raw=$d.Name.Substring($prefix.Length);")
    ps.append("       $norm=($raw -replace '[^0-9]+','.').Trim('.');")
    ps.append("       if([string]::IsNullOrWhiteSpace($norm)){ $norm='0.0.0.0' };")
    ps.append("       $parts=$norm.Split('.');")
    ps.append("       if($parts.Count -lt 4){ $parts += @('0','0','0','1') };")
    ps.append("       if($parts.Count -gt 4){ $parts=$parts[0..3] };")
    ps.append("       try{ $v=[version]::new([int]$parts[0],[int]$parts[1],[int]$parts[2],[int]$parts[3]);")
    ps.append("         if($v -ge $bestVer){ $bestVer=$v; $bestPath=$d.FullName }")
    ps.append("       }catch{}")
    ps.append("     }")
    ps.append("   };")
    ps.append(f'   if($bestPath){{ $results += "TOOL_{idx}_PATH=$bestPath" }}')
    ps.append(" };")
ps.append(' $results -join "`n"')
code1 = ' '.join(ps)

# 3) 转录 :resolve_latest_dir 的内嵌 PS
code2 = (
    "$root='C:\\App\\Env\\Git'; $prefix='git-'; $bestPath=''; "
    "$bestVer=[version]'0.0.0.0'; "
    "foreach($d in (Get-ChildItem -Path $root -Directory)){ "
    "if($d.Name.StartsWith($prefix,[System.StringComparison]::OrdinalIgnoreCase)){ "
    "$raw=$d.Name.Substring($prefix.Length); "
    "$norm=($raw -replace '[^0-9]+','.').Trim('.'); "
    "if([string]::IsNullOrWhiteSpace($norm)){ $norm='0.0.0.0' }; "
    "$parts=$norm.Split('.'); "
    "if($parts.Count -lt 4){ $parts += @('0','0','0','0') }; "
    "if($parts.Count -gt 4){ $parts=$parts[0..3] }; "
    "$v=[version]::new([int]$parts[0],[int]$parts[1],[int]$parts[2],[int]$parts[3]); "
    "if($v -ge $bestVer){ $bestVer=$v; $bestPath=$d.FullName } } }; "
    "if($bestPath){ $bestPath }"
)


def check_ps(code: str, label: str) -> bool:
    """用 Parser::ParseInput 做纯语法解析（不执行代码）"""
    enc = base64.b64encode(code.encode('utf-16-le')).decode()
    cmd = (
        "$c=[System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String('%s'));"
        "$t=$null; $e=$null;"
        "[System.Management.Automation.Language.Parser]::ParseInput($c,[ref]$t,[ref]$e)|Out-Null;"
        "if($e.Count -eq 0){ 'PARSE OK' }else{ $e | ForEach-Object { 'ERR: ' + $_.Message + ' @line ' + $_.Extent.StartLineNumber } }"
        % enc
    )
    r = subprocess.run(['powershell', '-NoProfile', '-Command', cmd],
                       capture_output=True, text=True, timeout=60)
    out = (r.stdout or '').strip()
    print(f'[{label}] {out}')
    if r.stderr.strip():
        print(f'[{label}] STDERR: {r.stderr.strip()[:300]}')
    return 'PARSE OK' in out


ok1 = check_ps(code1, 'resolve_all_dirs assembled ({0} chars)'.format(len(code1)))
ok2 = check_ps(code2, 'resolve_latest_dir embedded PS')
sys.exit(0 if ok1 and ok2 else 1)
