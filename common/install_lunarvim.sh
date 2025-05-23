#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Install LunarVim
print_info "Installing LunarVim..."

# Check if already installed
if is_app_installed "lunarvim"; then
  version=$(get_installed_version "lunarvim")
  print_info "LunarVim is already installed (version $version)"
  print_info "To reinstall, remove ~/.local/share/gui-dotfiles/lunarvim.info"
  
  # Check if lvim executable exists
  if ! command -v lvim &> /dev/null; then
    print_warning "LunarVim is tracked as installed but 'lvim' command is not found. Reinstalling..."
  else
    print_success "LunarVim installation verified."
    exit 0
  fi
fi

# Check Neovim dependency
if ! command -v nvim &> /dev/null; then
  print_error "Neovim is not installed. Please install it first."
  exit 1
fi

# Install dependencies for LunarVim
print_info "Installing LunarVim dependencies..."

# Check if cargo is available (Rust should be installed by now)
if ! command -v cargo &> /dev/null; then
  print_warning "Cargo is not available. Some LunarVim components may fail to install."
  if ask_yes_no "Do you want to try installing Rust/Cargo now?" "y"; then
    # Try to use the provided Rust installer
    if [ -f "$SCRIPT_DIR/../dev/rust/install_rustup.sh" ]; then
      print_info "Using Rust installer from dev environment..."
      bash "$SCRIPT_DIR/../dev/rust/install_rustup.sh"
    else
      # Fallback to the utility function
      ensure_rust
    fi
  fi
fi

# Detect distribution
pkg_manager=$(detect_pkg_manager)
case "$pkg_manager" in
  "apt")
    # Ubuntu/Debian
    install_packages git make python3-pip nodejs npm ripgrep fd-find
    
    # Create fd symlink if needed
    if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
      print_info "Creating fd symlink for fdfind..."
      mkdir -p ~/.local/bin
      ln -sf $(which fdfind) ~/.local/bin/fd
      add_to_path "$HOME/.local/bin"
    fi
    ;;
  "pacman")
    # Arch
    install_packages git make python-pip nodejs npm ripgrep fd
    
    # Ensure Rust is installed if needed
    if ! command -v cargo &> /dev/null; then
      install_packages rust
    fi
    ;;
  *)
    if is_fedora; then
      install_packages git make python3-pip nodejs npm ripgrep fd-find
    else
      print_warning "Unsupported distribution. Attempting to install dependencies..."
      ensure_command git git
      ensure_command python3 python
      ensure_command pip3 python3-pip
      ensure_command node nodejs
      ensure_command npm npm
      ensure_command rg ripgrep
      ensure_command fd fd-find
    fi
    ;;
esac

# Create required directories
mkdir -p ~/.config/lvim

# Install LunarVim
print_info "Installing LunarVim..."
LV_BRANCH='release-1.3/neovim-0.9' bash <(curl -s https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.3/neovim-0.9/utils/installer/install.sh)

# Verify installation
if verify_installation "LunarVim" "command -v lvim"; then
  # Create a backup of default config
  cp ~/.config/lvim/config.lua ~/.config/lvim/config.lua.bak 2>/dev/null || true
  
  # Create tracker file
  lvim_version="1.3" # Hard-coded since LunarVim doesn't have an easy version flag
  create_install_tracker "lunarvim" "$HOME/.local/share/gui-dotfiles" "$lvim_version"
  print_success "LunarVim installed successfully!"
else
  print_error "Failed to install LunarVim."
  exit 1
fi

# Add LunarVim to path if not already
add_to_path "$HOME/.local/bin"

print_info "You may need to restart your terminal or run 'source ~/.bashrc' to use LunarVim."
print_info "Use 'lvim' command to start LunarVim"