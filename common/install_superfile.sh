#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Install superfile (modern terminal file manager)
print_info "Installing superfile (modern terminal file manager)..."

# Check if already installed
if is_app_installed "superfile"; then
  version=$(get_installed_version "superfile")
  print_info "superfile is already installed (version $version)"
  print_info "To reinstall, remove ~/.local/share/gui-dotfiles/superfile.info"

  # Check if superfile executable exists
  if ! command -v spf &> /dev/null; then
    print_warning "superfile is tracked as installed but 'spf' command is not found. Reinstalling..."
  else
    print_success "superfile installation verified."
    exit 0
  fi
fi

# Install superfile using the official installer
print_info "Running superfile installer..."
print_warning "This will download and run the official installation script from superfile.dev"

# Download and run the installer
if bash -c "$(curl -sLo- https://superfile.dev/install.sh)"; then
  print_success "superfile installer completed!"
else
  print_error "superfile installation failed!"
  exit 1
fi

# Verify installation
if verify_installation "superfile" "command -v spf"; then
  superfile_version=$(spf --version 2>&1 | grep -oP 'v\K[0-9.]+' || echo "unknown")
  create_install_tracker "superfile" "$HOME/.local/share/gui-dotfiles" "$superfile_version"
  print_success "superfile installed successfully!"
  print_info "superfile version: $superfile_version"
  print_info ""
  print_info "Quick start:"
  print_info "  spf                  - Launch superfile"
  print_info "  spf <directory>      - Open specific directory"
  print_info ""
  print_info "Navigation:"
  print_info "  hjkl / Arrow keys    - Move around"
  print_info "  Enter                - Open file/directory"
  print_info "  Space                - Select files"
  print_info "  Backspace            - Go to parent directory"
  print_info "  q                    - Quit"
  print_info ""
  print_info "Full documentation: https://github.com/yorukot/superfile"
else
  print_error "superfile installation verification failed!"
  exit 1
fi
