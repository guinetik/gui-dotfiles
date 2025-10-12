# WSL Ubuntu Jammy Provisioning

Automated provisioning script for creating reproducible WSL Ubuntu Jammy environments with gui-dotfiles.

## Motivation

This script provides a fully automated, reproducible way to:

- **Test dotfiles changes** - Quickly spin up fresh Ubuntu instances to test your dotfiles configurations
- **Ensure idempotence** - Verify that installation scripts can run multiple times safely
- **Maintain consistency** - Create identical development environments across machines
- **Rapid iteration** - Nuke and recreate distros in minutes during development
- **Clean slate testing** - Start from a minimal Ubuntu Core image without cruft

Instead of manually configuring WSL distros and hoping scripts work, this approach lets you:
```powershell
# Destroy and recreate in one command
wsl --unregister UbuntuTest
.\wsl\run.ps1 -DistroName "UbuntuTest" -TargetDirectory "D:\linux\test-ubuntu"
```

## Prerequisites

- **Windows 11** or Windows 10 with WSL2 enabled
- **WSL installed**: Run `wsl --version` to verify
- **PowerShell 5.1+** (comes with Windows)
- **Internet connection** for downloading Ubuntu image and packages

### Install WSL (if needed)

```powershell
# Run as Administrator
wsl --install
```

Restart your computer after installation.

## Usage

### Basic Usage (with defaults)

```powershell
.\wsl\run.ps1 -DistroName "UbuntuTest" -TargetDirectory "D:\linux\test-ubuntu"
```

This creates:
- **User**: `guinetik`
- **Password**: `123`
- **Sudo**: NOPASSWD enabled (no password needed for sudo)

### Custom Username and Password

```powershell
.\wsl\run.ps1 `
  -DistroName "UbuntuDev" `
  -TargetDirectory "D:\linux\dev-ubuntu" `
  -UserName "myuser" `
  -UserPassword "mypassword"
```

### All Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `DistroName` | ✅ Yes | - | Name for the WSL distro |
| `TargetDirectory` | ✅ Yes | - | Where to store the WSL filesystem |
| `UserName` | ❌ No | `guinetik` | Username to create in WSL |
| `UserPassword` | ❌ No | `123` | Password for the user |
| `ImageUrl` | ❌ No | Ubuntu Jammy Core | URL to Ubuntu cloud image |

## What the Script Does

The provisioning process follows these steps:

### 1. Download Ubuntu Jammy Core Image
- Downloads minimal Ubuntu 22.04 (Jammy) cloud image (~50MB)
- Saves to target directory for import

### 2. Create WSL Distro
- Imports the Ubuntu image as a new WSL distro
- Creates isolated filesystem in `<TargetDirectory>/rootfs`

### 3. Configure User (as root)
- Creates specified user with bash shell
- Adds user to sudo group
- Configures NOPASSWD sudo access
- Sets user password

### 4. Initialize System (as root)
- Updates apt package lists
- Installs essential packages:
  - `sudo`, `curl`, `wget`, `git`
  - `ca-certificates`, `dos2unix`
  - `locales` (fixes Perl warnings)
- Generates `en_US.UTF-8` locale
- Verifies all installations

### 5. Set Default User
- Creates `/etc/wsl.conf` with default user
- Enables systemd (for Docker, etc.)
- Restarts distro for changes to take effect
- Verifies sudo access works

### 6. Link Repository
- Creates symlink from Windows path to `~/gui-dotfiles` in WSL
- Enables direct editing from Windows while running in WSL

### 7. Convert Line Endings
- Runs `dos2unix` on all `.sh` files
- Ensures scripts run correctly in Linux environment

### 8. Run Installation
- Executes `distros/ubuntu/install.sh`
- Installs all configured tools and settings
- Creates installation tracking files

## Directory Structure

After provisioning, you'll have:

```
<TargetDirectory>/
├── rootfs/              # WSL filesystem (managed by WSL)
│   ├── home/
│   │   └── <username>/
│   │       └── gui-dotfiles -> (symlink to Windows path)
│   ├── etc/
│   └── ...
└── jammy-wsl.tar.gz     # Downloaded Ubuntu image (can be deleted)
```

Inside WSL:
```
~/gui-dotfiles/          # Symlinked to Windows repository
~/.local/share/gui-dotfiles/  # Installation tracking files
  ├── .installed         # Master tracking file
  ├── docker.info
  ├── zoxide.info
  └── ...
```

## Accessing Your Distro

### Default access
```powershell
wsl -d UbuntuTest
```

### Specific user
```powershell
wsl -d UbuntuTest -u guinetik
```

### Run a command
```powershell
wsl -d UbuntuTest bash -c "cd ~/gui-dotfiles && git status"
```

### Open in Windows Terminal
```powershell
wt -d UbuntuTest
```

## Troubleshooting

### ⚠️ "WSL is not installed"

**Problem**: WSL is not enabled on your system.

**Solution**:
```powershell
# Run as Administrator
wsl --install
# Restart computer
```

### ⚠️ "Distro already exists"

**Problem**: A distro with that name already exists.

**Solution**: The script will prompt to unregister. Or manually:
```powershell
wsl --unregister UbuntuTest
```

### ⚠️ "Failed to import WSL distro"

**Problem**:
- Not enough disk space
- Target directory is invalid
- Downloaded image is corrupted

**Solutions**:
1. Check available disk space
2. Delete the `.tar.gz` file and re-run
3. Try a different target directory
4. Verify download completed (should be ~50MB)

### ⚠️ "Sudo configuration failed"

**Problem**: User doesn't have NOPASSWD sudo access.

**Solution**: This should not happen with the script. If it does:
```bash
# Inside WSL as root
echo "guinetik ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/guinetik
sudo chmod 0440 /etc/sudoers.d/guinetik
```

### ⚠️ "Repository linked but files not visible"

**Problem**: Symlink path is incorrect.

**Solution**: Check the symlink inside WSL:
```bash
ls -la ~/gui-dotfiles
# Should show: gui-dotfiles -> /mnt/d/Developer/gui-dotfiles
```

If broken, recreate:
```bash
ln -sf /mnt/d/Developer/gui-dotfiles ~/gui-dotfiles
```

### ⚠️ Scripts fail with "bad interpreter" or "/r" errors

**Problem**: Windows line endings (CRLF) instead of Unix (LF).

**Solution**: The script runs `dos2unix` automatically. If you still see issues:
```bash
cd ~/gui-dotfiles
find . -type f -name "*.sh" -exec dos2unix {} \;
```

### ⚠️ Installation scripts fail with "sudo: a password is required"

**Problem**: Some installers prompt for password even with NOPASSWD sudo.

**Solution**: The user password is set (default: `123`). Enter it when prompted:
```bash
# When prompted for password
Password: 123
```

Or pass a custom password to the script:
```powershell
.\wsl\run.ps1 -DistroName "Test" -TargetDirectory "D:\test" -UserPassword "mysecurepass"
```

### ⚠️ "apt-get: command not found" or similar

**Problem**: Essential tools not installed during system initialization.

**Solution**: Re-run as root inside WSL:
```bash
# Access distro as root
wsl -d UbuntuTest -u root

# Update and install essentials
apt-get update
apt-get install -y sudo curl wget git dos2unix locales
```

### ⚠️ Docker asks for password despite NOPASSWD

**Problem**: Docker installer may explicitly request password.

**Solution**: This is expected behavior for some installers. Use the password you set:
- Default: `123`
- Custom: Whatever you passed to `-UserPassword`

### ⚠️ "Perl: warning: locale" errors

**Problem**: Locale not properly configured.

**Solution**: The script generates locales automatically. If you still see warnings:
```bash
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8
```

Restart your WSL session after this.

### ⚠️ Windows sudo.exe interferes with Linux sudo

**Problem**: If you have Windows sudo (Scoop/Chocolatey) in PATH, it may conflict.

**Solution**:
1. Remove Windows sudo from PATH temporarily
2. Or the scripts use `/usr/bin/sudo` explicitly to avoid this

## Tips and Best Practices

### 🚀 Rapid Testing Workflow

```powershell
# 1. Make changes to your dotfiles
git commit -am "Test new configuration"

# 2. Nuke existing test distro
wsl --unregister UbuntuTest

# 3. Recreate from scratch
.\wsl\run.ps1 -DistroName "UbuntuTest" -TargetDirectory "D:\linux\test-ubuntu"

# 4. Test your changes
wsl -d UbuntuTest
```

### 📦 Multiple Test Environments

Create separate distros for different purposes:

```powershell
# Minimal test
.\wsl\run.ps1 -DistroName "UbuntuMinimal" -TargetDirectory "D:\linux\minimal"

# Full development environment
.\wsl\run.ps1 -DistroName "UbuntuDev" -TargetDirectory "D:\linux\dev"

# Production-like setup
.\wsl\run.ps1 -DistroName "UbuntuProd" -TargetDirectory "E:\linux\prod"
```

List all distros:
```powershell
wsl -l -v
```

### 🗑️ Clean Up Old Distros

```powershell
# Remove a distro
wsl --unregister UbuntuTest

# Remove distro and delete files
wsl --unregister UbuntuTest
Remove-Item -Recurse -Force "D:\linux\test-ubuntu"
```

### 💾 Backup a Working Distro

```powershell
# Export to tar file
wsl --export UbuntuDev D:\backups\ubuntu-dev-backup.tar

# Restore later
wsl --import UbuntuDev D:\linux\dev-restored D:\backups\ubuntu-dev-backup.tar
```

### 🔍 Debugging Installation Issues

If an installation step fails, you can manually enter the distro and debug:

```powershell
# Enter as your user
wsl -d UbuntuTest

# Enter as root
wsl -d UbuntuTest -u root
```

Check installation logs:
```bash
# View tracking files
cat ~/.local/share/gui-dotfiles/.installed

# Check which tools are tracked
ls ~/.local/share/gui-dotfiles/
```

Manually run specific installation scripts:
```bash
cd ~/gui-dotfiles/common
./install_zoxide.sh
./install_starship.sh
```

### 🌐 Network Issues

If downloads fail due to network issues, you can:

1. **Download image manually**:
   - Download from: https://partner-images.canonical.com/core/jammy/
   - Place in target directory as `jammy-wsl.tar.gz`
   - Re-run script (it will skip download if file exists)

2. **Use corporate proxy**:
   ```powershell
   # Set proxy before running
   $env:HTTP_PROXY="http://proxy.corp.com:8080"
   $env:HTTPS_PROXY="http://proxy.corp.com:8080"
   .\wsl\run.ps1 ...
   ```

### 🎯 Skip Installation

If you only want to set up the distro without running the full installation:

When prompted with:
```
Continue with installation? (Y/n)
```

Answer `n` to skip. You can run it manually later:
```bash
wsl -d UbuntuTest
cd ~/gui-dotfiles/distros/ubuntu
./install.sh
```

## Environment Variables

The installation scripts support these environment variables:

- `YOLO_MODE=true` - Auto-answer "yes" to all prompts
- `INSTALL_TRACKER_DIR` - Custom location for tracking files
- `PATH` - Automatically updated with `~/.local/bin`, `~/.cargo/bin`, etc.

## Related Documentation

- [Main README](../README.md) - Overview of gui-dotfiles
- [Ubuntu Install Script](../distros/ubuntu/README.md) - Ubuntu-specific setup
- [Common Scripts](../common/README.md) - Shared installation scripts

## Contributing

When modifying provisioning scripts:

1. **Test with fresh distro**: Always test by nuking and recreating
2. **Check idempotence**: Run scripts twice to ensure they handle re-runs
3. **Use tracking system**: Leverage `is_app_installed()` and tracking files
4. **Document changes**: Update this README with any new features or gotchas

## License

Same as gui-dotfiles repository.
