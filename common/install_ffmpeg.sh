#!/bin/bash

# Install FFmpeg - multimedia framework for audio/video processing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/utils.sh"

print_info "Installing FFmpeg (multimedia framework)..."

# Check if already installed
if is_app_installed "ffmpeg"; then
  version=$(get_installed_version "ffmpeg")
  print_info "FFmpeg is already installed (version $version)"

  if ! command -v ffmpeg &> /dev/null; then
    print_warning "FFmpeg tracked but not found. Reinstalling..."
  else
    print_success "FFmpeg installation verified."
    exit 0
  fi
fi

# Install via package manager
install_packages ffmpeg

# Verify installation
if verify_installation "ffmpeg" "command -v ffmpeg" "--version"; then
  ffmpeg_version=$(ffmpeg -version 2>&1 | head -1 | awk '{print $3}')
  create_install_tracker "ffmpeg" "$HOME/.local/share/gui-dotfiles" "$ffmpeg_version"
  print_success "FFmpeg installed successfully!"
else
  print_error "FFmpeg installation failed!"
  exit 1
fi
