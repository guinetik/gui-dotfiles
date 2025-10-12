#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Install fzf-git.sh (FZF + Git integration)
print_info "Installing fzf-git.sh (FZF + Git integration)..."

# Installation directory
FZF_GIT_DIR="$HOME/.local/share/fzf-git.sh"

# Check if already installed
if is_app_installed "fzf-git"; then
  version=$(get_installed_version "fzf-git")
  print_info "fzf-git.sh is already installed (version $version)"
  print_info "To reinstall, remove ~/.local/share/gui-dotfiles/fzf-git.info"

  # Check if directory exists
  if [ ! -d "$FZF_GIT_DIR" ]; then
    print_warning "fzf-git.sh is tracked as installed but directory not found. Reinstalling..."
  else
    print_success "fzf-git.sh installation verified."
    exit 0
  fi
fi

# Check if fzf is installed
if ! command -v fzf &> /dev/null; then
  print_error "fzf is not installed. Please install fzf first."
  exit 1
fi

# Clone the repository
print_info "Cloning fzf-git.sh repository..."
if [ -d "$FZF_GIT_DIR" ]; then
  print_info "Directory exists, pulling latest changes..."
  cd "$FZF_GIT_DIR" && git pull
else
  git clone https://github.com/junegunn/fzf-git.sh.git "$FZF_GIT_DIR"
fi

# Verify installation
if [ -f "$FZF_GIT_DIR/fzf-git.sh" ]; then
  # Get commit hash as version
  cd "$FZF_GIT_DIR"
  commit_hash=$(git rev-parse --short HEAD)
  create_install_tracker "fzf-git" "$HOME/.local/share/gui-dotfiles" "$commit_hash"
  print_success "fzf-git.sh installed successfully!"
  print_info "Location: $FZF_GIT_DIR"
  print_info "Add to your shell: source $FZF_GIT_DIR/fzf-git.sh"
else
  print_error "fzf-git.sh installation failed!"
  exit 1
fi
