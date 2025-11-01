# WSL Ubuntu Jammy Provisioning Script
# Creates a new WSL distro from Ubuntu Jammy image and provisions it with gui-dotfiles

param(
    [Parameter(Mandatory=$true)]
    [string]$DistroName,

    [Parameter(Mandatory=$true)]
    [string]$TargetDirectory,

    [Parameter(Mandatory=$false)]
    [string]$UserName = "guinetik",

    [Parameter(Mandatory=$false)]
    [string]$UserPassword = "123",

    [Parameter(Mandatory=$false)]
    [string]$ImageUrl = "https://partner-images.canonical.com/core/jammy/20230504/ubuntu-jammy-core-cloudimg-amd64-root.tar.gz"
)

# Color output functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Header {
    param([string]$Message)
    Write-Host "`n=== $Message ===`n" -ForegroundColor Magenta
}

# Check if WSL is installed
function Test-WSLInstalled {
    Write-Info "Checking if WSL is installed..."
    try {
        $wslVersion = wsl --version
        if ($LASTEXITCODE -eq 0) {
            Write-Success "WSL is installed"
            return $true
        }
    } catch {
        Write-Error "WSL is not installed. Please install WSL first:"
        Write-Info "Run: wsl --install"
        return $false
    }
    return $false
}

# Check if distro already exists
function Test-DistroExists {
    param([string]$Name)
    $distros = wsl -l -q
    return $distros -contains $Name
}

# Main script
Write-Header "WSL Ubuntu Jammy Provisioning"

# Verify WSL is installed
if (-not (Test-WSLInstalled)) {
    exit 1
}

# Check if distro already exists
if (Test-DistroExists -Name $DistroName) {
    Write-Warning "Distro '$DistroName' already exists!"
    $response = Read-Host "Do you want to unregister and recreate it? (y/N)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        Write-Info "Unregistering existing distro..."
        wsl --unregister $DistroName
        Write-Success "Distro unregistered"
    } else {
        Write-Error "Cannot proceed with existing distro. Exiting."
        exit 1
    }
}

# Create target directories
Write-Info "Setting up target directory: $TargetDirectory"
if (-not (Test-Path $TargetDirectory)) {
    New-Item -Path $TargetDirectory -ItemType Directory -Force | Out-Null
    Write-Success "Created directory: $TargetDirectory"
}

# Create rootfs subdirectory for WSL filesystem
$RootFsDirectory = Join-Path $TargetDirectory "rootfs"
if (-not (Test-Path $RootFsDirectory)) {
    New-Item -Path $RootFsDirectory -ItemType Directory -Force | Out-Null
    Write-Success "Created rootfs directory: $RootFsDirectory"
}

# Download Ubuntu Jammy image
$ImageFileName = "jammy-wsl.tar.gz"
$ImagePath = Join-Path $TargetDirectory $ImageFileName

# Check if image already exists
if (Test-Path $ImagePath) {
    $existingSize = (Get-Item $ImagePath).Length / 1MB
    Write-Info "Found existing image: $ImagePath"
    Write-Info "Existing image size: $([math]::Round($existingSize, 2)) MB"

    # Verify the file is not corrupted (minimum 20MB expected for compressed cloud image)
    if ($existingSize -gt 20) {
        Write-Success "Using cached image (skipping download)"
        $skipDownload = $true
    } else {
        Write-Warning "Existing image seems too small, will re-download"
        Remove-Item $ImagePath -Force
        $skipDownload = $false
    }
} else {
    $skipDownload = $false
}

# Download if needed
if (-not $skipDownload) {
    Write-Info "Downloading Ubuntu Jammy image from: $ImageUrl"
    Write-Info "Target: $ImagePath"

    try {
        # Use WebClient for download with progress
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($ImageUrl, $ImagePath)
        Write-Success "Image downloaded successfully"
    } catch {
        Write-Error "Failed to download image: $_"
        exit 1
    }

    # Verify download
    if (-not (Test-Path $ImagePath)) {
        Write-Error "Image file not found after download: $ImagePath"
        exit 1
    }

    $imageSize = (Get-Item $ImagePath).Length / 1MB
    Write-Info "Image size: $([math]::Round($imageSize, 2)) MB"
}

# Import WSL distro
Write-Header "Creating WSL Distro"
Write-Info "Distro Name: $DistroName"
Write-Info "Installing to: $RootFsDirectory"

try {
    wsl --import $DistroName $RootFsDirectory $ImagePath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to import WSL distro"
        exit 1
    }
    Write-Success "Distro '$DistroName' created successfully"
} catch {
    Write-Error "Failed to create distro: $_"
    exit 1
}

# Configure user in WSL
Write-Header "Configuring User"

Write-Info "Creating user '$UserName' with sudo privileges..."

# Create user setup script
$userSetupScript = @"
#!/bin/bash
set -e

# Create user $UserName
useradd -m -s /bin/bash $UserName

# Set up sudo privileges
usermod -aG sudo $UserName

# Create sudoers.d directory if it doesn't exist
mkdir -p /etc/sudoers.d

# Add sudoers configuration with NOPASSWD
echo "$UserName ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$UserName
chmod 0440 /etc/sudoers.d/$UserName

# Set password
echo "$UserName`:$UserPassword" | chpasswd

echo "User '$UserName' created with sudo privileges and password set"
"@

# Execute user setup in WSL (as root)
echo $userSetupScript | wsl -d $DistroName bash

Write-Success "User '$UserName' configured with password"

# Initialize Ubuntu system (BEFORE setting default user, so it runs as root)
Write-Header "Initializing Ubuntu System"

Write-Info "Setting up package management and basic utilities..."

$initCommand = @'
#!/bin/bash
set -e

echo "Creating required directories..."
mkdir -p /var/lib/apt/lists/partial
mkdir -p /var/cache/apt/archives/partial

echo "Updating package lists..."
apt-get update -qq

echo "Installing essential packages..."
apt-get install -y -qq sudo curl wget git ca-certificates dos2unix locales

echo "Verifying installations..."
command -v sudo >/dev/null 2>&1 || { echo "ERROR: sudo not installed"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "ERROR: curl not installed"; exit 1; }
command -v wget >/dev/null 2>&1 || { echo "ERROR: wget not installed"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "ERROR: git not installed"; exit 1; }
command -v dos2unix >/dev/null 2>&1 || { echo "ERROR: dos2unix not installed"; exit 1; }

echo "Generating locales..."
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

echo "Base system initialized successfully"
'@

# Execute as root (before default user is set)
echo $initCommand | wsl -d $DistroName bash
if ($LASTEXITCODE -ne 0) {
    Write-Error "System initialization failed!"
    exit 1
}
Write-Success "System initialized"

# Set default user
Write-Info "Setting default user to '$UserName'..."

# Create wsl.conf for default user
$wslConfScript = @"
#!/bin/bash
cat > /etc/wsl.conf <<'WSLCONF'
[user]
default=$UserName

[boot]
systemd=true
WSLCONF
echo "wsl.conf created"
"@

echo $wslConfScript | wsl -d $DistroName bash
Write-Success "Default user set to '$UserName'"

# Shutdown and restart distro for changes to take effect
Write-Info "Restarting distro to apply user configuration..."
wsl --terminate $DistroName
Start-Sleep -Seconds 2

# Verify sudo works for user
Write-Info "Verifying sudo configuration..."
$sudoTestResult = wsl -d $DistroName -u $UserName bash -c "sudo -n whoami 2>&1"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Sudo configuration failed! User '$UserName' cannot use sudo without password."
    Write-Error "Debug info: sudo test returned '$sudoTestResult' with exit code $LASTEXITCODE"
    exit 1
}

if ($sudoTestResult -ne "root") {
    Write-Error "Sudo configuration failed! Expected 'root' but got: '$sudoTestResult'"
    exit 1
}

Write-Success "Sudo configuration verified - user '$UserName' has NOPASSWD sudo access"

# Link repository to WSL home directory
Write-Header "Linking Repository"

# Find git repository root (works from any subdirectory)
$scriptDir = $PSScriptRoot
if (-not $scriptDir) {
    $scriptDir = $PWD.Path
}

# Navigate up to find .git directory
$repoPath = $scriptDir
while ($repoPath -and -not (Test-Path (Join-Path $repoPath ".git"))) {
    $parent = Split-Path -Parent $repoPath
    if ($parent -eq $repoPath) {
        # Reached filesystem root without finding .git
        Write-Error "Could not find git repository root. Are you inside gui-dotfiles?"
        exit 1
    }
    $repoPath = $parent
}

$repoPathWSL = $repoPath -replace '\\', '/' -replace 'C:', '/mnt/c' -replace 'D:', '/mnt/d' -replace 'E:', '/mnt/e'

Write-Info "Repository path: $repoPath"
Write-Info "WSL path: $repoPathWSL"

# Create symlink in WSL
$linkCommand = @"
#!/bin/bash
ln -sf '$repoPathWSL' ~/gui-dotfiles && echo 'Repository linked to ~/gui-dotfiles'
"@

echo $linkCommand | wsl -d $DistroName -u $UserName bash
Write-Success "Repository linked to ~/gui-dotfiles"

# Convert all shell scripts to Unix line endings
Write-Info "Converting all shell scripts to Unix line endings..."
$convertCommand = @'
#!/bin/bash
cd ~/gui-dotfiles || exit 1
echo "Converting line endings for all .sh files..."
find . -type f -name "*.sh" -exec dos2unix {} \; 2>&1

echo ""
echo "Checking install.sh shebang line:"
cd ~/gui-dotfiles/distros/ubuntu || exit 1
file install.sh
head -n 1 install.sh | od -c
echo ""
echo "Line ending conversion complete"
'@

echo $convertCommand | wsl -d $DistroName -u $UserName bash
Write-Success "All shell scripts converted to Unix format"

# Execute install.sh
Write-Header "Running Installation"

Write-Info "Executing gui-dotfiles installation script..."
Write-Warning "This will install all configured tools and settings."

$response = Read-Host "Continue with installation? (Y/n)"
if ($response -eq 'n' -or $response -eq 'N') {
    Write-Warning "Installation skipped. You can run it manually with:"
    Write-Info "wsl -d $DistroName -u $UserName bash -c 'cd ~/gui-dotfiles && ./install.sh'"
    exit 0
}

# Run install.sh from repository root
Write-Info "Starting installation in WSL..."
Write-Info "Making install.sh executable..."
wsl -d $DistroName -u $UserName bash -c "chmod +x ~/gui-dotfiles/install.sh"

Write-Info "Executing install.sh from repository root..."
Write-Info "Note: Interactive prompts will appear below"
Write-Host ""

# Run install.sh - use wsl without -c to preserve stdin for interactive prompts
wsl -d $DistroName -u $UserName --cd ~/gui-dotfiles bash ./install.sh

if ($LASTEXITCODE -ne 0) {
    Write-Warning "Installation script exited with code $LASTEXITCODE"
}

# Completion summary
Write-Header "Provisioning Complete!"
Write-Success "WSL distro '$DistroName' is ready!"
Write-Host ""
Write-Info "Summary:"
Write-Host "  Distro Name:    $DistroName" -ForegroundColor White
Write-Host "  Location:       $TargetDirectory" -ForegroundColor White
Write-Host "  User:           $UserName (default)" -ForegroundColor White
Write-Host "  Password:       $UserPassword" -ForegroundColor White
Write-Host "  Repository:     ~/gui-dotfiles" -ForegroundColor White
Write-Host ""
Write-Info "To access the distro:"
Write-Host "  wsl -d $DistroName" -ForegroundColor Yellow
Write-Host ""
Write-Info "To start with default user:"
Write-Host "  wsl -d $DistroName -u $UserName" -ForegroundColor Yellow
Write-Host ""
Write-Info "Dotfiles location in WSL:"
Write-Host "  ~/gui-dotfiles" -ForegroundColor Yellow
Write-Host ""
