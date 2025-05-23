#!/bin/bash

# Source common utilities
MAVEN_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$MAVEN_SCRIPT_DIR/../../common/utils.sh"

# Install Maven and Maven Daemon
print_info "Installing Maven..."

# Check if already installed
if is_app_installed "maven"; then
  version=$(get_installed_version "maven")
  print_info "Maven is already installed (version $version)"
  print_info "To reinstall, remove ~/.local/share/gui-dotfiles/maven.info"
  
  # Check if Maven executable exists
  if ! command -v mvn &> /dev/null; then
    print_warning "Maven is tracked as installed but 'mvn' command is not found. Reinstalling..."
  else
    print_success "Maven installation verified."
    exit 0
  fi
fi

# Install Maven using package manager
update_pkg_repos
install_packages maven

# Verify installation
if verify_installation "Maven" "command -v mvn"; then
  mvn_version=$(mvn --version | head -n 1 | awk '{print $3}')
  create_install_tracker "maven" "$HOME/.local/share/gui-dotfiles" "$mvn_version"
else
  print_error "Maven installation failed"
  exit 1
fi

# Install Maven Daemon (mvnd)
print_info "Installing Maven Daemon (mvnd)..."

# Check if already installed
if is_app_installed "mvnd"; then
  version=$(get_installed_version "mvnd")
  print_info "Maven Daemon is already installed (version $version)"
  print_info "To reinstall, remove ~/.local/share/gui-dotfiles/mvnd.info"
  
  if ! command -v mvnd &> /dev/null; then
    print_warning "Maven Daemon is tracked as installed but 'mvnd' command is not found. Reinstalling..."
  else
    print_success "Maven Daemon installation verified."
    exit 0
  fi
fi

# Create directory for mvnd
mkdir -p ~/.mvnd

# Get latest mvnd version
MVND_VERSION=$(curl -s https://api.github.com/repos/apache/maven-mvnd/releases/latest | grep -Po '"tag_name": "\K[^"]*')
print_info "Installing Maven Daemon version ${MVND_VERSION}..."

# Download and extract mvnd
cd /tmp || exit 1
curl -sL "https://github.com/apache/maven-mvnd/releases/download/${MVND_VERSION}/maven-mvnd-${MVND_VERSION}-linux-amd64.zip" -o mvnd.zip
unzip -q mvnd.zip
rm mvnd.zip

# Move to proper location
rm -rf "$HOME/.mvnd/maven-mvnd-"*
mv "maven-mvnd-${MVND_VERSION}-linux-amd64" "$HOME/.mvnd/"

# Add to PATH if not already added
MVND_HOME="$HOME/.mvnd/maven-mvnd-${MVND_VERSION}-linux-amd64"
add_to_bashrc "# Maven Daemon (mvnd)"
add_to_bashrc "export MVND_HOME=\"$MVND_HOME\""
add_to_bashrc "export PATH=\"\$MVND_HOME/bin:\$PATH\""

# Create a symlink for immediate use
mkdir -p "$HOME/.local/bin"
ln -sf "$MVND_HOME/bin/mvnd" "$HOME/.local/bin/mvnd"
export PATH="$HOME/.local/bin:$PATH"

# Verify installation
if verify_installation "Maven Daemon" "command -v mvnd"; then
  create_install_tracker "mvnd" "$HOME/.local/share/gui-dotfiles" "$MVND_VERSION"
  print_success "Maven Daemon (mvnd) installed successfully!"
else
  print_error "Maven Daemon installation failed"
  exit 1
fi

print_info "Maven and Maven Daemon installations completed."
print_info "Please restart your terminal or run 'source ~/.bashrc' to use mvnd."