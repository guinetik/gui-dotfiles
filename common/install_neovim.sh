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

# Install Neovim v0.9.5 for compatibility with LunarVim 1.3
print_info "Installing Neovim v0.9.5 from GitHub releases (compatible with LunarVim 1.3)..."

# Download and extract tarball
NEOVIM_VERSION="v0.9.5"
NEOVIM_URL="https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/nvim-linux64.tar.gz"
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR" || exit 1

print_info "Downloading Neovim ${NEOVIM_VERSION}..."
curl -L -o nvim-linux64.tar.gz "$NEOVIM_URL" || {
  print_error "Failed to download Neovim"
  cd - &>/dev/null
  rm -rf "$TMP_DIR"
  exit 1
}

print_info "Extracting Neovim..."
tar xzf nvim-linux64.tar.gz || {
  print_error "Failed to extract Neovim"
  cd - &>/dev/null
  rm -rf "$TMP_DIR"
  exit 1
}

print_info "Installing Neovim to /usr/local..."
# Copy each directory individually to avoid conflicts
/usr/bin/sudo cp -r nvim-linux64/bin/* /usr/local/bin/ 2>/dev/null || true
/usr/bin/sudo cp -r nvim-linux64/lib/* /usr/local/lib/ 2>/dev/null || true
/usr/bin/sudo mkdir -p /usr/local/share/nvim
/usr/bin/sudo cp -r nvim-linux64/share/nvim/* /usr/local/share/nvim/ 2>/dev/null || true

if [ -d "nvim-linux64/man" ]; then
  # Handle man pages carefully
  for mandir in nvim-linux64/man/man*; do
    if [ -d "$mandir" ]; then
      manname=$(basename "$mandir")
      /usr/bin/sudo mkdir -p "/usr/local/share/man/$manname"
      /usr/bin/sudo cp -r "$mandir"/* "/usr/local/share/man/$manname/" 2>/dev/null || true
    fi
  done
fi

# Clean up
cd - &>/dev/null
rm -rf "$TMP_DIR"

if command -v nvim &> /dev/null; then
  print_success "Neovim installed successfully from GitHub tarball!"
else
  print_error "Failed to install Neovim from GitHub tarball. Trying fallback methods..."
  
  # Fallback to package manager installation
  case "$pkg_manager" in
    "apt")
      # For Ubuntu/Debian - try to get a newer version via PPA
      print_info "Attempting package manager installation with PPA..."
      install_packages software-properties-common
      
      # Add PPA and update repo
      /usr/bin/sudo add-apt-repository -y ppa:neovim-ppa/stable 2>/dev/null || true
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