#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Install ripgrep (fast regex-based search tool)
print_info "Installing ripgrep (fast regex-based search tool)..."

# Check if already installed
if is_app_installed "ripgrep"; then
  version=$(get_installed_version "ripgrep")
  print_info "ripgrep is already installed (version $version)"
  print_info "To reinstall, remove ~/.local/share/gui-dotfiles/ripgrep.info"
  
  # Check if ripgrep executable exists
  if ! command -v rg &> /dev/null; then
    print_warning "ripgrep is tracked as installed but 'rg' command is not found. Reinstalling..."
  else
    print_success "ripgrep installation verified."
    exit 0
  fi
fi

# Try to install from package manager first
if ! install_packages ripgrep; then
  print_info "ripgrep not available in apt, installing from GitHub..."
  
  # Use the install_from_github helper
  install_from_github "BurntSushi/ripgrep" "ripgrep-.*-x86_64-unknown-linux-musl.tar.gz" "/usr/local/bin" '
    local dir=$(find . -type d -name "ripgrep-*-x86_64-unknown-linux-musl" | head -1)
    if [ -n "$dir" ]; then
      /usr/bin/sudo cp "$dir/rg" /usr/local/bin/
    fi
  '
fi

# Verify installation
if verify_installation "ripgrep" "command -v rg"; then
  rg_version=$(rg --version | head -n 1 | cut -d' ' -f2)
  create_install_tracker "ripgrep" "$HOME/.local/share/gui-dotfiles" "$rg_version"
  print_success "ripgrep installed successfully!"
else
  print_error "ripgrep installation failed!"
  exit 1
fi