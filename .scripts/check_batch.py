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

LABEL_RE = re.compile(r'^\s*:([A-Za-z_][A-Za-z0-9_]*)')
REF_RE = re.compile(r'(?:goto|call)\s+:?([A-Za-z_][A-Za-z0-9_]*)', re.IGNORECASE)


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
                problems.append(f'line {i}: 标签重复定义 :{name}（首次定义于 line {labels[name]}）')
            else:
                labels[name] = i

    # 2) goto/call 引用检查
    for i, l in enumerate(lines, 1):
        if is_comment(l):
            continue
        for m in REF_RE.finditer(l):
            target = m.group(1).lower()
            if target not in labels:
                problems.append(f'line {i}: goto/call 引用未定义的标签 :{target}')

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
                        problems.append(f'line {i}: 右括号多于左括号')
            j += 1
    if balance != 0:
        problems.append(f'括号总数不平衡: 净 {balance} 个未闭合')

    # 4) setlocal/endlocal 配对
    setlocal = sum(1 for l in lines if re.search(r'(?i)^\s*@?\s*setlocal\b', l))
    endlocal = sum(1 for l in lines if re.search(r'(?i)^\s*@?\s*endlocal\b', l))
    if setlocal != endlocal:
        problems.append(f'setlocal({setlocal}) 与 endlocal({endlocal}) 不配对')

    return problems


def main() -> int:
    root = sys.argv[1] if len(sys.argv) > 1 else '.'
    files = sorted(glob.glob(os.path.join(root, '*.cmd')))
    files += sorted(glob.glob(os.path.join(root, 'Nginx', '*.cmd')))
    if not files:
        print('未找到 .cmd 文件')
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
    print(f'\n共检查 {len(files)} 个脚本，发现 {total} 个问题' if total else f'\n共检查 {len(files)} 个脚本，全部通过')
    return 0 if total == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
