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
    # Ubuntu/Debian
    install_packages ninja-build gettext cmake unzip curl
    ;;
  "pacman")
    # Arch
    install_packages base-devel cmake unzip ninja curl
    ;;
  *)
    print_error "Unsupported distribution. Please install Neovim dependencies manually."
    exit 1
    ;;
esac

# Install latest stable Neovim
print_info "Installing latest stable Neovim..."
case "$pkg_manager" in
  "apt")
    # For Ubuntu/Debian
    install_packages software-properties-common
    
    # Add PPA and update repo
    sudo add-apt-repository -y ppa:neovim-ppa/stable
    update_pkg_repos
    
    # Install neovim
    install_packages neovim
    ;;
  "pacman")
    # For Arch
    install_packages neovim
    ;;
  *)
    # Build from source as fallback
    print_info "Building Neovim from source..."
    cd /tmp || exit 1
    git clone https://github.com/neovim/neovim
    cd neovim || exit 1
    git checkout stable
    make CMAKE_BUILD_TYPE=RelWithDebInfo
    sudo make install
    cd - || exit 1
    ;;
esac

# Verify installation
if verify_installation "Neovim" "command -v nvim"; then
  nvim_version=$(nvim --version | head -n 1 | awk '{print $2}')
  create_install_tracker "neovim" "$HOME/.local/share/gui-dotfiles" "$nvim_version"
  print_success "Neovim installed successfully!"
else
  print_error "Failed to install Neovim."
  exit 1
fi