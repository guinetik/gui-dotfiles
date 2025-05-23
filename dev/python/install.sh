#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../../common/utils.sh"

# Python Development Environment Setup
print_info "Setting up Python Development Environment..."

# Create installation tracking directory
mkdir -p "$HOME/.local/share/gui-dotfiles"

# Install pyenv
print_info "Installing pyenv (Python Version Manager)..."
bash "$SCRIPT_DIR/install_pyenv.sh"
if [ $? -ne 0 ]; then
    print_error "Failed to install pyenv!"
    exit 1
fi

# Re-source pyenv to make it available for this script
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# Install latest Python versions
print_info "Installing Python versions..."
bash "$SCRIPT_DIR/install_python.sh"
if [ $? -ne 0 ]; then
    print_error "Failed to install Python versions!"
    exit 1
fi

# Install essential Python tools
print_info "Installing essential Python tools..."
bash "$SCRIPT_DIR/install_python_tools.sh"
if [ $? -ne 0 ]; then
    print_warning "Some Python tools may not have installed correctly."
fi

print_success "Python Development Environment setup completed successfully!"
echo ""
print_info "Installed components:"
echo "- pyenv (Python Version Manager)"
echo "- Latest Python version"
echo "- Essential Python tools (pip, pipx, poetry, venv)"
echo ""
print_info "Python version:"
python --version
echo ""
print_info "Pip version:"
pip --version
echo ""
print_info "You may need to restart your terminal or run 'source ~/.bashrc' to use all tools."