#!/bin/bash

# Source common utilities
NVM_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$NVM_SCRIPT_DIR/../../common/utils.sh"

# Install NVM (Node Version Manager)
print_info "Installing NVM (Node Version Manager)..."

# Check if already installed
if is_app_installed "nvm"; then
  version=$(get_installed_version "nvm")
  print_info "NVM is already installed (version $version)"
  print_info "To reinstall, remove ~/.local/share/gui-dotfiles/nvm.info"
  
  # Check if NVM is properly sourced
  if ! command -v nvm &> /dev/null; then
    print_warning "NVM is tracked as installed but 'nvm' command is not found. Sourcing now..."
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    
    if ! command -v nvm &> /dev/null; then
      print_warning "NVM installation might be corrupted. Reinstalling..."
    else
      print_success "NVM installation verified."
      exit 0
    fi
  else
    print_success "NVM installation verified."
    exit 0
  fi
fi

# Ensure dependencies
ensure_command curl

# Get the latest NVM version
NVM_VERSION=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep -Po '"tag_name": "\K[^"]*')
print_info "Installing NVM version $NVM_VERSION..."

# Install NVM
curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash

# Source NVM for immediate use
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

# Verify installation - NVM needs special handling since it's a shell function, not a binary
print_info "Verifying NVM installation..."
if [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh" && command -v nvm &> /dev/null; then
  nvm_version=$(nvm --version)
  create_install_tracker "nvm" "$HOME/.local/share/gui-dotfiles" "$nvm_version"
  print_success "✅ NVM is correctly installed."
  print_info "   Version: $nvm_version"
else
  print_error "❌ NVM installation failed. Please check your internet connection and try again."
  exit 1
fi

print_success "NVM setup completed!"