#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../../../common/utils.sh"

# Install basic packages
print_info "Installing necessary basic packages..."

# Define required packages
BASIC_PACKAGES=(
  "curl"
  "git"
  "zsh"
  "wget"
  "unzip"
  "fzf"
  "jq"
  "sudo"
  "build-essential"
  "net-tools"
  "iproute2"
  "less"
  "vim"
  "dos2unix"
  "ca-certificates"
  "gnupg"
  "lsb-release"
  "software-properties-common"
  "apt-transport-https"
)

# Update package repositories
update_pkg_repos

# Install each package and track it
for pkg in "${BASIC_PACKAGES[@]}"; do
  if is_app_installed "base-pkg-$pkg"; then
    version=$(get_installed_version "base-pkg-$pkg")
    print_info "$pkg is already installed (version $version)"
    
    # Check if executable exists
    if ! command -v "$pkg" &> /dev/null; then
      print_warning "$pkg is tracked as installed but command is not found. Reinstalling..."
      install_packages "$pkg"
    fi
  else
    print_info "Installing $pkg..."
    if install_packages "$pkg"; then
      # For packages where we can get a version
      if command -v "$pkg" &> /dev/null; then
        pkg_version=$("$pkg" --version 2>/dev/null | head -n 1 | cut -d' ' -f2 2>/dev/null || echo "installed")
        create_install_tracker "base-pkg-$pkg" "$HOME/.local/share/gui-dotfiles" "$pkg_version"
        print_success "$pkg installed successfully!"
      fi
    else
      print_error "Failed to install $pkg!"
    fi
  fi
done

print_success "Basic packages installation completed!"