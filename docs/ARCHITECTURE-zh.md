# 架构设计 — WSL 开发环境

## 1. 分层模型

```
┌─────────────────────────────────────────────────────────┐
│                  Windows 11 (宿主机)                      │
│                                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │             Docker Desktop (Windows 侧)           │   │
│  │  ┌──────────────┐  ┌──────────────────────────┐  │   │
│  │  │  docker cli  │  │  docker-desktop (WSL VM)  │  │   │
│  │  └──────┬───────┘  └──────────────────────────┘  │   │
│  └─────────┼────────────────────────────────────────┘   │
│            │ unix:///var/run/docker.sock                │
│  ┌─────────┼────────────────────────────────────────┐   │
│  │         ▼                 WSL 2 虚拟机             │   │
│  │  ┌──────────────────────────────────────────┐     │   │
│  │  │        Ubuntu 24.04 (开发环境)             │     │   │
│  │  │                                           │     │   │
│  │  │  ┌ Shell 层 ────────────────────────┐    │     │   │
│  │  │  │ zsh + starship + 插件             │    │     │   │
│  │  │  │ zoxide（智能目录跳转）             │    │     │   │
│  │  │  │ eza（现代 ls）                    │    │     │   │
│  │  │  └───────────────────────────────────┘    │     │   │
│  │  │                                           │     │   │
│  │  │  ┌ 版本管理 ────────────────────────┐    │     │   │
│  │  │  │ mise（node, go, rust, java…）     │    │     │   │
│  │  │  └───────────────────────────────────┘    │     │   │
│  │  │                                           │     │   │
│  │  │  ┌ Python 层 ──────────────────────┐     │     │   │
│  │  │  │ uv（包管理）+ Ruff（lint/fmt）    │     │     │   │
│  │  │  │ pyinit() → 项目一键初始化         │     │     │   │
│  │  │  └───────────────────────────────────┘    │     │   │
│  │  │                                           │     │   │
│  │  │  ┌ 工具层 ─────────────────────────┐     │     │   │
│  │  │  │ lazygit, ripgrep, fd, fzf, bat    │     │     │   │
│  │  │  │ delta (git diff), btop (监控)     │     │     │   │
│  │  │  └───────────────────────────────────┘    │     │   │
│  │  │                                           │     │   │
│  │  │  ┌ AI 层 ──────────────────────────┐     │     │   │
│  │  │  │ OpenCode（终端 AI 编程助手）      │     │     │   │
│  │  │  └───────────────────────────────────┘    │     │   │
│  │  └───────────────────────────────────────────┘    │   │
│  └────────────────────────────────────────────────────┘   │
│                                                         │
│  ┌ VS Code (Windows 侧) ────────┐                       │
│  │  Remote - WSL 扩展             │                       │
│  │  Remote - Containers 扩展      │                       │
│  └────────────────────────────────┘                       │
└─────────────────────────────────────────────────────────┘
```

---

## 2. 为什么这么设计

### Docker：引擎在 Windows 上，不在 WSL 里

> ⚠️ **正确做法**：Docker Desktop 安装在 Windows 上。它会创建一个专用的 `docker-desktop` WSL 发行版（内核级虚拟机），然后通过 WSL Integration 设置把 `docker.sock` 暴露给你的开发环境。

**为什么不在 WSL 里 `apt install docker-ce`：**

- WSL 2 本身就是一台被托管的虚拟机，在里面再套 Docker 会形成双重 cgroup 开销
- WSL 里的 systemd 对 containerd/runC 的支持不如 Docker Desktop 稳定
- Docker Desktop 提供了图形界面、自动更新、以及统一的 `docker compose`

实际体验就是——在 WSL 里敲 `docker ps`，命令行在 Ubuntu 里跑，但 Docker 引擎在 Windows 侧的专用 VM 里执行，两者通过 socket 通信。零感知延迟，但对系统资源的管理更合理。

### 为什么用 mise，不用 nvm/pyenv/asdf

- **一个工具管 50+ 语言**——不用装 5 个不同的版本管理器
- Rust 写的，单个二进制，启动飞快
- 兼容 `.tool-versions`、`.node-version`、`.ruby-version` 等旧格式，迁移无痛
- 内置 direnv 替代方案，项目级环境变量自动切换

以前要维护 nvm（管 node）、pyenv（管 python）、rbenv（管 ruby）三套东西，每个都有自己的一套 shim、init 脚本、升级方式。mise 一个全解决。

### 为什么用 uv，不用 pip/virtualenv/poetry

- Rust 实现，比 pip 快 10-100 倍。`uv sync` 的感觉像是按了快进键
- 一个二进制替代 pip、pip-tools、virtualenv、pyenv、poetry、pipx 全家桶
- 能自己装 Python（`uv python install 3.13`），不需要 pyenv
- 零配置 lockfile（`uv lock`）

实际上 uv 已经成了 Python 社区的共识选择。Astral 团队同时维护 uv 和 Ruff，两个工具配合丝滑。

### 为什么不用 oh-my-zsh

- oh-my-zsh 自带 100+ 插件，绝大多数用不上，拖慢 shell 启动
- 我们只需要两个插件：autosuggestions（自动补全）和 syntax-highlighting（语法高亮）
- 手动 git clone 的方式让我们完全控制加载顺序和版本
- 一个干净、精简的 `.zshrc`，比 oh-my-zsh 那套框架易懂得多

shell 启动速度的差别是肉眼可见的——oh-my-zsh 常有 0.5-1 秒的延迟，我们的配置几乎秒开。

### 为什么用 Starship，不用 Powerlevel10k

- Rust 实现，生成提示符的速度是 p10k 的数倍
- 跨 shell：bash、zsh、fish、PowerShell 全支持。一套配置到处用
- TOML 配置文件——干净、可以版本控制、人类可读
- 不依赖任何 zsh 框架。你甚至可以把它用在 bash 登录 shell 里

p10k 是 zsh 专属的，而且配置非常复杂（`.p10k.zsh` 动辄几百行）。Starship 一个 toml 文件搞定，效果同样出色。

### 为什么用 zoxide，不用 autojump/z.lua

- Rust 实现，更快
- 跨 shell 支持
- 更聪明的排名算法（frecency = 频率 + 最近性，不是简单的访问次数）
- 零配置：装好之后直接用 `z <目录名>`，它会自动学习你的习惯

用两周之后，你可能都不记得项目的完整路径了——`z proj` 就能跳过去。

### 为什么用 eza，不用 exa 或普通 ls

- `exa` 已经停止维护，eza 是社区 fork 的活跃版本
- 支持图标、git 状态、树形视图、颜色编码权限
- 在 Ubuntu 24.04 的 apt 仓库里直接能装

---

## 3. 环境变量策略

| 变量 | 用途 | 位置 | 为什么放这里 |
|------|------|------|------------|
| `EDITOR` | git、crontab 等调用的默认编辑器 | `.zshenv` | 非交互式 shell 脚本也需要 |
| `VISUAL` | 同 EDITOR | `.zshenv` | POSIX 惯例 |
| `OPENCODE_CONFIG_DIR` | OpenCode 配置路径 | `.zshenv` | CLI 和 TUI 模式都需要 |
| `STARSHIP_CONFIG` | starship.toml 路径 | `.zshenv` | 脚本化使用时也需要 |
| `MISE_DATA_DIR` | mise 安装目录 | `.zshenv` | mise activate 时需要 |
| `BAT_THEME` | bat 语法高亮主题 | `.zshenv` | 全局默认 |
| `PATH`（扩展） | `~/.local/bin` 优先 | `.zshrc` | 交互式使用；`.profile` 处理登录 shell |
| `FZF_DEFAULT_OPTS` | fzf 外观配置 | `.zshrc` | 仅交互式需要 |
| `UV_INDEX_URL` | PyPI 镜像 | `.zshenv`（可选） | 影响所有 uv 调用 |

**原则**：需要被非交互式 zsh 脚本使用的变量放 `.zshenv`，仅交互式需要的放 `.zshrc`，bash 兼容的放 `.profile`。

---

## 4. 文件系统最佳实践

```
/mnt/c/Users/你/              ← 别把项目放在这（跨文件系统 I/O 慢 5-10 倍）
~/projects/                   ← 项目放这里（原生 ext4 虚拟磁盘）
```

WSL 2 在虚拟机磁盘内使用 ext4 文件系统。通过 `/mnt/c` 访问 Windows 文件会走 9P 协议层——每次 I/O 调用都要穿越虚拟机边界。对于 git 操作、`npm install` 或者任何涉及大量小文件的操作，性能是灾难级的。

**建议**：所有源码放 `~/projects/`。`/mnt/c` 只用于一次性文件传输。

---

## 5. 性能优化

### `.wslconfig` 调优（Windows 侧）

| 参数 | 建议值 | 说明 |
|------|--------|------|
| `memory` | 物理内存的 50-60% | 留给 Windows 足够呼吸空间 |
| `autoMemoryReclaim=gradual` | 开启 | WSL 自动归还空闲内存，不用关机 |
| `networkingMode=mirrored` | 开启 | WSL 共享 Windows IP，localhost 直通 |
| `sparseVhd=true` | 开启 | 删文件后自动收缩虚拟磁盘 |

### Linux 侧优化

- **apt 镜像**：阿里云 / 清华镜像，`apt update` 从几分钟降到几秒
- **uv 镜像**：PyPI 镜像加速 Python 包下载
- **`wsl.conf` 配置**：`appendWindowsPath=true` 允许从 WSL 调用 Windows 工具；设 `false` 则 PATH 更干净

---

## 6. Shell 函数设计

| 函数 | 用途 | 示例 |
|------|------|------|
| `pyinit [项目名]` | 一键初始化 Python 项目（uv + mise venv 自动激活） | `pyinit myapp` |
| `mkcd <目录>` | 创建目录并 cd 进去 | `mkcd ~/projects/foo` |
| `extract <文件>` | 统一解压（tar.gz/zip/7z/rar） | `extract archive.tar.gz` |

---

## 7. 技术选型对照表

| 场景 | 旧方案 | 新方案 | 为什么更好 |
|------|--------|--------|-----------|
| Python 包管理 | pip + virtualenv + pyenv | **uv** | 10-100x 快，单二进制，自带 Python 安装器 |
| 多语言版本管理 | nvm, pyenv, rbenv, sdkman | **mise** | 一个工具管 50+ 语言，内置 direnv |
| Shell 框架 | oh-my-zsh | **手动插件** | 启动更快，更轻量，完全可控 |
| 命令行提示符 | Powerlevel10k | **Starship** | Rust，跨 shell，配置更简单 |
| 目录跳转 | autojump / z.lua | **zoxide** | Rust，跨 shell，frecency 算法 |
| 文件列表 | exa（已停维） | **eza** | 活跃维护，图标、git 状态、树形视图 |
| Lint / 格式化 | Flake8 + Black + isort | **Ruff** | 单工具，10-100x 快 |
| Git 图形界面 | GitKraken / SourceTree | **lazygit** | 终端原生，无 Electron 臃肿 |
| Git diff 查看 | 原生 git diff | **delta** | 语法高亮、行号、侧边对比 |
| AI 编程助手 | Copilot（仅编辑器内） | **OpenCode** | 终端代理，多模型，多供应商 |
| Docker | WSL 内装 docker-ce | **Docker Desktop + WSL Integration** | 更稳的虚拟机管理，GUI，自动更新 |
| 系统监控 | htop | **btop** | 更现代的界面，GPU 显示，主题支持 |
| 磁盘查看 | du | **dust** | 可视化树形展示，一目了然 |
| 字体 | JetBrainsMono Nerd Font | **Maple Mono NF CN** | 原生中文等宽（精确 2:1），Nerd Font 图标内置 |

---

## 8. 脚本执行流程

```
bootstrap.sh
  │
  ├─ Phase 1: 00-essentials.sh    apt 镜像 + 基础包 + locale
  ├─ Phase 2: 01-zsh.sh           zsh + 插件（手动 clone）
  ├─ Phase 3: 02-mise.sh          多语言版本管理器 + node/go 运行时
  ├─ Phase 4: 03-uv.sh            uv + Ruff + PyPI 镜像
  ├─ Phase 5: 04-starship.sh      跨 shell 提示符
  ├─ Phase 6: 05-dev-tools.sh     lazygit, ripgrep, fd, fzf, bat, difftastic, tealdeer, gh
  ├─ Phase 7: 06-opencode.sh      终端 AI 编程助手
  ├─ Phase 8: 07-extras.sh        zoxide, eza, btop, delta, lazydocker, dust, yazi 等
  │
  └─ Linking:                    符号链接 config/ 下的 dotfile 到 $HOME
```

每个 Phase 的脚本都可以独立运行，Phase 之间通过 `command -v` 守卫和依赖检查保证安全。安装失败不阻断后续 Phase（除非必要依赖缺失）。

---

## 9. 错误处理设计

项目采用**三层防护**策略：

| 层 | 机制 | 覆盖场景 |
|----|------|---------|
| 外层 | `set -euo pipefail` + `trap EXIT INT TERM` | 脚本级异常退出，临时文件清理 |
| 中层 | `command -v` 守卫 + `curl -f` + `jq // empty` | 网络异常、API 限流、幂等跳过 |
| 内层 | `|| { fallback }` + 硬编码 fallback 版本号 | GitHub API 完全不可达时的最终保底 |

**trap 清理**：所有创建临时目录的代码块都有配对的 trap set/clear，确保 Ctrl+C 或 `set -e` 退出时不留垃圾。

**幂等性**：整个 bootstrap 可以在同一台机器上跑十次，每次都是"检查→跳过已有→只装缺的"。

---

> 更详细的设计决策和踩坑记录见 [README.md](../README.md)。
