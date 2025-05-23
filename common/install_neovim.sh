#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Install Neovim
print_info "Installing Neovim..."

# Check if already installed
if is_app_installed "neovim"; then
  version=$(get_installed_version "neovim")
  print_info "Neovim is already installed (version $version)"
  print_info "To reinstall, remove ~/.local/share/gui-dotfiles/neovim.info"
  
  # Check if neovim executable exists
  if ! command -v nvim &> /dev/null; then
    print_warning "Neovim is tracked as installed but 'nvim' command is not found. Reinstalling..."
  else
    print_success "Neovim installation verified."
    exit 0
  fi
fi

# Install dependencies for Neovim based on distribution
print_info "Installing Neovim dependencies..."

# Detect distribution
pkg_manager=$(detect_pkg_manager)
case "$pkg_manager" in
  "apt")
    # Ubuntu/Debian - Install basic dependencies for AppImage handling
    install_packages curl file
    ;;
  "pacman")
    # Arch - Install basic dependencies for AppImage handling
    install_packages curl file
    ;;
  *)
    print_warning "Unsupported distribution. Attempting to install Neovim anyway..."
    ;;
esac

# Install latest stable Neovim
print_info "Installing latest stable Neovim from GitHub releases..."

# Install Neovim from GitHub releases using AppImage
if install_from_github "neovim/neovim" "nvim-linux-x86_64.appimage" "/usr/local/bin" "" "nvim"; then
  print_success "Neovim installed successfully from GitHub AppImage!"
else
  print_error "Failed to install Neovim from GitHub AppImage. Trying fallback methods..."
  
  # Fallback to package manager installation
  case "$pkg_manager" in
    "apt")
      # For Ubuntu/Debian - try to get a newer version via PPA
      print_info "Attempting package manager installation with PPA..."
      install_packages software-properties-common
      
      # Add PPA and update repo
      sudo add-apt-repository -y ppa:neovim-ppa/stable 2>/dev/null || true
      update_pkg_repos
      
      # Install neovim
      install_packages neovim
      ;;
    "pacman")
      # For Arch
      print_info "Attempting package manager installation..."
      install_packages neovim
      ;;
    *)
      print_error "Unsupported distribution and GitHub installation failed."
      print_error "Please install Neovim manually from https://github.com/neovim/neovim/releases"
      exit 1
      ;;
  esac
fi

# Verify installation
if verify_installation "Neovim" "command -v nvim"; then
  nvim_version=$(nvim --version | head -n 1 | awk '{print $2}')
  create_install_tracker "neovim" "$HOME/.local/share/gui-dotfiles" "$nvim_version"
  print_success "Neovim installed successfully!"
else
  print_error "Failed to install Neovim."
  exit 1
fi