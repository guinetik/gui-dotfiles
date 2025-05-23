#!/bin/bash

# Source common utilities
RUSTUP_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$RUSTUP_SCRIPT_DIR/../../common/utils.sh"

# Install Rustup and Rust toolchain
print_info "Installing Rustup and Rust toolchain..."

# Check if Rust is already installed
if command -v rustc &> /dev/null && command -v cargo &> /dev/null; then
    print_info "Rust and Cargo are already installed:"
    rustc --version
    cargo --version
    
    # Update if already installed
    print_info "Updating Rust toolchain..."
    rustup update
else
    print_info "Installing Rust with Rustup..."
    
    # Install Rust using rustup
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    
    # Add Rust to current path for this session
    source "$HOME/.cargo/env"
    
    # Verify installation
    if command -v rustc &> /dev/null && command -v cargo &> /dev/null; then
        print_success "Rust and Cargo installed successfully!"
        rustc --version
        cargo --version
        create_install_tracker "rust" "$HOME/.local/share/gui-dotfiles" "$(rustc --version | cut -d' ' -f2)"
    else
        print_error "Failed to install Rust and Cargo"
        exit 1
    fi
fi

# Add Rust to path in bashrc if not already there
if ! grep -q 'source "$HOME/.cargo/env"' ~/.bashrc; then
    print_info "Adding Rust to PATH in ~/.bashrc"
    echo 'source "$HOME/.cargo/env"' >> ~/.bashrc
fi

print_success "Rustup installation completed successfully!"
exit 0