# script-kit

Windows 开发环境常用服务的批处理管理脚本集（`.cmd`），用于快速启动、停止、重启本机服务及初始化开发环境。

## 脚本清单

### 服务管理

| 脚本 | 服务 | 说明 |
| ---- | ---- | ---- |
| `MySQL57.cmd` | MySQL57 | 启动 / 停止 / 重启 MySQL 5.7 服务 |
| `MySQL80.cmd` | MySQL80 | 启动 / 停止 / 重启 MySQL 8.0 服务 |
| `Oracle.cmd` | Oracle（可配置） | 启动 / 停止 / 重启 Oracle 服务，服务名、监听器名与 SID 可在启动时配置（默认 XE 版） |
| `Redis.cmd` | Redis | 启动 / 停止 / 重启 Redis 服务 |
| `SVN.cmd` | VisualSVNServer | 启动 / 停止 / 重启 VisualSVN 服务 |

### Nginx 管理

| 脚本 | 说明 |
| ---- | ---- |
| `Nginx/Start.cmd` | 启动 Nginx |
| `Nginx/Stop.cmd` | 快速停止 Nginx |
| `Nginx/Quit.cmd` | 优雅停止 Nginx |
| `Nginx/Reload.cmd` | 重载配置 |

> Nginx 脚本会自动检测 `nginx` 是否在 PATH 中，找不到时提示输入 `nginx.exe` 的完整路径。

### 开发环境

| 脚本 | 说明 |
| ---- | ---- |
| `init_dev_env.cmd` | 初始化开发环境：批量扫描 `C:\App\Env` 下的工具目录，写入用户环境变量与 PATH |
| `switch_jdk_version.cmd` | 切换 JDK 版本（基于 `C:\App\Env\Java` 下的目录列表） |

## 使用说明

- 服务管理脚本需以**管理员身份**运行；脚本内置 UAC 提权逻辑，双击或普通权限运行时会自动请求提权。
- `init_dev_env.cmd` 参数：
  - `--dry-run`：仅预览将要写入的环境变量与 PATH，不实际修改
  - `--apply`：实际写入（跳过交互确认）；写入前自动把当前 PATH 备份到 `%USERPROFILE%\.cmd-env-path-backup.txt`
  - `--restore`：从备份恢复 PATH，并删除本脚本曾设置的工具环境变量（完整回滚）
  - `--list`：排查模式（等同 `--dry-run --verbose`），只输出工具检测详情，不写任何东西
  - `--quiet` / `-q`：静默模式
  - `--verbose` / `-v`：详细输出
  - 无参数：交互式选择运行模式
- 脚本中的服务名与安装路径（如 `C:\App\Env`）为本机约定，换机使用前请按需修改。
- 脚本文件为 UTF-8 编码，中文注释在默认 GBK 代码页的控制台下可能显示乱码（不影响执行）；如需正常显示，可先执行 `chcp 65001`。

## 沙盒实测（Windows Sandbox）

仓库内置一键实测脚本，在隔离的 Windows Sandbox 中非交互运行关键脚本，验证不会卡死且退出码正确，全程不影响本机（项目目录只读挂载、沙盒无网络）：

1. 启用「Windows 沙盒」功能（需要管理员权限与重启）
2. 运行 `.scripts\sandbox\launch_sandbox_test.cmd`
3. 等待约 1-2 分钟，自动显示 3 个测试场景的结果

测试场景覆盖全部 11 个脚本的每个分支（58+ 断言）：服务菜单全流程、EOF 防护、Oracle 配置、Nginx 路径分支、`init_dev_env` 的 dry-run/apply/restore/list/quiet/verbose、`switch_jdk` 的成功/取消/重问分支，以及提权 VBS 自删除验证。

## 开发

- 提交前自动运行静态检查（pre-commit 钩子，经 `core.hooksPath` 指向 `.githooks/`）
- 推送后 GitHub Actions 自动运行相同检查（`.github/workflows/static-check.yml`）

## 目录结构

## 许可证

[MIT](LICENSE)

## 目录结构

```
script-kit/
├── MySQL57.cmd
├── MySQL80.cmd
├── Oracle.cmd
├── Redis.cmd
├── SVN.cmd
├── init_dev_env.cmd
├── switch_jdk_version.cmd
└── Nginx/
    ├── Start.cmd
    ├── Stop.cmd
    ├── Quit.cmd
    └── Reload.cmd
```
