#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Install eza (modern ls replacement, maintained fork of exa)
print_info "Installing eza (modern ls replacement)..."

# Check if already installed
if is_app_installed "eza"; then
  version=$(get_installed_version "eza")
  print_info "eza is already installed (version $version)"
  print_info "To reinstall, remove ~/.local/share/gui-dotfiles/eza.info"

  # Check if eza executable exists
  if ! command -v eza &> /dev/null; then
    print_warning "eza is tracked as installed but 'eza' command is not found. Reinstalling..."
  else
    print_success "eza installation verified."
    exit 0
  fi
fi

# Try to install from package manager first (newer Ubuntu versions have it)
if ! install_packages eza; then
  print_info "eza not available in apt, installing from GitHub..."

  # Use the install_from_github helper function
  install_from_github "eza-community/eza" "eza_x86_64-unknown-linux-musl\.tar\.gz" "/usr/local/bin" '
    # Extract and move the binary
    tar -xzf eza_*.tar.gz
    /usr/bin/sudo mv ./eza /usr/local/bin/
  '
fi

# Verify installation
if verify_installation "eza" "command -v eza"; then
  eza_version=$(eza --version | head -n 1 | grep -oP "v\K[0-9.]+")
  create_install_tracker "eza" "$HOME/.local/share/gui-dotfiles" "$eza_version"
  print_success "eza installed successfully!"
else
  print_error "eza installation failed!"
  exit 1
fi
