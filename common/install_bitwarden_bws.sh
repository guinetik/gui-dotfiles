#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Install Bitwarden Secrets CLI (bws)
print_info "Installing Bitwarden Secrets CLI (bws)..."

# Check if already installed
if is_app_installed "bitwarden-bws"; then
  version=$(get_installed_version "bitwarden-bws")
  print_info "Bitwarden Secrets CLI is already installed (version $version)"
  print_info "To reinstall, remove ~/.local/share/gui-dotfiles/bitwarden-bws.info"

  # Check if bws command exists
  if ! command -v bws &> /dev/null; then
    print_warning "Bitwarden Secrets CLI is tracked as installed but 'bws' command is not found. Reinstalling..."
  else
    print_success "Bitwarden Secrets CLI installation verified."
    exit 0
  fi
fi

# Set version to install (update as needed)
BWS_VERSION="0.4.0"

print_info "Downloading Bitwarden Secrets CLI v${BWS_VERSION}..."
wget "https://github.com/bitwarden/sdk/releases/download/bws-v${BWS_VERSION}/bws-x86_64-unknown-linux-gnu-${BWS_VERSION}.zip" -O /tmp/bws.zip

if [ ! -f /tmp/bws.zip ]; then
  print_error "Failed to download Bitwarden Secrets CLI!"
  exit 1
fi

# Extract and install
print_info "Installing bws to /usr/local/bin..."
unzip -o /tmp/bws.zip -d /tmp/
chmod +x /tmp/bws
/usr/bin/sudo mv /tmp/bws /usr/local/bin/bws
rm /tmp/bws.zip

# Verify installation
if verify_installation "bitwarden-bws" "command -v bws"; then
  bws_version=$(bws --version 2>&1 | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "$BWS_VERSION")
  create_install_tracker "bitwarden-bws" "$HOME/.local/share/gui-dotfiles" "$bws_version"
  print_success "Bitwarden Secrets CLI installed successfully!"
  print_info "bws version: $bws_version"
  print_info "Usage: bws --help"
else
  print_error "Bitwarden Secrets CLI installation failed!"
  exit 1
fi
