#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/utils.sh"

#
# Install Nushell (modern shell)
#
print_info "Installing Nushell (modern shell)..."

# Check if already installed
if is_app_installed "nushell"; then
  version=$(get_installed_version "nushell")
  print_info "Nushell is already installed (version $version)"
  print_info "To reinstall, remove ~/.local/share/gui-dotfiles/nushell.info"
  
  # Check if nu executable exists
  if ! command -v nu &> /dev/null; then
    print_warning "Nushell is tracked as installed but 'nu' command is not found. Reinstalling..."
  else
    print_success "Nushell installation verified."
    exit 0
  fi
fi

# Function to install via cargo
install_via_cargo() {
  if command -v cargo &> /dev/null; then
    print_info "Installing Nushell via cargo..."
    cargo install nu --features=dataframe
    return $?
  else
    print_warning "Cargo not found. Cannot install via cargo."
    return 1
  fi
}

# Function to install via package manager (Ubuntu/Debian)
install_via_apt() {
  print_info "Attempting to install Nushell from package manager..."
  
  # Nushell may not be in standard repos, try to install anyway
  if sudo apt-get install -y nushell 2>/dev/null; then
    return 0
  else
    print_info "Nushell not available in apt repositories."
    return 1
  fi
}

# Try installation methods in order of preference
installation_success=false

# Method 1: Try cargo first (usually gets latest version)
if command -v cargo &> /dev/null; then
  print_info "Rust/Cargo detected, installing via cargo for latest version..."
  if install_via_cargo; then
    installation_success=true
  fi
fi

# Method 2: Try package manager if cargo failed or not available
if [ "$installation_success" = false ]; then
  if install_via_apt; then
    installation_success=true
  fi
fi

# Method 3: Install via official GitHub releases
if [ "$installation_success" = false ]; then
  print_info "Installing Nushell from GitHub releases..."
  
  # Ensure dependencies
  ensure_command curl
  ensure_command tar
  
  # Detect architecture
  ARCH=$(uname -m)
  case $ARCH in
    x86_64)
      NU_ARCH="x86_64"
      ;;
    aarch64|arm64)
      NU_ARCH="aarch64"
      ;;
    armv7l)
      NU_ARCH="armv7"
      ;;
    *)
      print_error "Unsupported architecture: $ARCH"
      exit 1
      ;;
  esac
  
  # Get latest release URL
  print_info "Fetching latest Nushell release for $NU_ARCH..."
  LATEST_URL=$(curl -s https://api.github.com/repos/nushell/nushell/releases/latest | \
    grep "browser_download_url.*${NU_ARCH}-unknown-linux-gnu.tar.gz" | \
    cut -d '"' -f 4)
  
  if [ -z "$LATEST_URL" ]; then
    print_error "Could not find Nushell release for architecture: $NU_ARCH"
    exit 1
  fi
  
  print_info "Downloading Nushell..."
  TMP_DIR=$(mktemp -d)
  cd "$TMP_DIR" || exit 1
  
  if curl -L -o nushell.tar.gz "$LATEST_URL"; then
    print_info "Extracting Nushell..."
    tar xzf nushell.tar.gz
    
    # Find the nu binary in extracted files
    NU_BINARY=$(find . -name "nu" -type f -executable | head -n 1)
    
    if [ -n "$NU_BINARY" ]; then
      # Install to ~/.local/bin
      mkdir -p "$HOME/.local/bin"
      cp "$NU_BINARY" "$HOME/.local/bin/nu"
      chmod +x "$HOME/.local/bin/nu"
      
      print_success "Nushell binary installed to ~/.local/bin/nu"
      installation_success=true
    else
      print_error "Could not find nu binary in downloaded archive"
    fi
  else
    print_error "Failed to download Nushell"
  fi
  
  # Cleanup
  cd - > /dev/null || exit 1
  rm -rf "$TMP_DIR"
fi

# Add ~/.local/bin to PATH if not already there
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
  print_info "Added ~/.local/bin to PATH for current session"
fi

# Verify installation
if [ "$installation_success" = true ]; then
  if command -v nu &> /dev/null; then
    nu_version=$(nu --version | head -n 1 | awk '{print $NF}')
    create_install_tracker "nushell" "$HOME/.local/share/gui-dotfiles" "$nu_version"
    print_success "Nushell installed successfully!"
    print_info "Nushell version: $nu_version"
    print_info "Start Nushell by running: nu"
    print_info "Config location: ~/.config/nushell/"
    exit 0
  elif [ -x "$HOME/.local/bin/nu" ]; then
    nu_version=$("$HOME/.local/bin/nu" --version | head -n 1 | awk '{print $NF}')
    create_install_tracker "nushell" "$HOME/.local/share/gui-dotfiles" "$nu_version"
    print_success "Nushell installed successfully!"
    print_info "Nushell version: $nu_version"
    print_info "Nushell will be available on PATH after shell restart"
    print_info "Config location: ~/.config/nushell/"
    exit 0
  fi
fi

# If we got here, installation failed
print_error "Nushell installation failed!"
print_info "You can try installing manually:"
print_info "  - Via cargo: cargo install nu --features=dataframe"
print_info "  - From GitHub: https://github.com/nushell/nushell/releases"
exit 1


