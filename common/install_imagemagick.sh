#!/bin/bash

# Install ImageMagick - image manipulation toolkit
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/utils.sh"

print_info "Installing ImageMagick (image manipulation toolkit)..."

# Check if already installed
if is_app_installed "imagemagick"; then
  version=$(get_installed_version "imagemagick")
  print_info "ImageMagick is already installed (version $version)"

  if ! command -v convert &> /dev/null; then
    print_warning "ImageMagick tracked but not found. Reinstalling..."
  else
    print_success "ImageMagick installation verified."
    exit 0
  fi
fi

# Install via package manager
install_packages imagemagick

# Verify installation (check for 'convert' command)
if verify_installation "imagemagick" "command -v convert" "--version"; then
  im_version=$(convert --version 2>&1 | head -1 | awk '{print $3}')
  create_install_tracker "imagemagick" "$HOME/.local/share/gui-dotfiles" "$im_version"
  print_success "ImageMagick installed successfully!"
else
  print_error "ImageMagick installation failed!"
  exit 1
fi
