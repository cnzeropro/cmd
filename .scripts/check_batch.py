# -*- coding: utf-8 -*-
"""批处理脚本静态检查器（不运行任何脚本）
检查项：
1. goto/call 标签引用完整性（目标标签必须已定义）
2. 括号配对平衡（忽略引号内、转义、注释行）
3. setlocal/endlocal 配对
4. 标签重复定义
用法: python check_batch.py <目录>
"""
import re
import sys
import glob
import os

# 强制 UTF-8 输出，避免 Windows CI 默认代码页（cp1252）无法编码中文而崩溃
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

LABEL_RE = re.compile(r'^\s*:([A-Za-z_][A-Za-z0-9_]*)')
# goto 可以省略冒号（goto label）；call 必须是 call :label（call C:\x.cmd 是调用外部脚本）
GOTO_RE = re.compile(r'goto\s+:?([A-Za-z_][A-Za-z0-9_]*)', re.IGNORECASE)
CALL_RE = re.compile(r'call\s+:([A-Za-z_][A-Za-z0-9_]*)', re.IGNORECASE)


def is_comment(s: str) -> bool:
    t = s.strip().lstrip('@')
    return t.startswith('::') or t.upper().startswith('REM')


def check_file(path: str) -> list:
    problems = []
    with open(path, encoding='utf-8', errors='replace') as f:
        lines = [l.rstrip('\r\n') for l in f]

    # 1) 标签定义与重复检测
    labels = {}
    for i, l in enumerate(lines, 1):
        if is_comment(l):
            continue
        m = LABEL_RE.match(l)
        if m:
            name = m.group(1).lower()
            if name in labels:
                problems.append(f'line {i}: duplicate label :{name} (first defined at line {labels[name]})')
            else:
                labels[name] = i

    # 2) goto/call 引用检查
    for i, l in enumerate(lines, 1):
        if is_comment(l):
            continue
        for m in GOTO_RE.finditer(l):
            target = m.group(1).lower()
            if target not in labels:
                problems.append(f'line {i}: goto references undefined label :{target}')
        for m in CALL_RE.finditer(l):
            target = m.group(1).lower()
            if target not in labels:
                problems.append(f'line {i}: call references undefined label :{target}')

    # 3) 括号平衡（忽略双引号内、^ 转义、注释行）
    balance = 0
    in_quote = False
    for i, l in enumerate(lines, 1):
        if is_comment(l):
            continue
        j = 0
        while j < len(l):
            ch = l[j]
            if ch == '^' and j + 1 < len(l):
                j += 2  # 跳过转义字符
                continue
            if ch == '"':
                in_quote = not in_quote
            elif not in_quote:
                if ch == '(':
                    balance += 1
                elif ch == ')':
                    balance -= 1
                    if balance < 0:
                        problems.append(f'line {i}: unmatched closing parenthesis')
            j += 1
    if balance != 0:
        problems.append(f'unbalanced parentheses: net {balance} unclosed')

    # 4) setlocal/endlocal 配对
    setlocal = sum(1 for l in lines if re.search(r'(?i)^\s*@?\s*setlocal\b', l))
    endlocal = sum(1 for l in lines if re.search(r'(?i)^\s*@?\s*endlocal\b', l))
    if setlocal != endlocal:
        problems.append(f'setlocal({setlocal}) and endlocal({endlocal}) do not match')

    return problems


def main() -> int:
    root = sys.argv[1] if len(sys.argv) > 1 else '.'
    files = sorted(glob.glob(os.path.join(root, '*.cmd')))
    files += sorted(glob.glob(os.path.join(root, 'Nginx', '*.cmd')))
    if not files:
        print('No .cmd files found')
        return 1
    total = 0
    for path in files:
        problems = check_file(path)
        name = os.path.relpath(path, root)
        if problems:
            total += len(problems)
            print(f'[FAIL] {name}')
            for p in problems:
                print(f'       - {p}')
        else:
            print(f'[OK]   {name}')
    print(f'\nChecked {len(files)} scripts, found {total} problem(s)' if total else f'\nChecked {len(files)} scripts, all passed')
    return 0 if total == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
