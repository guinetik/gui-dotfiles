#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../../common/utils.sh"

# Install Node.js using NVM
print_info "Installing latest Node.js version using NVM..."

# Source NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

# Check if NVM is installed
if ! command -v nvm &> /dev/null; then
    print_error "NVM is not installed. Please install NVM first."
    exit 1
fi

# Check if desired Node.js version is already installed
NODE_LTS_ALIAS="lts/*"
CURRENT_NODE_VERSION=$(nvm current)

if is_app_installed "node-lts" && [ "$CURRENT_NODE_VERSION" != "none" ] && [ "$CURRENT_NODE_VERSION" != "N/A" ]; then
  version=$(get_installed_version "node-lts")
  print_info "Node.js LTS is already installed (version $version)"
  print_info "To reinstall, remove ~/.local/share/gui-dotfiles/node-lts.info"
  
  # Check if node executable exists
  if ! command -v node &> /dev/null; then
    print_warning "Node.js is tracked as installed but 'node' command is not found. Reinstalling..."
  else
    print_success "Node.js installation verified."
    # Continue to the global packages section
  fi
else
  # Install latest LTS version of Node.js
  print_info "Installing latest LTS version of Node.js..."
  nvm install --lts
  
  # Make it the default
  nvm alias default "$NODE_LTS_ALIAS"
  nvm use default
  
  # Verify installation
  if verify_installation "Node.js" "command -v node"; then
    node_version=$(node --version)
    create_install_tracker "node-lts" "$HOME/.local/share/gui-dotfiles" "${node_version#v}"
    print_success "Node.js ${node_version} installed successfully!"
  else
    print_error "Node.js installation failed!"
    exit 1
  fi
fi

# Install essential global packages
print_info "Installing essential global packages..."

# Define packages to install
PACKAGES=("npm@latest" "yarn" "pnpm" "typescript" "nodemon")

# Install each package
for pkg in "${PACKAGES[@]}"; do
  pkg_name=${pkg%%@*}  # Remove version part
  
  # Check if package is already installed
  if is_app_installed "node-pkg-$pkg_name"; then
    version=$(get_installed_version "node-pkg-$pkg_name")
    print_info "$pkg_name is already installed (version $version)"
    
    # Check if executable exists
    if ! command -v "$pkg_name" &> /dev/null; then
      print_warning "$pkg_name is tracked as installed but command is not found. Reinstalling..."
      npm install -g "$pkg"
      
      if command -v "$pkg_name" &> /dev/null; then
        pkg_version=$("$pkg_name" --version 2>/dev/null)
        create_install_tracker "node-pkg-$pkg_name" "$HOME/.local/share/gui-dotfiles" "$pkg_version"
      else
        print_error "Failed to install $pkg_name"
      fi
    fi
  else
    print_info "Installing $pkg..."
    npm install -g "$pkg"
    
    if command -v "$pkg_name" &> /dev/null; then
      pkg_version=$("$pkg_name" --version 2>/dev/null)
      create_install_tracker "node-pkg-$pkg_name" "$HOME/.local/share/gui-dotfiles" "$pkg_version"
      print_success "$pkg_name installed successfully (version $pkg_version)"
    else
      print_error "Failed to install $pkg_name"
    fi
  fi
done

# Verify all installations
print_success "Node.js environment setup completed!"
print_info "Node version: $(node --version)"
print_info "NPM version: $(npm --version)"
print_info "Yarn version: $(yarn --version 2>/dev/null || echo 'Not installed')"
print_info "PNPM version: $(pnpm --version 2>/dev/null || echo 'Not installed')"
print_info "TypeScript version: $(tsc --version 2>/dev/null || echo 'Not installed')"
print_info "Nodemon version: $(nodemon --version 2>/dev/null || echo 'Not installed')"