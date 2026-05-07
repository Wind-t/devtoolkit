# 🚀 WSL 命令行生产力指南

> 面向小白用户。每个工具只讲你最常用的 1-3 个用法，30 分钟看完就能上手。

---

## 目录

1. [Shell 基础](#1-shell-基础)
2. [文件导航](#2-文件导航)
3. [查看文件](#3-查看文件)
4. [搜索一切](#4-搜索一切)
5. [Git 工作流](#5-git-工作流)
6. [终端分屏](#6-终端分屏)
7. [文本编辑](#7-文本编辑)
8. [系统信息](#8-系统信息)
9. [Docker 管理](#9-docker-管理)
10. [预置别名](#10-预置别名)
11. [实用函数](#11-实用函数)
12. [速查表](#12-速查表)

---

## 1. Shell 基础

### 你的 Shell：zsh

按 `Tab` 自动补全，输入时自动高亮语法，灰色提示是自动建议——按 `→` 键采纳。

```bash
# 按 ↑ 模糊搜索历史命令
# 比如你记得之前跑过 docker，输入 dock 再按 ↑
dock ↑   # 自动匹配最近含 "dock" 的命令

# 忽略大小写。比如输入 LS 也会匹配 ls
LS   # 回车，zsh 会自动纠正执行 ls
```

### 历史命令：Atuin

你所有终端的历史命令会自动同步，换个终端也能搜到。

```bash
atuin search   # 交互式搜索全量历史（比 Ctrl+R 强）
# 或直接按 Ctrl+R（已被 Atuin 接管）
```

### 提示符：Starship

你看到的 `~  took 2s` 就是 Starship 的效果。它告诉你：
- 当前路径
- Git 分支和状态
- 上条命令耗时
- Node/Python 版本（如果进入对应项目）

### 快捷键

你的 zsh 预设了两个高效快捷键：

| 快捷键 | 效果 |
|--------|------|
| `Ctrl+Space` | 接受灰色建议词（不用按 `→`） |
| `Shift+Tab` | 反向切换补全选项 |

```bash
# 示例：输入 "ls /usr/l" 然后按 Tab
# 候选：lib, lib64, local, libexec…
# 按 Tab: lib → lib64 → libexec → …
# 按 Shift+Tab: 反方向回退
```

---

## 2. 文件导航

### 智能跳转：`z`（zoxide）

**最重要的命令，先学这个。** 它会记住你去过的目录，权重越高越靠前。

```bash
z dev       # 跳转到 ~/dev（匹配最近/最常用的含 "dev" 的目录）
z tool      # 跳转到 ~/projects/devtoolkit
z config    # 跳转到 ~/projects/devtoolkit/config（注意不是 ~/.config）

# 只记路径片段就可以
z con dev   # 匹配同时含 "con" 和 "dev" 的目录
```

**对比 `cd`：**

```bash
# cd 方式：需要知道完整路径
cd ~/projects/devtoolkit/config

# z 方式：随便说两个词就够了
z tool config
```

### 看目录：`eza`（替代 `ls`）

你已经把 `ls` 替换成了 eza，直接`ls`就行：

```bash
ls              # 彩色、图标、网格排列
ls -l           # 详细信息
ls -la          # 含隐藏文件
ls -T           # 树形展开目录结构
ls -l --sort=modified   # 按修改时间排序，最新文件在最上面
```

### 找文件：`fd`（替代 `find`）

```bash
fd readme       # 在当前位置递归搜索文件名含 "readme" 的文件
fd -e js        # 只找 .js 文件
fd -e rs src    # 在 src/ 下找 .rs 文件
fd '^doc'       # 文件名以 "doc" 开头（支持正则）

# 对比传统 find：
# find . -name "*readme*"        ← 难记
# fd readme                      ← 会打字就会用
```

---

## 3. 查看文件

### 带高亮的 `cat`：`bat`

`cat` 已被替换为 `bat`，直接 `cat` 就有效果：

```bash
cat README.md       # 语法高亮、行号、Git 变更标记
cat package.json    # JSON 自动格式化高亮
cat .zshrc          # 任何代码文件都会高亮
```

常用选项：

```bash
bat --plain         # 纯文本模式（不要行号和边框）
bat --show-all      # 显示所有不可见字符（调试用）
```

### 磁盘空间：`dust`（替代 `du`）

```bash
dust               # 当前目录按大小排序展示，一目了然
dust ~/.local      # 查看某目录的空间占用
dust -d 2          # 只展示 2 层深度
```

### 查看 JSON / YAML：`jq` / `yq`

```bash
cat data.json | jq .               # 格式化 JSON
cat data.json | jq '.name'         # 提取字段
cat config.yaml | yq '.server.port'  # 提取 YAML 字段
```

---

## 4. 搜索一切

### 代码搜索：`rg`（ripgrep）

比 `grep` 快 10-100 倍，自动忽略 `.gitignore` 里的文件。

```bash
rg useState            # 在当前目录搜索 "useState"
rg useState src/       # 只在 src/ 下搜
rg -l useState         # 只列出文件名
rg 'function\s+\w+'    # 正则搜索所有函数定义
rg -g '*.tsx' useState # 只在 .tsx 文件中搜
```

### 交互式模糊搜索：`fzf`

```bash
# Ctrl+T：在当前目录选文件，选中的路径自动贴到命令行
# 例如：cat [按 Ctrl+T，输入关键词选文件，回车]

# Ctrl+R：搜索历史命令（已被 Atuin 接管，但功能类似）

# 管道使用：
rg -l 'TODO' | fzf     # 搜索含 TODO 的文件，然后 fzf 模糊筛选
```

组合技：

```bash
# 搜索含 "useEffect" 的文件 → fzf 筛选 → 用 bat 查看
rg -l 'useEffect' | fzf | xargs bat

# 搜索含 "TODO" 的文件，按修改时间排序
rg -l 'TODO' | xargs ls -lt | head
```

---

## 5. Git 工作流

### 图形化 Git：`lazygit`

**最重要的 Git 工具。** 终端里直接输入 `lazygit`（或简写 `lg`）。

```bash
lg    # 打开 lazygit
```

进入后你会看到 5 个面板：

| 面板 | 内容 | 常用操作 |
|------|------|---------|
| 1. Status | 修改的文件 | `Space` 暂存，`a` 全部暂存 |
| 2. Branches | 本地分支 | `Space` 切换，`n` 新建 |
| 3. Commits | 提交历史 | `Enter` 查看详情 |
| 4. Stash | 暂存区 | `s` 暂存当前修改 |
| 5. 底部面板 | 操作预览 | — |

**最常用流程：**

```
1. 打开 lazygit，按 Space 勾选你要提交的文件
2. 按 c 输入提交信息
3. 按 P 推送到远程
```

其他快捷操作：
- `d` — 丢弃文件的修改（取消所有改动）
- `z` — 把文件藏到 stash
- `Shift+S` — 查看 diff
- `?` — 显示所有快捷键

### 漂亮的 diff：`delta`

你的 git diff 已经配置为 delta。试一下：

```bash
git diff          # 彩色、行号、逐词高亮
git show HEAD     # 查看最近一次提交的 diff
```

### GitHub CLI：`gh`

```bash
gh auth login         # 首次使用先登录（一次性）
gh repo view          # 查看当前仓库的 GitHub 页面
gh pr create          # 创建 Pull Request
gh pr list            # 列出所有 PR
gh issue create       # 创建 Issue
gh browse             # 在浏览器打开当前仓库
```

---

## 6. 终端分屏

### 你的终端复用器：`zellij`

**tmux 已被清理，zellij 是你的唯一复用器。**

```bash
zellij                  # 启动 zellij
```

**基础操作（记住 3 个键）：**

| 操作 | 按键 |
|------|------|
| 锁定/解锁 | `Ctrl+g`（所有快捷键都要先按这个） |
| 水平分屏 | `Ctrl+g` → `n`（new pane） |
| 关闭当前窗格 | `Ctrl+g` → `x` |
| 重命名标签页 | `Ctrl+g` → `,` |
| 切换窗格 | `Ctrl+g` → 方向键 |
| 切换标签页 | `Ctrl+g` → `[` 或 `]` |
| 全屏当前窗格 | `Ctrl+g` → `f` |
| 浮动窗格（画中画） | `Ctrl+g` → `w` |
| 分离会话 | `Ctrl+g` → `d`（后台运行，重新 `zellij attach` 连回） |
| 滚动模式 | `Ctrl+g` → `s`（然后用方向键/PgUp/PgDn 滚动） |

**为什么比 tmux 好：**
- 底部自带状态栏，显示窗格和快捷键提示
- 浮动窗格可以临时弹出小窗口而不破坏布局
- 开箱即用，不需要写配置文件

---

## 7. 文本编辑

### 终端编辑器：`micro`

```bash
micro file.txt       # 打开文件
micro .              # 打开当前目录的文件管理器
```

micro 的快捷键就是 `Ctrl+字母`，和普通编辑器一样：

| 操作 | 快捷键 |
|------|--------|
| 保存 | `Ctrl+s` |
| 退出 | `Ctrl+q` |
| 查找 | `Ctrl+f` |
| 撤销 | `Ctrl+z` |
| 重做 | `Ctrl+y` |
| 剪切/复制/粘贴 | `Ctrl+x` / `Ctrl+c` / `Ctrl+v` |
| 多光标 | `Ctrl+鼠标拖选` 或 `Alt+↑/↓` |
| 命令面板 | `Ctrl+e`（输入命令） |

**micro 的优势：**
- 不需要学 vim 的模态编辑
- 鼠标可以直接点击、选中、滚动
- 自动语法高亮、括号匹配、自动缩进
- 内置插件管理器

---

## 8. 系统信息

### 系统总览：`fastfetch`

```bash
fastfetch          # 一次性系统信息总览
```

会显示：OS、Kernel、Shell、CPU、GPU、内存、磁盘、运行时间等。

### 实时监控：`btop`

```bash
btop               # 实时 CPU/内存/磁盘/网络/进程
```

进入后：
- `鼠标` — 点击切换选项
- `1-4` — 切换视图
- `q` — 退出
- `f` — 搜索进程
- `k` — 杀死选中的进程

### 快速查命令用法：`tldr`（tealdeer）

比 `man` 快 100 倍，只给最常用的例子：

```bash
tldr tar            # tar 怎么用？
tldr docker         # docker 常用命令
tldr git rebase     # git rebase 实战示例
tldr --update       # 更新缓存
```

对比：

```bash
# man tar     ← 几千行，找不到重点
# tldr tar    ← 10 行，全是常用例子
```

---

## 9. Docker 管理

### 命令行

```bash
docker ps              # 查看运行中的容器
docker ps -a           # 查看所有容器（含停掉的）
docker images          # 查看本地镜像
docker logs -f 容器名   # 实时查看日志
docker exec -it 容器名 sh  # 进入容器内部
```

### 图形化 Docker：`lazydocker`

```bash
lazydocker            # 或简写 lzd
```

进入后：
- 左侧面板：容器列表
- 底部面板：日志实时滚动
- `Tab` — 切换面板
- `b` — 在浏览器打开
- `r` — 重启容器
- `d` — 删除容器
- `Enter` — 查看日志 / 进入容器 shell
- `?` — 帮助

---

## 10. 预置别名

你的 `.zshrc` 里预置了 30+ 个别名，记住几个高性价比的就能快很多。

### 目录跳转

```bash
..        # cd ..
...       # cd ../..
....      # cd ../../..
~         # cd ~
```

### 安全防护

这些命令加了 `-i`（删除前确认）和 `-v`（显示操作详情），防止手滑：

```bash
cp       # cp -iv    （覆盖前询问）
mv       # mv -iv    （覆盖前询问）
rm       # rm -iv    （删除前询问）
mkdir    # mkdir -pv （自动创建父目录 + 显示详情）
```

### 文件列表（eza）

| 别名 | 实际命令 | 效果 |
|------|---------|------|
| `ls` | `eza --icons --group-directories-first` | 彩色图标，目录排前 |
| `ll` | `eza -l --icons --group-directories-first --git` | 详细信息 + git 状态 |
| `la` | `eza -la --icons --group-directories-first --git` | 含隐藏文件 |
| `lt` | `eza --tree --level=2 --icons` | 树形，2 层深度 |
| `lta` | `eza --tree --icons -a` | 树形 + 隐藏文件 |

### Git 两字母流

```bash
g        # git
gs       # git status         — 最常用
ga       # git add
gc       # git commit
gp       # git push
gl       # git pull
gd       # git diff
gco      # git checkout
gb       # git branch
lg       # lazygit            — 图形化操作
```

### 系统维护

```bash
update     # sudo apt update && sudo apt upgrade -y
cleanup    # sudo apt autoremove -y && sudo apt autoclean
reload     # exec zsh    （重载 shell，配置改动后生效）
ports      # ss -tlnp    （查看所有监听端口）
ip         # ip -color   （彩色 IP 输出）
df         # df -h       （磁盘用量，人类可读）
```

### Docker

```bash
d          # docker
dc         # docker compose
dps        # docker ps --format ... （精简表格）
ld         # lazydocker
```

### Python（uv） + mise

```bash
uvr        # uv run
uva        # uv add
uvs        # uv sync
mx         # mise exec
mi         # mise install
ml         # mise list
```

### 现代替换（已自动生效）

```bash
grep       # → rg（ripgrep，快 100 倍）
find       # → fd（语法更简单）
cat        # → bat（语法高亮）
top        # → btop（更直观）
du         # → dust（大小排序，一目了然）
```

> **提示**：想看完整列表，终端输入 `alias` 回车即可。

---

## 11. 实用函数

除了别名，`.zshrc` 里还预置了 3 个常用函数。

### `mkcd` — 创建目录并进入

```bash
mkcd my-project     # 等同于 mkdir -p my-project && cd my-project
```

### `extract` — 智能解压

不用记 tar 参数，一个命令解所有格式：

```bash
extract archive.tar.gz
extract file.zip
extract file.7z
extract file.tar.bz2
```

支持的格式：`tar.gz`, `tar.bz2`, `tar.xz`, `zip`, `7z`, `rar`, `tgz`, `tbz2`, `.gz`, `.bz2`

### `pyinit` — 一键初始化 Python 项目

```bash
pyinit my-project     # 创建目录，配置 mise venv 自动激活
pyinit .              # 在当前目录初始化
```

自动完成三步：
1. 创建 mise.toml，配置 `.venv` 自动创建/激活
2. 不需要手动 `python -m venv`
3. `cd` 进出目录即可自动激活虚拟环境

---

## 12. 速查表

### 替换对照

| 传统操作 | 你的方式 | 说明 |
|---------|---------|------|
| `cd ~/xxx/xxx/xxx` | `z xxx` 或 `..` / `...` | 模糊跳转 |
| `ls -la` | `ll` | 详情 + git 状态 |
| `ls -R` | `lt` | 树形目录 |
| `find . -name "*.rs"` | `fd -e rs` | 更简单 |
| `grep -r "foo" .` | `rg foo` | 快 100 倍 |
| `cat file.rs` | `cat file.rs`（bat） | 语法高亮 |
| `du -sh *` | `dust` | 大小排序 |
| `man tar` | `tldr tar` | 只给例子 |
| `top` / `htop` | `btop` | 好看 + 鼠标 |
| `tmux` | `zellij` | 开箱即用 |
| `git status / add / commit` | `gs` / `ga` / `gc` | 两字母流 |
| `git log --graph` | `lg`（lazygit） | 可视化 |
| `docker ps` | `dps` | 精简表格 |
| `docker ps / logs` | `ld`（lazydocker） | 图形界面 |
| `nano` / `vim` | `micro` | Ctrl+S 保存 |
| `neofetch` | `fastfetch` | 更快更全 |
| `mkdir xxx && cd xxx` | `mkcd xxx` | 一次搞定 |
| `tar xzf / unzip / ...` | `extract xxx` | 自动识别格式 |
| `python -m venv .venv` | `pyinit` | 一键初始化 |

### 每日工作流示例

```bash
# 早上开工
z my-project           # 跳到项目目录
lg                     # lazygit：看昨天改了什么，切分支

# 写代码时
rg useState src/       # 搜索用法
cat README.md          # 看文档（带高亮）
fd -e tsx              # 找所有组件

# 需要分屏
zellij                 # 左边编辑器，右边跑命令

# 查看状态
btop                   # 系统负载
dust                   # 磁盘占用
fastfetch              # 系统信息

# 提交代码
gs                     # git status
ga file.ts             # git add
gc                     # git commit（或 lg 直接图形化操作）
gp                     # git push
gh pr create           # 创建 PR

# 系统维护
update && cleanup      # 更新系统 + 清理
ports                  # 查看端口占用
```

### 一个命令解决临时需求

```bash
# "package.json 里装了哪些依赖"
cat package.json | jq '.dependencies'

# "项目的 TODO 都在哪"
rg TODO | fzf | xargs micro

# "哪个目录最占空间"
dust ~

# "我前天跑过一条很长的 docker 命令"
atuin search docker    # 或 Ctrl+R 输入 docker

# "docker / tar 怎么用"
tldr docker
tldr tar

# "解压这个压缩包"
extract file.tar.gz
```

---

## 进阶提示

1. **善用 `tldr`** — 任何命令忘了用法，先 `tldr 命令名`，别去谷歌。

2. **善用 `Ctrl+R`** — 历史命令搜索，比重复输入快 10 倍。

3. **善用 `z`** — 别再用 `cd ../../../../` 了，直接 `z 目录名片段`。

4. **善用 `Tab`** — zsh 补全非常智能，路径、命令、Git 分支都能补。

5. **用 `micro` 而不是 nano** — 如果你不会 vim，micro 的体验和你熟悉的任何编辑器一样。

6. **用 `lazygit` 而不是 `git add` + `git commit`** — 可视化的暂存和提交，减少犯错。

7. **管道组合** — 这是命令行的精髓：
   ```bash
   工具A | 工具B | 工具C
   ```
   每个工具只做一件事，组合起来就是你的超级武器。
