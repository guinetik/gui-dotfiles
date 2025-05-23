#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../../common/utils.sh"

# Node.js Development Environment Setup
print_info "Setting up Node.js Development Environment..."

# Create installation tracking directory
mkdir -p "$HOME/.local/share/gui-dotfiles"

# Install NVM
print_info "Installing NVM (Node Version Manager)..."
bash "$SCRIPT_DIR/install_nvm.sh"
if [ $? -ne 0 ]; then
    print_error "Failed to install NVM!"
    exit 1
fi

# Re-source the shell to get NVM working in this script
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

# Install Node.js
print_info "Installing Node.js..."
bash "$SCRIPT_DIR/install_node.sh"
if [ $? -ne 0 ]; then
    print_error "Failed to install Node.js!"
    exit 1
fi

print_success "Node.js Development Environment setup completed successfully!"
echo ""
print_info "Installed components:"
echo "- NVM (Node Version Manager)"
echo "- Latest LTS Node.js version"
echo "- Global packages: npm, yarn, pnpm, typescript, nodemon"
echo ""
print_info "You may need to restart your terminal or run the following to start using Node.js:"
echo 'export NVM_DIR="$HOME/.nvm"'
echo '[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"'