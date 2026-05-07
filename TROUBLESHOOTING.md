# Troubleshooting Guide

## GitHub API Rate Limit (403 Error)

**Problem**: `curl: (22) The requested URL returned error: 403` in `verify.sh` version checks.

**Cause**: GitHub API rate limit exceeded (60 requests/hour for unauthenticated requests).

**Auto-fix**: `verify.sh` now detects `gh auth status` automatically. If you're logged into `gh`, it uses authenticated API calls (5000 req/hr limit). If not, it falls back to unauthenticated curl.

**Steps**:
1. Log into gh once: `gh auth login`
2. `verify.sh` will use it automatically — no further config needed.

**If `gh` is unavailable**:
- Wait for rate limit reset (hourly), or
- Install tools via apt: `sudo apt install -y bat eza btop git-delta fastfetch`

## OpenCode Installation Failed

**Problem**: `Failed to fetch version information`

**Solution**:
```bash
curl -fsSL https://opencode.ai/install.sh | bash
# or manually download from https://github.com/anomalyco/opencode/releases
```

## Symbol Links Not Created

**Problem**: `.zshrc`, `.zshenv` etc. show as FAIL in verify.sh

**Cause**: Script exited early due to `set -euo pipefail` and a failed phase.

**Solution**:
```bash
# Fix ownership first
sudo chown -R $USER:$USER ~/projects/devtoolkit

# Manually create links
CONFIG_DIR="$HOME/dev/devtoolkit/config"
ln -sf "$CONFIG_DIR/.zshrc" "$HOME/.zshrc"
ln -sf "$CONFIG_DIR/.zshenv" "$HOME/.zshenv"
ln -sf "$CONFIG_DIR/.gitconfig" "$HOME/.gitconfig"
ln -sf "$CONFIG_DIR/starship.toml" "$HOME/.config/starship/starship.toml"
ln -sf "$CONFIG_DIR/mise.config.toml" "$HOME/.config/mise/config.toml"
ln -sf "$CONFIG_DIR/.gitignore_global" "$HOME/.gitignore_global"
```

## bat Command Not Found

**Problem**: `bat --version` fails in verify.sh

**Cause**: Ubuntu packages `bat` as `batcat` command.

**Solution**:
- The alias `bat='batcat'` should be set in `.zshrc`
- Or use `batcat --version` directly

## WSL Mirrored Networking Issues

**Problem**: `localhost` not accessible between Windows and WSL, or LAN access fails.

**Solution**: Mirrored networking mode (GA since WSL 2.4+) may require Hyper-V firewall configuration:
```powershell
# In PowerShell (admin):
Set-NetFirewallHyperVVMSetting -Name '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}' -LoopbackEnabled True
```

For LAN access to WSL services, create a Hyper-V firewall rule:
```powershell
New-NetFirewallHyperVRule -Name "WSL Port 3000" -DisplayName "WSL Port 3000" -Direction Inbound -Protocol TCP -LocalPorts 3000
```

**Note**: `dnsTunneling` and `firewall` are GA features, defaulting to `true` on Windows 11 22H2+. Check `.wslconfig` if issues persist.

## WSL Sparse VHD Warning

**Problem**: `wsl: 由于潜在的数据损坏，目前已禁用稀疏 VHD 支持` or disk space growing unbounded.

**Solution**: Enable sparse VHD in `.wslconfig` (experimental but recommended for disk optimization):
```ini
[experimental]
sparseVhd=true
```
Then in PowerShell (admin), if the distro already exists:
```powershell
wsl.exe --manage Ubuntu-24.04 --set-sparse --allow-unsafe
```
Restart WSL: `wsl --shutdown`

## libcuda.so.1 Not a Symbolic Link

**Problem**: `/sbin/ldconfig.real: /usr/lib/wsl/lib/libcuda.so.1 is not a symbolic link`

**Cause**: WSL NVIDIA driver issue.

**Solution** (optional, doesn't affect functionality):
```bash
sudo rm /usr/lib/wsl/lib/libcuda.so.1
sudo ln -s /usr/lib/wsl/lib/libcuda.so /usr/lib/wsl/lib/libcuda.so.1
sudo ldconfig
```
