#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../../../common/utils.sh"

# Install zoxide (smarter cd command)
print_info "Installing zoxide (smarter cd command)..."

# Check if already installed
if is_app_installed "zoxide"; then
  version=$(get_installed_version "zoxide")
  print_info "zoxide is already installed (version $version)"
  print_info "To reinstall, remove ~/.local/share/gui-dotfiles/zoxide.info"
  
  # Check if zoxide executable exists
  if ! command -v zoxide &> /dev/null; then
    print_warning "zoxide is tracked as installed but 'zoxide' command is not found. Reinstalling..."
  else
    print_success "zoxide installation verified."
    exit 0
  fi
fi

# Try to install from package manager first
if ! install_packages zoxide; then
  print_info "zoxide not available in apt, installing from GitHub..."
  
  # Ensure dependencies
  ensure_command curl
  
  # Install from GitHub
  curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

# Verify installation
if verify_installation "zoxide" "command -v zoxide"; then
  zoxide_version=$(zoxide --version | cut -d' ' -f2)
  create_install_tracker "zoxide" "$HOME/.local/share/gui-dotfiles" "$zoxide_version"
  print_success "zoxide installed successfully!"
else
  print_error "zoxide installation failed!"
  exit 1
fi

# Ensure it's initialized in bashrc
add_to_bashrc 'eval "$(zoxide init bash)"'