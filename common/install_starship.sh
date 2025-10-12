#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Install Starship prompt
print_info "Installing Starship prompt..."

# Check if already installed
if is_app_installed "starship"; then
  version=$(get_installed_version "starship")
  print_info "Starship is already installed (version $version)"
  print_info "To reinstall, remove ~/.local/share/gui-dotfiles/starship.info"
  
  # Check if starship executable exists
  if ! command -v starship &> /dev/null; then
    print_warning "Starship is tracked as installed but 'starship' command is not found. Reinstalling..."
  else
    print_success "Starship installation verified."
    exit 0
  fi
fi

# Ensure dependencies
ensure_command curl

# Install Starship
curl -sS https://starship.rs/install.sh | sh

# Verify installation
if verify_installation "Starship" "command -v starship"; then
  starship_version=$(starship --version | cut -d' ' -f2)
  create_install_tracker "starship" "$HOME/.local/share/gui-dotfiles" "$starship_version"
  print_success "Starship installed successfully!"
else
  print_error "Starship installation failed!"
  exit 1
fi

# Ensure it's initialized in bashrc
add_to_bashrc 'eval "$(starship init bash)"'

# Create config directory if it doesn't exist
mkdir -p ~/.config