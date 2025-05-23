#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../../../common/utils.sh"

# Install exa (modern ls replacement)
print_info "Installing exa (modern ls replacement)..."

# Check if already installed
if is_app_installed "exa"; then
  version=$(get_installed_version "exa")
  print_info "exa is already installed (version $version)"
  print_info "To reinstall, remove ~/.local/share/gui-dotfiles/exa.info"
  
  # Check if exa executable exists
  if ! command -v exa &> /dev/null; then
    print_warning "exa is tracked as installed but 'exa' command is not found. Reinstalling..."
  else
    print_success "exa installation verified."
    exit 0
  fi
fi

# Try to install from package manager first
if ! install_packages exa; then
  print_info "exa not available in apt, installing from GitHub..."
  
  # Use the install_from_github helper function
  install_from_github "ogham/exa" "exa-linux-x86_64-musl-.*\.zip" "/usr/local/bin" '
    # Extract the zip and move the binary
    unzip -q *.zip
    sudo mv bin/exa /usr/local/bin/
    rm -rf bin completions man
  '
fi

# Verify installation
if verify_installation "exa" "command -v exa"; then
  exa_version=$(exa --version | head -n 1 | cut -d' ' -f1)
  create_install_tracker "exa" "$HOME/.local/share/gui-dotfiles" "$exa_version"
  print_success "exa installed successfully!"
else
  print_error "exa installation failed!"
  exit 1
fi