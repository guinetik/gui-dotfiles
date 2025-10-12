#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../../../common/utils.sh"

# Install PowerShell
print_info "Installing PowerShell..."

# Check if already installed
if is_app_installed "powershell"; then
  version=$(get_installed_version "powershell")
  print_info "PowerShell is already installed (version $version)"
  print_info "To reinstall, remove ~/.local/share/gui-dotfiles/powershell.info"

  # Check if pwsh command exists
  if ! command -v pwsh &> /dev/null; then
    print_warning "PowerShell is tracked as installed but 'pwsh' command is not found. Reinstalling..."
  else
    print_success "PowerShell installation verified."
    exit 0
  fi
fi

# Download and install Microsoft repository package
print_info "Adding Microsoft repository..."
UBUNTU_VERSION=$(lsb_release -rs)
wget -q "https://packages.microsoft.com/config/ubuntu/${UBUNTU_VERSION}/packages-microsoft-prod.deb" -O /tmp/packages-microsoft-prod.deb

if [ ! -f /tmp/packages-microsoft-prod.deb ]; then
  print_error "Failed to download Microsoft repository package!"
  exit 1
fi

/usr/bin/sudo dpkg -i /tmp/packages-microsoft-prod.deb
rm /tmp/packages-microsoft-prod.deb

# Update package repositories
update_pkg_repos

# Install PowerShell
print_info "Installing PowerShell package..."
if ! install_packages powershell; then
  print_error "Failed to install PowerShell!"
  exit 1
fi

# Verify installation
if verify_installation "powershell" "command -v pwsh"; then
  pwsh_version=$(pwsh --version | cut -d' ' -f2)
  create_install_tracker "powershell" "$HOME/.local/share/gui-dotfiles" "$pwsh_version"
  print_success "PowerShell installed successfully!"
  print_info "PowerShell version: $pwsh_version"
else
  print_error "PowerShell installation failed!"
  exit 1
fi
