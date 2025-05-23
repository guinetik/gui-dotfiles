#!/bin/bash

# Source common utilities
PYENV_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$PYENV_SCRIPT_DIR/../../common/utils.sh"

# Install pyenv (Python Version Manager)
print_info "Installing pyenv (Python Version Manager)..."

# Check if already installed
if is_app_installed "pyenv"; then
  version=$(get_installed_version "pyenv")
  print_info "pyenv is already installed (version $version)"
  print_info "To reinstall, remove ~/.local/share/gui-dotfiles/pyenv.info"
  
  # Check if pyenv is properly sourced
  if ! command -v pyenv &> /dev/null; then
    print_warning "pyenv is tracked as installed but 'pyenv' command is not found. Sourcing now..."
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
    
    if ! command -v pyenv &> /dev/null; then
      print_warning "pyenv installation might be corrupted. Reinstalling..."
    else
      print_success "pyenv installation verified."
      exit 0
    fi
  else
    print_success "pyenv installation verified."
    exit 0
  fi
fi

# Install dependencies
print_info "Installing pyenv dependencies..."
if is_ubuntu_debian; then
  install_packages "make" "build-essential" "libssl-dev" "zlib1g-dev" \
  "libbz2-dev" "libreadline-dev" "libsqlite3-dev" "wget" "curl" "llvm" \
  "libncursesw5-dev" "xz-utils" "tk-dev" "libxml2-dev" "libxmlsec1-dev" \
  "libffi-dev" "liblzma-dev"
elif is_arch; then
  install_packages "base-devel" "openssl" "zlib" "bzip2" "readline" "sqlite" \
  "wget" "curl" "llvm" "ncurses" "xz" "tk" "libxml2" "libxmlsec1" "libffi"
else
  print_warning "Unsupported distribution for automatic dependency installation."
  print_info "You may need to install dependencies manually."
fi

# Install pyenv using the official installer
print_info "Installing pyenv..."
curl -s https://pyenv.run | bash

# Source pyenv for immediate use
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# Check for successful installation
if command -v pyenv &> /dev/null; then
  pyenv_version=$(pyenv --version | awk '{print $2}')
  create_install_tracker "pyenv" "$HOME/.local/share/gui-dotfiles" "$pyenv_version"
  print_success "pyenv $pyenv_version installed successfully!"
else
  print_error "pyenv installation failed."
  exit 1
fi

# Add pyenv to bashrc if not already there
if ! grep -q 'PYENV_ROOT' ~/.bashrc; then
  print_info "Adding pyenv to ~/.bashrc"
  cat >> ~/.bashrc << 'EOF'

# pyenv setup
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
EOF
fi

print_success "pyenv installation completed!"
exit 0