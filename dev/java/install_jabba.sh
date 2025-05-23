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
print_info "Verifying Jabba installation..."

# For Jabba, we need to check if the files are installed rather than just the command
# since the command requires sourcing the environment
if [ -s "$JABBA_HOME/jabba.sh" ] && [ -x "$JABBA_HOME/bin/jabba" ]; then
  # Also check if we can run jabba in the current session
  if command -v jabba &> /dev/null; then
    print_success "✅ Jabba is correctly installed."
    print_info "   Jabba home: $JABBA_HOME"
    create_install_tracker "jabba" "$HOME/.local/share/gui-dotfiles" "$JABBA_VERSION"
  else
    print_warning "Jabba files installed but command not available in current session."
    print_info "This is normal - Jabba will be available after shell restart."
    create_install_tracker "jabba" "$HOME/.local/share/gui-dotfiles" "$JABBA_VERSION"
  fi
else
  print_error "❌ Jabba installation failed or is not working correctly."
  print_error "Expected files not found in $JABBA_HOME"
  exit 1
fi

# Add Jabba to bashrc if not already present
add_to_bashrc 'export JABBA_HOME="$HOME/.jabba"'
add_to_bashrc '[ -s "$JABBA_HOME/jabba.sh" ] && source "$JABBA_HOME/jabba.sh"'

# Install default Java version (OpenJDK 17)
print_info "Installing default Java version (OpenJDK 17)..."

# Try to install Java - only proceed if jabba command is available
if command -v jabba &> /dev/null; then
  jabba install openjdk@1.17.0
  jabba alias default openjdk@1.17.0
  
  # Verify Java installation by checking if the Java installation exists
  print_info "Verifying Java installation..."
  if [ -d "$JABBA_HOME/jdk" ] && jabba current &> /dev/null; then
    # Try to get Java version if available
    if command -v java &> /dev/null; then
      java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
      print_success "✅ Java installation verified."
      print_info "   Java version: $java_version"
      create_install_tracker "java-openjdk-17" "$HOME/.local/share/gui-dotfiles" "$java_version"
    else
      print_warning "Java installed via Jabba but not available in current session."
      print_info "Java will be available after shell restart."
      create_install_tracker "java-openjdk-17" "$HOME/.local/share/gui-dotfiles" "17"
    fi
  else
    print_warning "Java installation may have issues, but Jabba is installed."
    print_info "You can manually install Java with: jabba install openjdk@1.17.0"
  fi
else
  print_warning "Jabba command not available in current session."
  print_info "Java installation will be available after shell restart."
  print_info "Run 'jabba install openjdk@1.17.0' after restarting your shell."
fi

print_success "Jabba setup completed!"
print_info ""
print_info "📋 Next steps:"
print_info "• Restart your shell or run: source ~/.bashrc"
print_info "• Verify installation: jabba --version"
print_info ""
print_info "🔧 Useful Jabba commands:"
print_info "• jabba ls-remote    - See available Java versions"
print_info "• jabba install <ver> - Install a specific Java version"
print_info "• jabba use <ver>     - Switch between Java versions"
print_info "• jabba current       - Show current Java version"