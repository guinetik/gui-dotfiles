#!/bin/bash

# Source common utilities
PYTHON_TOOLS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$PYTHON_TOOLS_SCRIPT_DIR/../../common/utils.sh"

# Install essential Python tools
print_info "Installing essential Python tools..."

# Ensure pyenv is in path
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# Check if Python is installed
if ! command -v python &> /dev/null; then
  print_error "Python is not installed. Please install Python first."
  exit 1
fi

# Function to install a Python package
install_pip_package() {
  local package_name=$1
  local binary_name="${2:-$package_name}"
  local tracker_name="python-tool-$binary_name"
  
  if is_app_installed "$tracker_name"; then
    version=$(get_installed_version "$tracker_name")
    print_info "$binary_name is already installed (version $version)"
    
    # Check if executable exists
    if ! command -v "$binary_name" &> /dev/null; then
      if [[ "$binary_name" == "pipx" ]]; then
        # Special case for pipx
        if ! python -m pipx --version &> /dev/null; then
          print_warning "$binary_name is tracked as installed but command is not found. Reinstalling..."
          pip install --user --upgrade "$package_name"
        else
          print_success "$binary_name module is available via python -m $binary_name"
          return 0
        fi
      else
        print_warning "$binary_name is tracked as installed but command is not found. Reinstalling..."
        pip install --user --upgrade "$package_name"
      fi
    else
      print_success "$binary_name installation verified."
      return 0
    fi
  else
    print_info "Installing $package_name..."
    pip install --user --upgrade "$package_name"
  fi
  
  # Check installation and create tracker
  if command -v "$binary_name" &> /dev/null; then
    # Get version
    if [[ "$binary_name" == "poetry" ]]; then
      version=$("$binary_name" --version | awk '{print $3}')
    elif [[ "$binary_name" == "pipx" ]]; then
      version=$("$binary_name" --version 2>/dev/null || python -m pipx --version)
    else
      version=$("$binary_name" --version 2>/dev/null | awk '{print $2}')
    fi
    create_install_tracker "$tracker_name" "$HOME/.local/share/gui-dotfiles" "$version"
    print_success "$binary_name installed successfully (version $version)!"
    return 0
  elif [[ "$binary_name" == "pipx" ]] && python -m pipx --version &> /dev/null; then
    version=$(python -m pipx --version)
    create_install_tracker "$tracker_name" "$HOME/.local/share/gui-dotfiles" "$version"
    print_success "$binary_name module installed successfully (version $version)!"
    print_info "Use 'python -m pipx' to run pipx"
    return 0
  else
    print_error "Failed to install $binary_name"
    return 1
  fi
}

# Make sure pip is up to date
print_info "Upgrading pip..."
pip install --upgrade pip

# Install pipx for managing Python applications
install_pip_package "pipx" "pipx"

# Ensure pipx is in PATH
if command -v pipx &> /dev/null; then
  print_info "Ensuring pipx is properly configured..."
  pipx ensurepath
elif python -m pipx --version &> /dev/null; then
  print_info "Ensuring pipx is properly configured..."
  python -m pipx ensurepath
fi

# Install Poetry (dependency management)
print_info "Installing Poetry..."
if ! command -v poetry &> /dev/null; then
  curl -sSL https://install.python-poetry.org | python3 -
  if command -v poetry &> /dev/null; then
    version=$(poetry --version | awk '{print $3}')
    create_install_tracker "python-tool-poetry" "$HOME/.local/share/gui-dotfiles" "$version"
    print_success "Poetry installed successfully (version $version)!"
  else
    print_error "Failed to install Poetry"
  fi
else
  version=$(poetry --version | awk '{print $3}')
  print_info "Poetry is already installed (version $version)"
fi

# Install common development tools with pipx
PIPX_TOOLS=(
  "black"        # Code formatter
  "flake8"       # Linter
  "mypy"         # Static type checker
  "pytest"       # Testing framework
  "isort"        # Import sorter
  "virtualenv"   # Virtual environment tool
  "ruff"         # Fast Python linter
)

# Install each pipx tool
for tool in "${PIPX_TOOLS[@]}"; do
  if command -v pipx &> /dev/null; then
    # Install with pipx command
    print_info "Installing $tool with pipx..."
    if ! pipx list | grep -q "$tool"; then
      pipx install "$tool"
      
      if pipx list | grep -q "$tool"; then
        version=$(pipx list | grep "$tool" | grep -o "version.*" | awk '{print $2}')
        create_install_tracker "python-pipx-$tool" "$HOME/.local/share/gui-dotfiles" "$version"
        print_success "$tool installed successfully with pipx!"
      else
        print_error "Failed to install $tool with pipx"
      fi
    else
      version=$(pipx list | grep "$tool" | grep -o "version.*" | awk '{print $2}')
      print_info "$tool is already installed with pipx (version $version)"
    fi
  elif python -m pipx --version &> /dev/null; then
    # Install with python -m pipx
    print_info "Installing $tool with python -m pipx..."
    if ! python -m pipx list | grep -q "$tool"; then
      python -m pipx install "$tool"
      
      if python -m pipx list | grep -q "$tool"; then
        version=$(python -m pipx list | grep "$tool" | grep -o "version.*" | awk '{print $2}')
        create_install_tracker "python-pipx-$tool" "$HOME/.local/share/gui-dotfiles" "$version"
        print_success "$tool installed successfully with pipx!"
      else
        print_error "Failed to install $tool with pipx"
      fi
    else
      version=$(python -m pipx list | grep "$tool" | grep -o "version.*" | awk '{print $2}')
      print_info "$tool is already installed with pipx (version $version)"
    fi
  else
    # Fall back to pip if pipx is not available
    print_warning "pipx not available, installing $tool with pip..."
    install_pip_package "$tool" "$tool"
  fi
done

# Add Python user bin to PATH in bashrc if not already there
PYTHON_USER_BIN="$HOME/.local/bin"
if ! check_path "$PYTHON_USER_BIN"; then
  print_info "Adding Python user bin to PATH in ~/.bashrc"
  add_to_path "$PYTHON_USER_BIN"
fi

print_success "Python tools installation completed!"
echo ""
print_info "Installed Python tools:"
echo "- pipx (for isolated Python applications)"
echo "- poetry (dependency management)"
echo "- black (code formatter)"
echo "- flake8 (linter)"
echo "- mypy (type checker)"
echo "- pytest (testing framework)"
echo "- isort (import sorter)"
echo "- virtualenv (virtual environment tool)"
echo "- ruff (fast Python linter)"
exit 0