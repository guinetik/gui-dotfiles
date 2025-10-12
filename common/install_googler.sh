#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Install googler (Google from the command line)
print_info "Installing googler (Google search from CLI)..."

# Check if already installed
if is_app_installed "googler"; then
  version=$(get_installed_version "googler")
  print_info "googler is already installed (version $version)"
  print_info "To reinstall, remove ~/.local/share/gui-dotfiles/googler.info"

  # Check if googler executable exists
  if ! command -v googler &> /dev/null; then
    print_warning "googler is tracked as installed but command is not found. Reinstalling..."
  else
    print_success "googler installation verified."
    exit 0
  fi
fi

# Try to install from apt first (some distros have it)
if install_packages googler 2>/dev/null; then
  print_success "googler installed from apt"
else
  print_info "googler not available in apt, trying pip..."

  # Check if pip/pip3 is available
  if command -v pip3 &> /dev/null; then
    PIP_CMD="pip3"
  elif command -v pip &> /dev/null; then
    PIP_CMD="pip"
  else
    print_error "pip is not installed. Please install Python and pip first."
    exit 1
  fi

  # Install googler using pip
  print_info "Installing googler via pip..."
  if $PIP_CMD install --user googler; then
    # Add ~/.local/bin to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
      export PATH="$HOME/.local/bin:$PATH"
    fi
    print_success "googler installed via pip"
  else
    print_error "Failed to install googler via pip!"
    exit 1
  fi
fi

# Verify installation
if verify_installation "googler" "command -v googler"; then
  googler_version=$(googler --version 2>&1 | grep -oP 'googler \K[0-9.]+' || echo "unknown")
  create_install_tracker "googler" "$HOME/.local/share/gui-dotfiles" "$googler_version"
  print_success "googler installed successfully!"
  print_info "googler version: $googler_version"
  print_info ""
  print_info "Quick start:"
  print_info "  googler <query>      - Search Google"
  print_info "  googler -n 5 <query> - Show 5 results"
  print_info "  googler -w <site>    - Search within a site"
  print_info "  googler -t <time>    - Search by time (h5=5hrs, d10=10days)"
  print_info ""
  print_info "Interactive mode:"
  print_info "  googler              - Enter interactive mode"
  print_info "  Press 'o' to open link in browser (w3m)"
  print_info "  Press 'n' for next page"
  print_info "  Press 'p' for previous page"
  print_info "  Press 'q' to quit"
  print_info ""
  print_info "Tip: Combine with w3m: googler <query> -C | w3m -T text/html"
else
  print_error "googler installation failed!"
  exit 1
fi
