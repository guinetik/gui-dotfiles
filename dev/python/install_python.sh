#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../../common/utils.sh"

# Install Python using pyenv
print_info "Installing Python versions using pyenv..."

# Ensure pyenv is in path
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# Check if pyenv is installed
if ! command -v pyenv &> /dev/null; then
  print_error "pyenv is not installed. Please install pyenv first."
  exit 1
fi

# Update pyenv
print_info "Updating pyenv..."
cd "$PYENV_ROOT" && git pull || true

# Get latest Python versions
PYTHON_LATEST=$(pyenv install --list | grep -v "[a-zA-Z]" | grep -v "-" | sort -V | tail -1 | tr -d '[:space:]')
PYTHON_LATEST_LTS="3.10.13"  # This is stable as of 2024, update manually as needed

print_info "Latest Python version: $PYTHON_LATEST"
print_info "Latest Python LTS version: $PYTHON_LATEST_LTS"

# Function to install Python version
install_python_version() {
  local version=$1
  local tracker_name="python-$version"
  
  if is_app_installed "$tracker_name"; then
    stored_version=$(get_installed_version "$tracker_name")
    print_info "Python $version is already installed (tracked version: $stored_version)"
    
    # Verify the installation
    if ! pyenv versions | grep -q "$version"; then
      print_warning "Python $version is tracked but not found in pyenv. Reinstalling..."
      pyenv install -v "$version"
      create_install_tracker "$tracker_name" "$HOME/.local/share/gui-dotfiles" "$version"
    else
      print_success "Python $version installation verified."
      return 0
    fi
  else
    print_info "Installing Python $version..."
    pyenv install -v "$version"
    
    if pyenv versions | grep -q "$version"; then
      create_install_tracker "$tracker_name" "$HOME/.local/share/gui-dotfiles" "$version"
      print_success "Python $version installed successfully!"
      return 0
    else
      print_error "Failed to install Python $version"
      return 1
    fi
  fi
}

# Install both Python versions
install_python_version "$PYTHON_LATEST_LTS" || true
install_python_version "$PYTHON_LATEST" || true

# Set global Python version
print_info "Setting Python $PYTHON_LATEST as the global version..."
pyenv global "$PYTHON_LATEST"
pyenv rehash

# Upgrade pip in the global Python
print_info "Upgrading pip..."
pyenv exec pip install --upgrade pip

# Verify installations
print_success "Python installations completed!"
print_info "Available Python versions:"
pyenv versions

print_info "Current Python version:"
python --version
pip --version
exit 0