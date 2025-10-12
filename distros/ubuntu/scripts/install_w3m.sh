#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../../../common/utils.sh"

# Install w3m (text-based web browser)
print_info "Installing w3m (text-based web browser)..."

# Check if already installed
if is_app_installed "w3m"; then
  version=$(get_installed_version "w3m")
  print_info "w3m is already installed (version $version)"
  print_info "To reinstall, remove ~/.local/share/gui-dotfiles/w3m.info"

  # Check if w3m executable exists
  if ! command -v w3m &> /dev/null; then
    print_warning "w3m is tracked as installed but command is not found. Reinstalling..."
  else
    print_success "w3m installation verified."
    exit 0
  fi
fi

# Install w3m from apt
print_info "Installing w3m from apt..."
if ! install_packages w3m; then
  print_error "Failed to install w3m!"
  exit 1
fi

# Verify installation
if verify_installation "w3m" "command -v w3m"; then
  w3m_version=$(w3m -version 2>&1 | head -1 | grep -oP 'w3m version \K[^\s,]+' || echo "unknown")
  create_install_tracker "w3m" "$HOME/.local/share/gui-dotfiles" "$w3m_version"
  print_success "w3m installed successfully!"
  print_info "w3m version: $w3m_version"
  print_info ""
  print_info "Quick start:"
  print_info "  w3m <url>            - Browse a URL"
  print_info "  w3m google.com       - Search Google"
  print_info "  w3m -dump <url>      - Dump page as text"
  print_info ""
  print_info "Navigation:"
  print_info "  hjkl / Arrow keys    - Navigate"
  print_info "  Enter                - Follow link"
  print_info "  B                    - Go back"
  print_info "  U                    - Open URL"
  print_info "  q                    - Quit"
  print_info "  /                    - Search in page"
else
  print_error "w3m installation failed!"
  exit 1
fi
