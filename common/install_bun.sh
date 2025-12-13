#!/bin/bash

# Install Bun - JavaScript/TypeScript runtime and package manager
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/utils.sh"

print_info "Installing Bun (JavaScript/TypeScript runtime)..."

# Check if already installed
if is_app_installed "bun"; then
  version=$(get_installed_version "bun")
  print_info "Bun is already installed (version $version)"

  if ! command -v bun &> /dev/null; then
    print_warning "Bun tracked but not found. Reinstalling..."
  else
    print_success "Bun installation verified."
    exit 0
  fi
fi

# Ensure curl is available
ensure_command curl

print_info "Downloading and installing Bun..."

# Use official Bun installer
if ! curl -fsSL https://bun.sh/install | bash; then
  print_error "Failed to download/install Bun"
  exit 1
fi

# Source the newly installed Bun in PATH
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Add to shell configs if not already present
if ! grep -q '$HOME/.bun/bin' ~/.bashrc; then
  echo '' >> ~/.bashrc
  echo '# Bun - added by gui-dotfiles' >> ~/.bashrc
  echo 'export BUN_INSTALL="$HOME/.bun"' >> ~/.bashrc
  echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> ~/.bashrc
fi

if ! grep -q '$HOME/.bun/bin' ~/.zshrc; then
  echo '' >> ~/.zshrc
  echo '# Bun - added by gui-dotfiles' >> ~/.zshrc
  echo 'export BUN_INSTALL="$HOME/.bun"' >> ~/.zshrc
  echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> ~/.zshrc
fi

# Verify installation
if verify_installation "bun" "command -v bun" "--version"; then
  bun_version=$(bun --version)
  create_install_tracker "bun" "$HOME/.local/share/gui-dotfiles" "$bun_version"
  print_success "Bun installed successfully!"
  print_info "Bun version: $bun_version"
  print_info "You may need to reload your shell (exec zsh or exec bash) for PATH changes to take effect"
else
  print_error "Bun installation failed!"
  exit 1
fi
