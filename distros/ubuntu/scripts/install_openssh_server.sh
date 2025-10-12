#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../../../common/utils.sh"

# Install and configure OpenSSH Server
print_info "Installing OpenSSH Server..."

# Check if already installed
if is_app_installed "openssh-server"; then
  version=$(get_installed_version "openssh-server")
  print_info "OpenSSH Server is already installed (version $version)"
  print_info "To reinstall, remove ~/.local/share/gui-dotfiles/openssh-server.info"

  # Check if sshd command exists
  if ! command -v sshd &> /dev/null; then
    print_warning "OpenSSH Server is tracked as installed but 'sshd' command is not found. Reinstalling..."
  else
    # Ensure SSH service is configured
    if [ ! -d /run/sshd ]; then
      print_info "Creating /run/sshd directory..."
      /usr/bin/sudo mkdir -p /run/sshd
    fi

    # Check if SSH is running
    if ! pgrep -x "sshd" > /dev/null; then
      print_info "SSH server is not running. Starting..."
      /usr/bin/sudo /usr/sbin/sshd || print_warning "Could not start SSH server (this is normal in some WSL environments)"
    fi

    print_success "OpenSSH Server installation verified."
    exit 0
  fi
fi

# Install OpenSSH Server
print_info "Installing openssh-server package..."
if ! install_packages openssh-server; then
  print_error "Failed to install OpenSSH Server!"
  exit 1
fi

# Create SSH runtime directory
if [ ! -d /run/sshd ]; then
  print_info "Creating /run/sshd directory..."
  /usr/bin/sudo mkdir -p /run/sshd
fi

# Try to enable SSH with systemd (if available)
print_info "Attempting to enable SSH auto-start with systemd..."
/usr/bin/sudo systemctl enable ssh 2>/dev/null || print_warning "Could not enable SSH with systemd (may not be active yet)"

# Start SSH server if not running
if ! pgrep -x "sshd" > /dev/null; then
  print_info "Starting SSH server..."
  /usr/bin/sudo /usr/sbin/sshd

  if pgrep -x "sshd" > /dev/null; then
    print_success "SSH server started successfully"
  else
    print_warning "SSH server failed to start (this is normal in some WSL environments)"
    print_info "You can start it manually with: /usr/bin/sudo /usr/sbin/sshd"
  fi
else
  print_success "SSH server is already running"
fi

# Verify installation
if verify_installation "openssh-server" "command -v sshd"; then
  sshd_version=$(sshd -V 2>&1 | head -1 | grep -oP 'OpenSSH_\K[0-9.]+[a-z0-9]*')
  create_install_tracker "openssh-server" "$HOME/.local/share/gui-dotfiles" "$sshd_version"
  print_success "OpenSSH Server installed successfully!"
  print_info "OpenSSH version: $sshd_version"
  print_info "Note: For WSL, ensure systemd is enabled in /etc/wsl.conf for auto-start"
else
  print_error "OpenSSH Server installation failed!"
  exit 1
fi
