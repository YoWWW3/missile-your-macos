#!/bin/bash
#
# backup-config.sh — Phase 1: Backup Developer Configuration
#
# Backs up SSH keys, shell configs, Git settings, editor settings,
# database client configs, terminal app configs, Homebrew packages,
# and other developer-relevant files before erasing macOS.
#
# Usage:
#   ./backup-config.sh              # Saves backup ZIP to ~/Desktop
#   ./backup-config.sh /path/to/dir # Saves backup ZIP to specified directory
#

set -euo pipefail

# ─── Configuration ───────────────────────────────────────────────────────────

BACKUP_DEST="${1:-$HOME/Desktop}"
BACKUP_NAME="mac_dev_backup_$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$BACKUP_DEST/$BACKUP_NAME"
LOG_FILE="$BACKUP_DIR/_backup_log.txt"

# ─── Colors ──────────────────────────────────────────────────────────────────

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ─── Helper Functions ────────────────────────────────────────────────────────

log()  { echo -e "${GREEN}✔${NC} $1"; echo "[OK] $1" >> "$LOG_FILE"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; echo "[WARN] $1" >> "$LOG_FILE"; }
fail() { echo -e "${RED}✖${NC} $1"; echo "[SKIP] $1" >> "$LOG_FILE"; }
info() { echo -e "${CYAN}ℹ${NC} $1"; echo "[INFO] $1" >> "$LOG_FILE"; }

backup_file() {
    local src="$1"
    local dest_dir="$2"
    if [ -f "$src" ]; then
        mkdir -p "$dest_dir"
        cp "$src" "$dest_dir/"
        return 0
    fi
    return 1
}

backup_dir() {
    local src="$1"
    local dest="$2"
    if [ -d "$src" ]; then
        mkdir -p "$dest"
        cp -r "$src" "$dest/"
        return 0
    fi
    return 1
}

# ─── Pre-flight Checks ──────────────────────────────────────────────────────

if [ ! -d "$BACKUP_DEST" ]; then
    echo -e "${RED}Error:${NC} Destination directory does not exist: $BACKUP_DEST"
    echo "Usage: $0 [destination_directory]"
    exit 1
fi

mkdir -p "$BACKUP_DIR"
echo "Backup started at $(date)" > "$LOG_FILE"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          macOS Developer Configuration Backup               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
info "Backup destination: $BACKUP_DIR"
echo ""

# ─── 1. SSH Keys ─────────────────────────────────────────────────────────────

echo "── SSH Keys ──────────────────────────────────────────────────"
if [ -d "$HOME/.ssh" ]; then
    backup_dir "$HOME/.ssh" "$BACKUP_DIR/ssh"
    log "SSH keys and config backed up (~/.ssh)"
else
    fail "No ~/.ssh directory found"
fi
echo ""

# ─── 2. Shell Configuration ─────────────────────────────────────────────────

echo "── Shell Configuration ─────────────────────────────────────"
SHELL_FILES=(
    ".zshrc"
    ".zshenv"
    ".zprofile"
    ".bashrc"
    ".bash_profile"
    ".profile"
    ".aliases"
    ".exports"
    ".functions"
    ".path"
    ".extra"
    ".inputrc"
)
shell_count=0
for f in "${SHELL_FILES[@]}"; do
    if backup_file "$HOME/$f" "$BACKUP_DIR/shell"; then
        log "Backed up $f"
        shell_count=$((shell_count + 1))
    fi
done
if [ "$shell_count" -eq 0 ]; then
    fail "No shell configuration files found"
else
    info "Total shell config files backed up: $shell_count"
fi
echo ""

# ─── 3. Git Configuration ───────────────────────────────────────────────────

echo "── Git Configuration ─────────────────────────────────────────"
GIT_FILES=(
    ".gitconfig"
    ".gitignore_global"
    ".gitmessage"
)
git_count=0
for f in "${GIT_FILES[@]}"; do
    if backup_file "$HOME/$f" "$BACKUP_DIR/git"; then
        log "Backed up $f"
        git_count=$((git_count + 1))
    fi
done
if [ "$git_count" -eq 0 ]; then
    fail "No Git configuration files found"
fi
echo ""

# ─── 4. Package Managers ────────────────────────────────────────────────────

echo "── Package Managers ──────────────────────────────────────────"

# Homebrew
if command -v brew &> /dev/null; then
    mkdir -p "$BACKUP_DIR/homebrew"
    brew list --formula > "$BACKUP_DIR/homebrew/formulae.txt" 2>/dev/null || true
    brew list --cask > "$BACKUP_DIR/homebrew/casks.txt" 2>/dev/null || true
    brew tap > "$BACKUP_DIR/homebrew/taps.txt" 2>/dev/null || true
    brew services list > "$BACKUP_DIR/homebrew/services.txt" 2>/dev/null || true
    log "Homebrew formulae, casks, taps, and services list saved"
else
    fail "Homebrew not installed"
fi

# npm global packages
if command -v npm &> /dev/null; then
    mkdir -p "$BACKUP_DIR/node"
    npm list -g --depth=0 > "$BACKUP_DIR/node/npm_global_packages.txt" 2>/dev/null || true
    log "npm global packages list saved"
fi
if backup_file "$HOME/.npmrc" "$BACKUP_DIR/node"; then
    log "Backed up .npmrc"
fi

# yarn
if command -v yarn &> /dev/null; then
    mkdir -p "$BACKUP_DIR/node"
    yarn global list > "$BACKUP_DIR/node/yarn_global_packages.txt" 2>/dev/null || true
    log "Yarn global packages list saved"
fi

# pnpm
if command -v pnpm &> /dev/null; then
    mkdir -p "$BACKUP_DIR/node"
    pnpm list -g > "$BACKUP_DIR/node/pnpm_global_packages.txt" 2>/dev/null || true
    log "pnpm global packages list saved"
fi

# nvm
if [ -d "$HOME/.nvm" ]; then
    mkdir -p "$BACKUP_DIR/node"
    if command -v nvm &> /dev/null || [ -s "$HOME/.nvm/nvm.sh" ]; then
        # shellcheck disable=SC1091
        [ -s "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh"
        nvm list > "$BACKUP_DIR/node/nvm_versions.txt" 2>/dev/null || true
        log "nvm Node.js versions list saved"
    fi
fi

# pip / Python
if command -v pip3 &> /dev/null; then
    mkdir -p "$BACKUP_DIR/python"
    pip3 list --format=freeze > "$BACKUP_DIR/python/pip3_packages.txt" 2>/dev/null || true
    log "pip3 packages list saved"
fi
if command -v conda &> /dev/null; then
    mkdir -p "$BACKUP_DIR/python"
    conda list --export > "$BACKUP_DIR/python/conda_packages.txt" 2>/dev/null || true
    conda env list > "$BACKUP_DIR/python/conda_envs.txt" 2>/dev/null || true
    log "Conda environments and packages list saved"
fi

# Ruby gems
if command -v gem &> /dev/null; then
    mkdir -p "$BACKUP_DIR/ruby"
    gem list > "$BACKUP_DIR/ruby/gem_list.txt" 2>/dev/null || true
    log "Ruby gems list saved"
fi

# Go
if command -v go &> /dev/null; then
    mkdir -p "$BACKUP_DIR/go"
    go version > "$BACKUP_DIR/go/go_version.txt" 2>/dev/null || true
    log "Go version saved"
fi

# Rust / Cargo
if command -v cargo &> /dev/null; then
    mkdir -p "$BACKUP_DIR/rust"
    cargo install --list > "$BACKUP_DIR/rust/cargo_packages.txt" 2>/dev/null || true
    log "Cargo installed packages list saved"
fi

# Composer (PHP)
if command -v composer &> /dev/null; then
    mkdir -p "$BACKUP_DIR/php"
    composer global show > "$BACKUP_DIR/php/composer_global.txt" 2>/dev/null || true
    log "Composer global packages list saved"
fi

echo ""

# ─── 5. Editor / IDE Settings ───────────────────────────────────────────────

echo "── Editor / IDE Settings ─────────────────────────────────────"

# VS Code
VSCODE_USER="$HOME/Library/Application Support/Code/User"
if [ -d "$VSCODE_USER" ]; then
    mkdir -p "$BACKUP_DIR/vscode"
    backup_file "$VSCODE_USER/settings.json" "$BACKUP_DIR/vscode"
    backup_file "$VSCODE_USER/keybindings.json" "$BACKUP_DIR/vscode"
    if [ -d "$VSCODE_USER/snippets" ]; then
        backup_dir "$VSCODE_USER/snippets" "$BACKUP_DIR/vscode"
    fi
    if command -v code &> /dev/null; then
        code --list-extensions > "$BACKUP_DIR/vscode/extensions_list.txt" 2>/dev/null || true
        log "VS Code extensions list saved"
    fi
    log "VS Code settings, keybindings, and snippets backed up"
else
    fail "VS Code user settings not found"
fi

# Cursor (VS Code fork)
CURSOR_USER="$HOME/Library/Application Support/Cursor/User"
if [ -d "$CURSOR_USER" ]; then
    mkdir -p "$BACKUP_DIR/cursor"
    backup_file "$CURSOR_USER/settings.json" "$BACKUP_DIR/cursor"
    backup_file "$CURSOR_USER/keybindings.json" "$BACKUP_DIR/cursor"
    log "Cursor editor settings backed up"
fi

# Vim / Neovim
if backup_file "$HOME/.vimrc" "$BACKUP_DIR/vim"; then
    log "Backed up .vimrc"
fi
if [ -d "$HOME/.config/nvim" ]; then
    backup_dir "$HOME/.config/nvim" "$BACKUP_DIR/neovim"
    log "Neovim config backed up"
fi

# JetBrains IDEs (settings are per-version, back up any found)
JETBRAINS_DIR="$HOME/Library/Application Support/JetBrains"
if [ -d "$JETBRAINS_DIR" ]; then
    mkdir -p "$BACKUP_DIR/jetbrains"
    # Copy options directories from each IDE version found
    for ide_dir in "$JETBRAINS_DIR"/*/; do
        ide_name=$(basename "$ide_dir")
        if [ -d "$ide_dir/options" ]; then
            mkdir -p "$BACKUP_DIR/jetbrains/$ide_name"
            cp -r "$ide_dir/options" "$BACKUP_DIR/jetbrains/$ide_name/"
        fi
    done
    log "JetBrains IDE settings backed up"
fi

# Sublime Text
SUBLIME_DIR="$HOME/Library/Application Support/Sublime Text/Packages/User"
if [ -d "$SUBLIME_DIR" ]; then
    backup_dir "$SUBLIME_DIR" "$BACKUP_DIR/sublime-text"
    log "Sublime Text settings backed up"
fi

echo ""

# ─── 6. Database & API Client Configs ───────────────────────────────────────

echo "── Database & API Client Configs ─────────────────────────────"

# TablePlus
TABLEPLUS_DIR="$HOME/Library/Application Support/com.tinyapp.TablePlus"
if [ -d "$TABLEPLUS_DIR" ]; then
    backup_dir "$TABLEPLUS_DIR" "$BACKUP_DIR/tableplus"
    log "TablePlus connections and settings backed up"
else
    fail "TablePlus data not found"
fi

# Sequel Pro / Sequel Ace
SEQUEL_PRO_PLIST="$HOME/Library/Preferences/com.sequelpro.SequelPro.plist"
SEQUEL_ACE_DIR="$HOME/Library/Containers/com.sequel-ace.sequel-ace"
if [ -f "$SEQUEL_PRO_PLIST" ]; then
    backup_file "$SEQUEL_PRO_PLIST" "$BACKUP_DIR/sequel-pro"
    log "Sequel Pro preferences backed up"
fi
if [ -d "$SEQUEL_ACE_DIR" ]; then
    backup_dir "$SEQUEL_ACE_DIR" "$BACKUP_DIR/sequel-ace"
    log "Sequel Ace data backed up"
fi

# Postman
POSTMAN_DIR="$HOME/Library/Application Support/Postman"
if [ -d "$POSTMAN_DIR" ]; then
    info "Postman detected — make sure your collections are synced to your Postman account"
fi

# Insomnia
INSOMNIA_DIR="$HOME/Library/Application Support/Insomnia"
if [ -d "$INSOMNIA_DIR" ]; then
    backup_dir "$INSOMNIA_DIR" "$BACKUP_DIR/insomnia"
    log "Insomnia settings backed up"
fi

# DBeaver
DBEAVER_DIR="$HOME/Library/DBeaverData"
if [ -d "$DBEAVER_DIR" ]; then
    backup_dir "$DBEAVER_DIR" "$BACKUP_DIR/dbeaver"
    log "DBeaver connections and settings backed up"
fi

echo ""

# ─── 7. Terminal App Configs ─────────────────────────────────────────────────

echo "── Terminal App Configs ─────────────────────────────────────"

# Termius (synced via account, but note it)
TERMIUS_DIR="$HOME/Library/Application Support/Termius"
if [ -d "$TERMIUS_DIR" ]; then
    info "Termius detected — verify your connections are synced to your Termius account"
fi

# iTerm2
ITERM_PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
if [ -f "$ITERM_PLIST" ]; then
    backup_file "$ITERM_PLIST" "$BACKUP_DIR/iterm2"
    log "iTerm2 preferences backed up"
fi

# Hyper
if backup_file "$HOME/.hyper.js" "$BACKUP_DIR/hyper"; then
    log "Hyper terminal config backed up"
fi

# Warp
WARP_DIR="$HOME/.warp"
if [ -d "$WARP_DIR" ]; then
    backup_dir "$WARP_DIR" "$BACKUP_DIR/warp"
    log "Warp terminal config backed up"
fi

# tmux
if backup_file "$HOME/.tmux.conf" "$BACKUP_DIR/tmux"; then
    log "tmux config backed up"
fi

echo ""

# ─── 8. Docker ───────────────────────────────────────────────────────────────

echo "── Docker ────────────────────────────────────────────────────"
if [ -d "$HOME/.docker" ]; then
    backup_dir "$HOME/.docker" "$BACKUP_DIR/docker"
    log "Docker config backed up (~/.docker)"
fi
if command -v docker &> /dev/null; then
    mkdir -p "$BACKUP_DIR/docker"
    docker image ls > "$BACKUP_DIR/docker/images.txt" 2>/dev/null || true
    docker container ls -a > "$BACKUP_DIR/docker/containers.txt" 2>/dev/null || true
    docker volume ls > "$BACKUP_DIR/docker/volumes.txt" 2>/dev/null || true
    log "Docker images, containers, and volumes list saved"
fi
echo ""

# ─── 9. Kubernetes ───────────────────────────────────────────────────────────

echo "── Kubernetes ────────────────────────────────────────────────"
if [ -d "$HOME/.kube" ]; then
    backup_dir "$HOME/.kube" "$BACKUP_DIR/kube"
    log "Kubernetes config backed up (~/.kube)"
fi
echo ""

# ─── 10. Cloud CLI Configs ───────────────────────────────────────────────────

echo "── Cloud CLI Configs ─────────────────────────────────────────"

# AWS
if [ -d "$HOME/.aws" ]; then
    backup_dir "$HOME/.aws" "$BACKUP_DIR/aws"
    log "AWS CLI config backed up (~/.aws)"
fi

# GCP
GCLOUD_DIR="$HOME/.config/gcloud"
if [ -d "$GCLOUD_DIR" ]; then
    backup_dir "$GCLOUD_DIR" "$BACKUP_DIR/gcloud"
    log "Google Cloud SDK config backed up"
fi

# Azure
if [ -d "$HOME/.azure" ]; then
    backup_dir "$HOME/.azure" "$BACKUP_DIR/azure"
    log "Azure CLI config backed up"
fi

# Vercel
if backup_file "$HOME/.vercel/config.json" "$BACKUP_DIR/vercel"; then
    log "Vercel CLI config backed up"
fi

# Netlify
if backup_file "$HOME/.netlify/config.json" "$BACKUP_DIR/netlify"; then
    log "Netlify CLI config backed up"
fi

echo ""

# ─── 11. macOS Preferences & System Info ─────────────────────────────────────

echo "── macOS System Info ─────────────────────────────────────────"
mkdir -p "$BACKUP_DIR/system"

# Installed applications list
if [ -d "/Applications" ]; then
    ls /Applications > "$BACKUP_DIR/system/installed_apps.txt" 2>/dev/null || true
    log "Installed applications list saved"
fi

# macOS version
if sw_vers > "$BACKUP_DIR/system/macos_version.txt" 2>/dev/null; then
    log "macOS version info saved"
fi

# Mac App Store apps (if mas is installed)
if command -v mas &> /dev/null; then
    mas list > "$BACKUP_DIR/system/mas_apps.txt" 2>/dev/null || true
    log "Mac App Store apps list saved"
fi

echo ""

# ─── 12. Misc Developer Configs ─────────────────────────────────────────────

echo "── Miscellaneous Developer Configs ───────────────────────────"

# GPG keys
if command -v gpg &> /dev/null; then
    mkdir -p "$BACKUP_DIR/gpg"
    gpg --list-keys > "$BACKUP_DIR/gpg/public_keys.txt" 2>/dev/null || true
    gpg --export --armor > "$BACKUP_DIR/gpg/public_keys.asc" 2>/dev/null || true
    gpg --export-secret-keys --armor > "$BACKUP_DIR/gpg/private_keys.asc" 2>/dev/null || true
    log "GPG keys exported"
fi

# Env files (.env patterns in common locations)
if backup_file "$HOME/.env" "$BACKUP_DIR/env"; then
    log "Backed up ~/.env"
fi

# Starship prompt
if backup_file "$HOME/.config/starship.toml" "$BACKUP_DIR/starship"; then
    log "Starship prompt config backed up"
fi

# Oh My Zsh custom directory
if [ -d "$HOME/.oh-my-zsh/custom" ]; then
    backup_dir "$HOME/.oh-my-zsh/custom" "$BACKUP_DIR/oh-my-zsh"
    log "Oh My Zsh custom plugins and themes backed up"
fi

echo ""

# ─── Create ZIP Archive ─────────────────────────────────────────────────────

echo "── Creating Archive ──────────────────────────────────────────"

cd "$BACKUP_DEST"
zip -r -q "${BACKUP_NAME}.zip" "$BACKUP_NAME"

ZIP_SIZE=$(du -sh "${BACKUP_NAME}.zip" | cut -f1)
log "Archive created: ${BACKUP_NAME}.zip ($ZIP_SIZE)"

# Clean up unzipped directory
rm -rf "$BACKUP_NAME"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    Backup Complete!                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo -e "  ${GREEN}📦 Archive:${NC} $BACKUP_DEST/${BACKUP_NAME}.zip"
echo -e "  ${GREEN}📏 Size:${NC}    $ZIP_SIZE"
echo ""
echo "  Next steps:"
echo "    1. Copy this ZIP to an external drive or cloud storage"
echo "    2. Verify the ZIP contents: unzip -l ${BACKUP_NAME}.zip"
echo "    3. Run backup-projects-dry-run.sh to preview project backups"
echo ""
