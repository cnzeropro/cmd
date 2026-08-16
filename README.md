# cmd

Windows 开发环境常用服务的批处理管理脚本集（`.cmd`），用于快速启动、停止、重启本机服务及初始化开发环境。

## 脚本清单

### 服务管理

| 脚本 | 服务 | 说明 |
| ---- | ---- | ---- |
| `MySQL57.cmd` | MySQL57 | 启动 / 停止 / 重启 MySQL 5.7 服务 |
| `MySQL80.cmd` | MySQL80 | 启动 / 停止 / 重启 MySQL 8.0 服务 |
| `Oracle.cmd` | OracleXE | 切换 Oracle XE 运行状态（含监听器） |
| `Redis.cmd` | Redis | 启动 / 停止 / 重启 Redis 服务 |
| `SVN.cmd` | VisualSVNServer | 启动 / 停止 / 重启 VisualSVN 服务 |

### Nginx 管理

| 脚本 | 说明 |
| ---- | ---- |
| `Nginx/Start.cmd` | 启动 Nginx |
| `Nginx/Stop.cmd` | 快速停止 Nginx |
| `Nginx/Quit.cmd` | 优雅停止 Nginx |
| `Nginx/Reload.cmd` | 重载配置 |

### 开发环境

| 脚本 | 说明 |
| ---- | ---- |
| `init_dev_env.cmd` | 初始化开发环境：批量扫描 `C:\App\Env` 下的工具目录，写入用户环境变量与 PATH |
| `switch_jdk_version.cmd` | 切换 JDK 版本（基于 `C:\App\Env\Java` 下的目录列表） |

## 使用说明

- 服务管理脚本需以**管理员身份**运行；脚本内置 UAC 提权逻辑，双击或普通权限运行时会自动请求提权。
- `init_dev_env.cmd` 参数：
  - `--dry-run`：仅预览将要写入的环境变量与 PATH，不实际修改
  - `--apply`：实际写入（跳过交互确认）
  - `--quiet` / `-q`：静默模式
  - `--verbose` / `-v`：详细输出
  - 无参数：交互式选择运行模式
- 脚本中的服务名与安装路径（如 `C:\App\Env`）为本机约定，换机使用前请按需修改。

## 目录结构

```
cmd/
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
