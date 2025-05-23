#!/bin/bash

# Source common utilities
JABBA_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$JABBA_SCRIPT_DIR/../../common/utils.sh"

# Install Jabba - Java Version Manager
print_info "Installing Jabba (Java Version Manager)..."

# Check if already installed
if is_app_installed "jabba"; then
  version=$(get_installed_version "jabba")
  print_info "Jabba is already installed (version $version)"
  print_info "To reinstall, remove ~/.local/share/gui-dotfiles/jabba.info"
  
  # Check if Jabba executable exists
  if ! command -v jabba &> /dev/null; then
    print_warning "Jabba is tracked as installed but 'jabba' command is not found. Reinstalling..."
  else
    print_success "Jabba installation verified."
    exit 0
  fi
fi

# Set the latest Jabba version
export JABBA_VERSION="0.14.0"

# Ensure dependencies
ensure_command curl

# Install Jabba
print_info "Installing Jabba version $JABBA_VERSION..."
curl -sL https://github.com/Jabba-Team/jabba/raw/main/install.sh | bash

# Source Jabba for immediate use
export JABBA_HOME="$HOME/.jabba"
[ -s "$JABBA_HOME/jabba.sh" ] && source "$JABBA_HOME/jabba.sh"

# Verify installation
if verify_installation "Jabba" "command -v jabba"; then
  create_install_tracker "jabba" "$HOME/.local/share/gui-dotfiles" "$JABBA_VERSION"
else
  print_error "Jabba installation failed!"
  exit 1
fi

# Add Jabba to bashrc if not already present
add_to_bashrc 'export JABBA_HOME="$HOME/.jabba"'
add_to_bashrc '[ -s "$JABBA_HOME/jabba.sh" ] && source "$JABBA_HOME/jabba.sh"'

# Install default Java version (OpenJDK 17)
print_info "Installing default Java version (OpenJDK 17)..."
jabba install openjdk@1.17.0
jabba alias default openjdk@1.17.0

# Verify Java installation
if verify_installation "Java" "jabba current"; then
  java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
  create_install_tracker "java-openjdk-17" "$HOME/.local/share/gui-dotfiles" "$java_version"
  print_success "Java installation verified."
else
  print_error "Java installation failed!"
  exit 1
fi

print_success "Jabba setup completed!"
print_info "Use 'jabba ls-remote' to see available Java versions"
print_info "Use 'jabba install <version>' to install a specific version"
print_info "Use 'jabba use <version>' to switch between versions"