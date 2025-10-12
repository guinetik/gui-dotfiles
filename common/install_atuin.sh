#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Install atuin (shell history management)
print_info "Installing atuin (shell history management)..."

# Check if already installed
if is_app_installed "atuin"; then
  version=$(get_installed_version "atuin")
  print_info "atuin is already installed (version $version)"
  print_info "To reinstall, remove ~/.local/share/gui-dotfiles/atuin.info"

  # Check if atuin executable exists
  if ! command -v atuin &> /dev/null; then
    print_warning "atuin is tracked as installed but 'atuin' command is not found. Reinstalling..."
  else
    print_success "atuin installation verified."
    exit 0
  fi
fi

# Install atuin using the official installer
print_info "Running atuin installer..."
print_warning "This will download and run the official atuin installation script"

# Download and run the installer
if curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh; then
  print_success "atuin installer completed!"
else
  print_error "atuin installation failed!"
  exit 1
fi

# Add ~/.atuin/bin to PATH if not already there (atuin installs there)
if [[ ":$PATH:" != *":$HOME/.atuin/bin:"* ]]; then
  export PATH="$HOME/.atuin/bin:$PATH"
fi

# Source atuin env if it exists
[ -f "$HOME/.atuin/bin/env" ] && source "$HOME/.atuin/bin/env"

# Verify installation
if command -v atuin &> /dev/null || [ -x "$HOME/.atuin/bin/atuin" ]; then
  if command -v atuin &> /dev/null; then
    atuin_version=$(atuin --version 2>&1 | grep -oP 'atuin \K[0-9.]+' || echo "unknown")
    create_install_tracker "atuin" "$HOME/.local/share/gui-dotfiles" "$atuin_version"
    print_success "atuin installed successfully!"
    print_info "atuin version: $atuin_version"
    print_info ""
    print_info "Next steps:"
    print_info "1. Restart your shell or run: source ~/.bashrc (or ~/.zshrc)"
    print_info "2. Run 'atuin register' to create an account for sync (optional)"
    print_info "3. Run 'atuin login' to login to your account (optional)"
    print_info "4. Use Ctrl+R for fuzzy history search"
    print_info "5. Use 'atuin search <query>' to search history"
  else
    print_warning "atuin installed but not found in PATH. You may need to restart your shell."
    create_install_tracker "atuin" "$HOME/.local/share/gui-dotfiles" "installed"
    print_success "atuin installed successfully!"
  fi
else
  print_error "atuin installation verification failed!"
  print_error "atuin binary not found at $HOME/.atuin/bin/atuin"
  exit 1
fi
