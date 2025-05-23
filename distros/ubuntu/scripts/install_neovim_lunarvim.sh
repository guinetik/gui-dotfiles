#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../../../common/utils.sh"

# Install Neovim and LunarVim
print_info "Installing Neovim and LunarVim..."

# Create installation tracking directory
mkdir -p "$HOME/.local/share/gui-dotfiles"

# Check for required dependencies
print_info "Checking for dependencies..."

# Check if Rust is available or install it
if ! command -v cargo &> /dev/null; then
    print_info "Rust/Cargo is required for LunarVim. Installing Rust..."
    if ask_yes_no "Do you want to install Rust (required for LunarVim)?" "y"; then
        # Try to use the Rust dev environment if available
        if [ -f "$SCRIPT_DIR/../../../dev/rust/install_rustup.sh" ]; then
            print_info "Using Rust installer from dev environment..."
            bash "$SCRIPT_DIR/../../../dev/rust/install_rustup.sh"
        else
            # Fallback to the utility function
            ensure_rust
        fi

        if [ $? -ne 0 ]; then
            print_error "Rust installation failed! LunarVim requires Rust to build some components."
            if ! ask_yes_no "Do you want to continue anyway?" "n"; then
                exit 1
            fi
        fi
    else
        print_warning "Rust installation skipped. Some LunarVim components may fail to install."
    fi
fi

# Use the common scripts with proper error checking
print_info "Installing Neovim..."
bash "$SCRIPT_DIR/../../../common/install_neovim.sh"
if [ $? -ne 0 ]; then
    print_error "Neovim installation failed!"
    exit 1
fi

print_info "Installing LunarVim..."
bash "$SCRIPT_DIR/../../../common/install_lunarvim.sh"
if [ $? -ne 0 ]; then
    print_error "LunarVim installation failed!"
    exit 1
fi

print_info "Setting up LunarVim configuration..."
bash "$SCRIPT_DIR/../../../common/setup_lunarvim_config.sh"
if [ $? -ne 0 ]; then
    print_error "LunarVim configuration failed!"
    exit 1
fi

print_success "Neovim and LunarVim installation completed successfully!"