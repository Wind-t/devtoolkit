# 🧰 DevToolkit — WSL 开发环境一键部署

> 一条命令，咖啡没凉，环境就绪。
> 幂等、现代、中国用户友好。

[![Platform](https://img.shields.io/badge/platform-WSL2%20%7C%20Ubuntu%2024.04+-blue)](https://learn.microsoft.com/en-us/windows/wsl/)
[![Shell](https://img.shields.io/badge/shell-zsh%20%2B%20starship-purple)](https://starship.rs)
[![Python](https://img.shields.io/badge/python-uv%20%2B%20ruff-yellow)](https://docs.astral.sh/uv/)
[![Version](https://img.shields.io/badge/multi--lang-mise-orange)](https://mise.jdx.dev)
[![AI](https://img.shields.io/badge/AI-OpenCode-green)](https://opencode.ai)

[English](README.en.md) | 中文

---

## 这是什么

一个 idempotent（幂等）的 WSL Ubuntu 开发环境 bootstrap 脚本。分 8 个 phase 渐进式安装，跑十遍不炸。最后链接 dotfiles 到 `$HOME`，重启终端就能干活。

**设计原则：**

- **快** — Rust 写的工具优先（uv、mise、starship、ripgrep、fd、zoxide、eza）
- **少** — 不堆屎山，不装 oh-my-zsh，按需加载
- **稳** — 幂等，网络挂了有 fallback，中断了有 trap 清理
- **中国用户友好** — apt 阿里云镜像、PyPI 清华镜像，SKIP_APT_MIRROR=1 可跳过

## 装了啥

| 分类 | 工具 | 干什么的 |
|------|------|---------|
| Shell | zsh + starship | 带主题色彩（Gruvbox Dark）的提示符 |
| 插件 | zsh-autosuggestions | 鱼壳风格自动补全 |
| | zsh-syntax-highlighting | 实时命令语法高亮 |
| 版本管理 | mise | Node、Go、Rust、Java 等 50+ 语言 |
| Python | uv | 包管理器 + Python 安装器（替代 pip/pyenv/poetry） |
| | Ruff | 10-100x 快的 linter + formatter |
| Git | lazygit + delta + difftastic | TUI 客户端 + 语法高亮 diff + 结构化对比 |
| 导航 | zoxide | 智能 cd（越用越懂你） |
| 列表 | eza | 现代 ls，带图标和 git 状态 |
| 搜索 | ripgrep + fd + fzf | 快速文件/内容搜索 |
| 查看 | bat | 带语法高亮的 cat |
| 速查 | tealdeer | 实用命令示例（tldr） |
| 监控 | btop | 现代资源监控（htop 替代） |
| 磁盘 | dust | 可视化磁盘占用（du 替代） |
| 终端 | yazi + zellij | 文件管理器 + 终端复用器 |
| 编辑器 | micro | 终端文本编辑器 ($EDITOR) |
| 信息 | fastfetch | 系统信息展示（neofetch 替代） |
| Docker | lazydocker | Docker TUI（lazygit 伴侣） |
| AI | OpenCode | 终端 AI 编程助手 |
| 其他 | atuin + fastfetch | shell 历史同步 + 系统信息 |

**Shell 函数：**

- `pyinit <项目名>` — 一键初始化 Python 项目（uv + mise venv 自动激活）
- `mkcd <目录>` — 创建目录并 cd 进去
- `extract <压缩包>` — 统一解压 tar.gz/zip/7z/rar

## 快速开始

### 前置条件

- Windows 11 / Windows 10 2004+
- BIOS 已开启虚拟化（VT-x / AMD-V）
- Windows 侧管理员权限

### 第一步 — 装 WSL2

以**管理员身份**打开 PowerShell：

```powershell
wsl --install -d Ubuntu-24.04
```

按提示重启。从开始菜单启动 **Ubuntu 24.04**，完成初始设置（用户名、密码）。

### 第二步 — 一键部署

```bash
git clone https://github.com/你的用户名/devtoolkit.git ~/.local/share/devtoolkit
bash ~/.local/share/devtoolkit/bootstrap.sh
```

等几分钟。看到 "Bootstrap Complete" 后：

```bash
exec zsh
bash ~/.local/share/devtoolkit/verify.sh   # 50 项检查，应该全绿
```

### 第三步 — 配置 OpenCode（可选）

```bash
opencode auth login
```

## 常用 alias

装完即用的快捷命令：

```bash
# git
g / ga / gs / gc / gp / gl / gd / gco / gb
lg          → lazygit

# 现代替换
grep        → rg (ripgrep)
find        → fd
cat         → bat
top         → btop
du          → dust

# 导航
..          → cd ..
...         → cd ../..
reload      → exec zsh

# Python
uvr         → uv run
uva         → uv add

# 系统
update      → sudo apt update && sudo apt upgrade
ports       → ss -tlnp
```

完整列表见 `config/.zshrc`。

## 项目结构

```
devtoolkit/
├── bootstrap.sh              # 主入口，按 phase 调度
├── verify.sh                 # 50 项环境健康检查
├── install/
│   ├── 00-essentials.sh      # apt 镜像 + 基础包 + locale
│   ├── 01-zsh.sh             # zsh + 插件（手动 clone，无 oh-my-zsh）
│   ├── 02-mise.sh            # 多语言版本管理器
│   ├── 03-uv.sh              # Python 工具链（uv + Ruff）
│   ├── 04-starship.sh        # 跨 shell 提示符
│   ├── 05-dev-tools.sh       # lazygit, ripgrep, fd, fzf, bat, difftastic, tealdeer, gh
│   ├── 06-opencode.sh        # 终端 AI 编程助手
│   └── 07-extras.sh          # zoxide, eza, btop, delta, lazydocker, dust, yazi, fastfetch, zellij, atuin
└── config/
    ├── .zshrc                # 交互式 shell 配置（alias、插件、fzf、函数）
    ├── .zshenv               # 环境变量（EDITOR, XDG, locale, mise）
    ├── .profile              # bash 兼容登录 shell
    ├── starship.toml         # Tokyo Night 提示符主题
    ├── .gitconfig            # git 默认配置 + delta + difftastic + alias
    ├── .gitignore_global     # 全局 gitignore
    ├── mise.config.toml      # mise 全局设置
    ├── wsl.conf.ref          # → /etc/wsl.conf（WSL 内）
    └── .wslconfig.ref        # → %UserProfile%\.wslconfig（Windows 侧）
```

## 定制指南

### 跳过 apt 镜像

```bash
SKIP_APT_MIRROR=1 bash bootstrap.sh
```

### 只装某几个 Phase

```bash
bash ~/.local/share/devtoolkit/install/05-dev-tools.sh   # 只装 dev tools
bash ~/.local/share/devtoolkit/install/07-extras.sh       # 只装 extras
```

### 加更多语言运行时

```bash
mise use --global rust@latest java@21 ruby@3.4
```

### 修改 dotfiles

直接编辑 `config/` 下的文件，然后重跑 bootstrap（幂等，只重新链接）：

```bash
bash ~/.local/share/devtoolkit/bootstrap.sh
```

### API 密钥

```bash
touch ~/.env_secrets && chmod 600 ~/.env_secrets
# 编辑添加：
# export ANTHROPIC_API_KEY=sk-...
# export OPENAI_API_KEY=sk-...
# 然后取消 .zshrc 里 source ~/.env_secrets 那行的注释
```

### 换主题

编辑 `~/.config/starship.toml`。参考 [starship.rs/config](https://starship.rs/config/)。

### 装 Maple Mono NF CN（推荐）

Starship 的图标需要 Nerd Font 才能正常渲染。推荐 [Maple Mono NF CN](https://github.com/subframe7536/maple-font)——原生中文等宽（精确 2:1）、Nerd Font 图标内置、连字可配置。比 JetBrainsMono 更适合中文终端场景。

下载后在 Windows Terminal 设置里选 `Maple Mono NF CN`。

## 踩坑指南

### bootstrap 中途报错退出

1. **看错误信息** — stderr 不会被吞，错误直接显示
2. 网络问题最常见：GitHub API 未认证限速（60次/小时）或某镜像抽风
3. 脚本幂等，修好问题直接重跑即可

### 某个工具没装上

```bash
bash ~/.local/share/devtoolkit/verify.sh
```

50 项逐个检查，哪项挂了标红，一目了然。botp/delta/lazydocker/dust 如果 API 不通会自动 fallback 到硬编码版本。

### zsh 插件没生效

确认 `~/.zshrc` 末尾有：

```bash
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
```

### sudo 超时

bootstrap 内置了 sudo keepalive 后台进程，每 60 秒自动刷新 credential，全程不会超时。如果手动跑单个 install 脚本时间很长，先 `sudo -v`。

### 提示符乱码

装 Maple Mono NF CN（见上方"定制指南"）。

### 卸载

没有集中卸载脚本。手动操作：

```bash
# 删 dotfiles 链接
rm ~/.zshrc ~/.zshenv ~/.profile ~/.gitconfig ~/.gitignore_global
rm ~/.config/starship.toml ~/.config/mise/config.toml

# ~/.local/bin 下大部分二进制是 devtoolkit 装的，逐个确认后删
ls ~/.local/bin

# apt 包不删也行
```

## 验证

```bash
bash ~/.local/share/devtoolkit/verify.sh
```

检查 50 项：WSL 环境、Shell、mise、Python、Dev Tools、Extras、AI、dotfiles、PATH、配置内容。

## 已知限制

- 仅支持 **WSL2 Ubuntu 24.04+**，x86_64 / aarch64
- GitHub API 未认证限 60 次/小时，单次 bootstrap 约消耗 8-10 次
- `curl | bash` 安装（mise、uv、starship 等）依赖上游服务器安全
- git user.name / user.email 需要装完自己改（`config/.gitconfig` 里是占位符）

## 许可

MIT — 随便用，随便改，随便分发。

---

> 本脚本已经过贴吧老哥锐评。
