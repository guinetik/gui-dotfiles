#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Install tokei (code statistics tool)
print_info "Installing tokei (code statistics tool)..."

# Check if already installed
if is_app_installed "tokei"; then
  version=$(get_installed_version "tokei")
  print_info "tokei is already installed (version $version)"
  print_info "To reinstall, remove ~/.local/share/gui-dotfiles/tokei.info"
  
  # Check if tokei executable exists
  if ! command -v tokei &> /dev/null; then
    print_warning "tokei is tracked as installed but 'tokei' command is not found. Reinstalling..."
  else
    print_success "tokei installation verified."
    exit 0
  fi
fi

# Try to install from package manager first
if ! install_packages tokei; then
  print_info "tokei not available in apt, installing from GitHub..."
  
  # Ensure dependencies
  ensure_command curl
  ensure_command wget
  
  # Install from GitHub
  install_from_github "XAMPPRocky/tokei" "tokei-x86_64-unknown-linux-gnu.tar.gz" "/usr/local/bin" "" "tokei" "v12.1.2"
fi

# Verify installation
if verify_installation "tokei" "command -v tokei"; then
  tokei_version=$(tokei --version | cut -d' ' -f2)
  create_install_tracker "tokei" "$HOME/.local/share/gui-dotfiles" "$tokei_version"
  print_success "tokei installed successfully!"
else
  print_error "tokei installation failed!"
  exit 1
fi