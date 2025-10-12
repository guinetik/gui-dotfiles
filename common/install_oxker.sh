#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
if [ -f "$SCRIPT_DIR/utils.sh" ]; then
  source "$SCRIPT_DIR/utils.sh"
else
  # Fallback print functions if utils.sh not available
  print_info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
  print_success() { echo -e "\033[0;32m[SUCCESS]\033[0m $1"; }
  print_warning() { echo -e "\033[0;33m[WARNING]\033[0m $1"; }
  print_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }
fi

# Install oxker (TUI for Docker containers)
print_info "Installing oxker (Docker TUI)..."

# Check if already installed
if is_app_installed "oxker"; then
  version=$(get_installed_version "oxker")
  print_info "oxker is already installed (version $version)"
  print_info "To reinstall, remove ~/.local/share/gui-dotfiles/oxker.info"

  # Check if oxker executable exists
  if ! command -v oxker &> /dev/null; then
    print_warning "oxker is tracked as installed but command is not found. Reinstalling..."
  else
    print_success "oxker installation verified."
    exit 0
  fi
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
  print_warning "Docker is not installed. oxker requires Docker to function."
  print_info "You can still install oxker, but it won't be functional until Docker is installed."
  read -p "Continue anyway? (y/n): " continue_choice
  if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
    print_info "Skipping oxker installation."
    exit 0
  fi
fi

# Try cargo install first if available
if command -v cargo &> /dev/null; then
  print_info "Rust/Cargo detected. Installing oxker via cargo..."
  if cargo install oxker; then
    # Verify installation
    if command -v oxker &> /dev/null; then
      oxker_version=$(oxker --version 2>&1 | grep -oP 'oxker \K[0-9.]+' || echo "unknown")
      create_install_tracker "oxker" "$HOME/.local/share/gui-dotfiles" "$oxker_version"
      print_success "oxker installed successfully via cargo!"
      print_info "Run 'oxker' to launch the Docker TUI"
      print_info "Note: Your shell is configured to use custom config from ~/gui-dotfiles/oxker/oxker.config.jsonc"
      exit 0
    fi
  else
    print_warning "Cargo install failed. Trying GitHub release..."
  fi
else
  print_info "Rust/Cargo not available. Installing from GitHub releases..."
fi

# Fallback to GitHub release
print_info "Downloading oxker from GitHub..."

# Use the install_from_github helper
install_from_github "mrjackwills/oxker" "oxker_linux_x86_64\.tar\.gz" "/usr/local/bin" '
  # Extract and move the binary
  tar -xzf oxker_linux_x86_64.tar.gz
  /usr/bin/sudo mv oxker /usr/local/bin/
  /usr/bin/sudo chmod +x /usr/local/bin/oxker
'

# Verify installation
if verify_installation "oxker" "command -v oxker"; then
  oxker_version=$(oxker --version 2>&1 | grep -oP 'oxker \K[0-9.]+' || echo "unknown")
  create_install_tracker "oxker" "$HOME/.local/share/gui-dotfiles" "$oxker_version"
  print_success "oxker installed successfully!"
  print_info "Run 'oxker' to launch the Docker TUI"
  print_info "Note: Your shell is configured to use custom config from ~/gui-dotfiles/oxker/oxker.config.jsonc"
else
  print_error "oxker installation failed!"
  exit 1
fi
