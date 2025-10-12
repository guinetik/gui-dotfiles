#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../../../common/utils.sh"

# Install Docker Engine
print_info "Installing Docker Engine..."

# Check if already installed
if is_app_installed "docker"; then
  version=$(get_installed_version "docker")
  print_info "Docker is already installed (version $version)"
  print_info "To reinstall, remove ~/.local/share/gui-dotfiles/docker.info"

  # Check if docker command exists
  if ! command -v docker &> /dev/null; then
    print_warning "Docker is tracked as installed but 'docker' command is not found. Reinstalling..."
  else
    # Ensure Docker service is running
    if ! docker ps >/dev/null 2>&1; then
      print_info "Docker is installed but service is not running. Starting Docker..."
      /usr/bin/sudo service docker start || true
    fi
    print_success "Docker installation verified."
    exit 0
  fi
fi

# Add Docker's official GPG key
print_info "Adding Docker's official GPG key..."
/usr/bin/sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | /usr/bin/sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
/usr/bin/sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
print_info "Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | /usr/bin/sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package repositories
update_pkg_repos

# Install Docker packages
print_info "Installing Docker packages..."
if ! install_packages docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
  print_error "Failed to install Docker packages!"
  exit 1
fi

# Start Docker service (WSL2 specific)
print_info "Starting Docker service..."
/usr/bin/sudo service docker start || true

# Add current user to docker group
if [ "$USER" ] && [ "$USER" != "root" ]; then
  print_info "Adding user '$USER' to docker group..."
  /usr/bin/sudo usermod -aG docker "$USER"
  print_success "User '$USER' added to docker group"
  print_info "Note: Logout/login or run 'newgrp docker' for group changes to take effect"
fi

# Verify installation
if verify_installation "docker" "command -v docker"; then
  docker_version=$(docker --version | cut -d' ' -f3 | tr -d ',')
  create_install_tracker "docker" "$HOME/.local/share/gui-dotfiles" "$docker_version"
  print_success "Docker Engine installed successfully!"
  print_info "Docker version: $docker_version"
  print_info "Docker Compose is included as a plugin (docker compose)"

  # Offer to install oxker (Docker TUI)
  echo ""
  if ask_yes_no "Do you want to install oxker (TUI for Docker containers)?" "y"; then
    print_info "Installing oxker..."

    # Get the repository root directory
    repo_root=""
    current_dir="$SCRIPT_DIR"

    while [ "$current_dir" != "/" ]; do
      if [ -d "$current_dir/common" ]; then
        repo_root="$current_dir"
        break
      fi
      current_dir="$(cd "$current_dir/.." && pwd)"
    done

    if [ -z "$repo_root" ]; then
      print_error "Could not find repository root directory"
    else
      oxker_script="$repo_root/common/install_oxker.sh"

      if [ ! -f "$oxker_script" ]; then
        print_error "Oxker installation script not found: $oxker_script"
      else
        bash "$oxker_script"
      fi
    fi
  else
    print_info "Skipping oxker installation"
    print_info "You can install it later by running: ~/gui-dotfiles/common/install_oxker.sh"
  fi
else
  print_error "Docker installation failed!"
  exit 1
fi
