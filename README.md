# 🚀 Missile Your macOS

> The complete guide to safely back up everything and erase all content & settings on macOS — built for software engineers.

Wiping your Mac should be stress-free. This toolkit ensures you don't lose SSH keys, configs, database connections, projects, or any developer tool settings before you hit "Erase All Content and Settings."

---

## Table of Contents

- [Install via Homebrew](#install-via-homebrew)
- [Overview](#overview)
- [mym CLI Reference](#mym-cli-reference)
- [Before You Start — The Checklist](#before-you-start--the-checklist)
- [Phase 1: Backup Developer Configuration](#phase-1-backup-developer-configuration)
- [Phase 2: Backup Projects](#phase-2-backup-projects)
- [Pre-Erase Sign-Out Guide](#pre-erase-sign-out-guide)
- [Erasing macOS](#erasing-macos)
- [After the Reset — Restore Guide](#after-the-reset--restore-guide)
- [Publishing to Homebrew](#publishing-to-homebrew)

---

## Install via Homebrew

The easiest way to get started on any Mac:

```bash
brew tap YoWWW3/missile-your-macos
brew install mym
```

Then run `mym --help` to see all commands.

> **Don't have Homebrew?**  Install it first:
> ```bash
> /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
> ```

### Manual install (no Homebrew)

```bash
git clone https://github.com/YoWWW3/missile-your-macos.git
cd missile-your-macos
chmod +x bin/mym backup-config.sh backup-projects-dry-run.sh backup-projects-execute.sh

# Optional: put mym on your PATH
sudo ln -sf "$PWD/bin/mym" /usr/local/bin/mym
```

---

## Overview

This repository provides a unified `mym` CLI and three underlying shell scripts:

| Command / Script | Purpose |
|-----------------|---------|
| `mym` | Unified CLI — run `config`, `dry-run`, or `execute` with one command |
| `backup-config.sh` | Backs up all developer configs (SSH, Git, editors, DBs, cloud CLIs, etc.) into a single ZIP |
| `backup-projects-dry-run.sh` | Previews which Git projects will be archived (no changes made) |
| `backup-projects-execute.sh` | Archives each Git project to ZIP and moves originals to Trash |

---

## mym CLI Reference

```
mym <command> [options] [arguments]
```

### Commands

| Command | Argument | Description |
|---------|----------|-------------|
| `config` | `[dest]` | Back up all developer configs to a timestamped ZIP. Default destination: `~/Desktop` |
| `dry-run` | `[dir]` | Preview which Git projects will be archived. Default: current directory |
| `execute` | `[dir]` | Archive Git projects to ZIP, move originals to Trash. Default: current directory |

### Options

| Flag | Description |
|------|-------------|
| `-h`, `--help` | Show help and exit |
| `-v`, `--version` | Show version and exit |
| `--no-color` | Disable colored output (also honored via `$NO_COLOR` env var) |

### Examples

```bash
mym --help                           # Show usage
mym --version                        # Show version

mym config                           # Backup configs → ~/Desktop
mym config /Volumes/ExternalDrive    # Backup configs → external drive

mym dry-run                          # Preview project backups in current directory
mym dry-run ~/Projects               # Preview project backups in ~/Projects

mym execute                          # Archive projects in current directory
mym execute ~/Projects               # Archive projects in ~/Projects
```

---

## Before You Start — The Checklist

Before erasing your Mac, verify **every item** on this list:

### 🔑 Accounts & Authentication

- [ ] **iCloud** — Verify all data is synced (Photos, Documents, Contacts, Calendars, Notes, Keychain)
- [ ] **Apple ID** — Confirm you know your Apple ID email and password
- [ ] **Two-Factor Authentication** — Ensure you have a backup method (phone number, another device, or recovery key)
- [ ] **iMessage / FaceTime** — Note your registered phone numbers
- [ ] **App Store purchases** — These are tied to your Apple ID and will be available after sign-in

### 💾 Data Backup

- [ ] **Time Machine** — Run a full backup to an external drive (Settings → General → Time Machine)
- [ ] **Documents & Desktop** — If not using iCloud Drive, manually copy these folders
- [ ] **Downloads folder** — Check for important files
- [ ] **Photos** — Verify iCloud Photos is enabled, or export your library
- [ ] **Music** — Sync your iTunes/Apple Music library or verify streaming status
- [ ] **Browser data** — Export bookmarks and check saved passwords
  - Safari: bookmarks sync via iCloud
  - Chrome: sign in to sync
  - Firefox: sign in to sync
- [ ] **Email** — Ensure your email uses IMAP (not POP3), so messages stay on the server
- [ ] **Notes** — Verify they're synced to iCloud (not stored locally as "On My Mac")
- [ ] **Contacts & Calendars** — Verify iCloud sync is on

### 🛠️ Developer-Specific Backup

- [ ] **Run `backup-config.sh`** — SSH keys, shell configs, editor settings, package lists
- [ ] **Run `backup-projects-dry-run.sh`** — Preview project archives
- [ ] **Run `backup-projects-execute.sh`** — Archive all projects
- [ ] **Git repositories** — Verify all important branches are pushed to remote
- [ ] **Database exports** — Export databases that are not in the cloud
  - MySQL: `mysqldump --all-databases > all_databases.sql`
  - PostgreSQL: `pg_dumpall > all_databases.sql`
  - MongoDB: `mongodump --out ./mongo_backup`
  - Redis: Copy the `dump.rdb` file
- [ ] **Docker** — Export important containers and images if needed
  - `docker save -o image_backup.tar <image_name>`
- [ ] **Environment variables / secrets** — Check `.env` files across projects
- [ ] **API keys & tokens** — Document any that aren't stored in a password manager
- [ ] **License keys** — Note licenses for paid apps (TablePlus, JetBrains, Sublime Text, etc.)

### 📱 Apps to Check

| App | Backup Method |
|-----|--------------|
| **TablePlus** | Backed up automatically by `backup-config.sh`. Also: File → Export Connections |
| **Termius** | Synced via Termius account. Verify you're signed in and synced |
| **VS Code** | Settings Sync (sign in with GitHub). Extensions list saved by `backup-config.sh` |
| **iTerm2** | Preferences backed up by `backup-config.sh` |
| **Postman** | Synced via Postman account. Verify workspace is synced |
| **Slack** | All data is in the cloud. Just sign in again |
| **Docker Desktop** | Re-install after reset. Export critical images first |
| **1Password / Bitwarden** | Cloud-synced. Verify you have your master password |
| **Figma** | Cloud-based. Nothing to back up locally |

---

## Phase 1: Backup Developer Configuration

The `backup-config.sh` script backs up all developer-relevant configuration files into a single ZIP archive.

### What Gets Backed Up

| Category | Items |
|----------|-------|
| SSH | `~/.ssh` (keys, config, known_hosts) |
| Shell | `.zshrc`, `.bashrc`, `.bash_profile`, `.profile`, `.aliases`, and more |
| Git | `.gitconfig`, `.gitignore_global`, `.gitmessage` |
| Homebrew | Formulae, casks, taps, and services lists |
| Node.js | npm/yarn/pnpm global packages, nvm versions, `.npmrc` |
| Python | pip3 packages, conda environments |
| Ruby | Gem list |
| Go | Version info |
| Rust | Cargo installed packages |
| PHP | Composer global packages |
| VS Code | `settings.json`, `keybindings.json`, snippets, extensions list |
| Cursor | Settings and keybindings |
| Vim/Neovim | `.vimrc`, `~/.config/nvim` |
| JetBrains | IDE settings (options directory) |
| Sublime Text | User packages and preferences |
| TablePlus | Connections and settings |
| iTerm2 | Preferences plist |
| Warp | Terminal config |
| Docker | Docker config, images/containers/volumes list |
| Kubernetes | `~/.kube` config |
| Cloud CLIs | AWS, GCP, Azure configs |
| GPG | Public and private keys |
| System | Installed apps list, macOS version, Mac App Store apps |

### Usage

```bash
# Save backup to Desktop (default)
chmod +x backup-config.sh
./backup-config.sh

# Save backup to a specific directory
./backup-config.sh /Volumes/ExternalDrive/backups
```

The script creates a timestamped ZIP file (e.g., `mac_dev_backup_20250115_143022.zip`) at the specified location.

---

## Phase 2: Backup Projects

### Step 1: Dry Run (Preview)

The dry run script scans a directory for Git repositories and shows what will be archived — without making any changes.

```bash
chmod +x backup-projects-dry-run.sh

# Scan the current directory
./backup-projects-dry-run.sh

# Scan a specific directory
./backup-projects-dry-run.sh ~/Projects
```

**Output includes:**
- Project name and path
- Current Git branch
- Uncommitted changes and untracked files
- Estimated size (excluding `node_modules`, build artifacts)
- Target ZIP filename

### Step 2: Execute Backup

The execute script creates ZIP archives and moves originals to macOS Trash.

```bash
chmod +x backup-projects-execute.sh

# Back up projects in the current directory
./backup-projects-execute.sh

# Back up projects in a specific directory
./backup-projects-execute.sh ~/Projects
```

**Safety features:**
- Asks for confirmation before proceeding
- Excludes `node_modules`, `.next`, `dist`, `build`, `vendor`, `__pycache__`, `.gradle`, `target`
- Verifies each ZIP archive is valid before removing the original
- Moves originals to macOS Trash (not permanent delete) — you can recover them
- Creates a log file for audit

---

## Pre-Erase Sign-Out Guide

**Sign out of these services in order before erasing:**

### 1. Deauthorize Apps

- [ ] **iTunes/Music** — Account → Authorizations → Deauthorize This Computer
- [ ] **Adobe Creative Cloud** — Sign out from the app
- [ ] **JetBrains IDEs** — Help → Register → Deactivate license
- [ ] **Microsoft Office** — Sign out from any Office app
- [ ] **Any app with a device limit** — Deactivate on this machine

### 2. Sign Out of Accounts

- [ ] **iMessage** — Messages → Settings → iMessage → Sign Out
- [ ] **FaceTime** — FaceTime → Settings → Sign Out
- [ ] **iCloud** — System Settings → Apple ID → Sign Out
  - When prompted, choose whether to keep a copy of iCloud data on this Mac (not needed if erasing)
  - This also disables Find My Mac
- [ ] **App Store** — Store → Sign Out (from menu bar)
- [ ] **Music/TV/Podcasts** — Account → Sign Out (from each app)

### 3. Unpair Devices

- [ ] **Bluetooth devices** — System Settings → Bluetooth → Unpair devices you want to use with another Mac
- [ ] **Apple Watch** — If paired, unpair before erasing

### 4. Reset NVRAM (Intel Macs Only)

For Intel-based Macs, reset NVRAM after erasing:
- Shut down → Turn on → Immediately hold `Option + Command + P + R` for 20 seconds

> **Note:** Apple Silicon Macs (M1/M2/M3/M4) handle this automatically during the erase process.

---

## Erasing macOS

### For macOS Ventura or Later (Recommended)

1. Go to **System Settings → General → Transfer or Reset → Erase All Content and Settings**
2. Enter your administrator password
3. Review what will be removed, then click **Continue**
4. Sign out of your Apple ID if you haven't already
5. Click **Erase All Content & Settings** to confirm
6. Your Mac will restart and begin the erase process

### For macOS Monterey

1. Go to **System Preferences → Erase All Content and Settings** (in menu bar)
2. Follow the prompts

### For Older macOS Versions

1. Restart in Recovery Mode:
   - **Apple Silicon:** Hold power button until "Loading startup options" appears
   - **Intel:** Hold `Command + R` during startup
2. Open **Disk Utility** → Select your startup disk → Click **Erase**
3. Format as **APFS** → Click **Erase**
4. Close Disk Utility → Select **Reinstall macOS**

---

## After the Reset — Restore Guide

After macOS is reinstalled, restore your setup:

### 1. Initial Setup

- Sign in with your Apple ID
- Enable iCloud services
- Install Xcode Command Line Tools: `xcode-select --install`

### 2. Install Homebrew & Packages

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Restore taps
xargs brew tap < ~/path-to-backup/homebrew/taps.txt

# Restore formulae
xargs brew install < ~/path-to-backup/homebrew/formulae.txt

# Restore casks
xargs brew install --cask < ~/path-to-backup/homebrew/casks.txt
```

### 3. Restore Developer Configs

```bash
# Unzip your config backup
unzip mac_dev_backup_XXXXXXXX.zip

# Restore SSH keys
cp -r ssh/.ssh ~/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_*
chmod 644 ~/.ssh/*.pub

# Restore shell config
cp shell/.zshrc ~/

# Restore Git config
cp git/.gitconfig ~/
```

### 4. Restore VS Code

```bash
# Install extensions from list
cat vscode/extensions_list.txt | xargs -L 1 code --install-extension

# Copy settings
cp vscode/settings.json ~/Library/Application\ Support/Code/User/
cp vscode/keybindings.json ~/Library/Application\ Support/Code/User/
```

### 5. Restore Projects

Unzip your project backups to your working directory:

```bash
cd ~/Projects
unzip /path/to/project_backup_*.zip
```

---

## Tips

- **Always verify your backups** before erasing. Unzip and check the contents.
- **Use multiple backup locations** — external drive + cloud storage.
- **Take a screenshot** of your Homebrew services (`brew services list`) and installed apps for reference.
- **Export database data**, not just configurations. The scripts back up app settings, but your actual data (tables, records) needs separate export.
- **Keep your backup ZIP files** for at least a few weeks after the reset, in case you forgot something.

---

## Publishing to Homebrew

This section is for **maintainers** who want to publish `mym` to a Homebrew tap so users can install it with `brew install mym`.

### Step 1 — Create a GitHub Release

Tag and release the version:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Then go to **GitHub → Releases → Draft a new release**, select the tag, add release notes, and publish.

### Step 2 — Get the Tarball SHA256

GitHub automatically creates a source tarball for every release. Compute its hash:

```bash
curl -sL https://github.com/YoWWW3/missile-your-macos/archive/refs/tags/v1.0.0.tar.gz \
  | shasum -a 256
```

Copy the 64-character hash.

### Step 3 — Update the Formula

Edit `Formula/mym.rb` and replace the two placeholders:

```ruby
url "https://github.com/YoWWW3/missile-your-macos/archive/refs/tags/v1.0.0.tar.gz"
sha256 "REPLACE_WITH_ACTUAL_SHA256_OF_v1.0.0_TARBALL"   # ← paste the hash here
```

### Step 4 — Create a Homebrew Tap Repository

A Homebrew tap is just a public GitHub repository whose name starts with `homebrew-`.

```bash
# Create a new repo called homebrew-missile-your-macos on GitHub, then:
mkdir homebrew-missile-your-macos && cd homebrew-missile-your-macos
git init
mkdir Formula
cp /path/to/missile-your-macos/Formula/mym.rb Formula/mym.rb
git add .
git commit -m "Add mym formula v1.0.0"
git remote add origin https://github.com/YoWWW3/homebrew-missile-your-macos.git
git push -u origin main
```

### Step 5 — Verify the Formula Locally

Before publishing, test the formula on your Mac:

```bash
# Audit for style issues
brew audit --strict Formula/mym.rb

# Dry-run install (no network)
brew install --dry-run Formula/mym.rb

# Full local install
brew install --build-from-source Formula/mym.rb

# Run the built-in tests
brew test mym
```

### Step 6 — Install (End-User Flow)

Once the tap repository is live, anyone can install with:

```bash
brew tap YoWWW3/missile-your-macos
brew install mym
mym --help
```

### Updating to a New Version

1. Bump the version in `bin/mym` (`VERSION="1.x.x"`)
2. Tag and push the new release
3. Compute the new SHA256
4. Update `Formula/mym.rb` (`url`, `sha256`, `version`)
5. Commit and push the updated formula to the tap repository

---

## License

MIT
