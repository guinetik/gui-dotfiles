#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../../common/utils.sh"

# Install Cargo tools
print_info "Installing Cargo tools for Rust development..."

# Ensure rustup is properly sourced
source "$HOME/.cargo/env" 2>/dev/null || true

# Check for Cargo
if ! command -v cargo &> /dev/null; then
    print_error "Cargo not found. Make sure Rust is installed first."
    return 1
fi

# Install basic Rust components
print_info "Installing Rust components (rustfmt, clippy)..."
rustup component add rustfmt clippy

# Define Cargo tools to install
CARGO_TOOLS=(
    "cargo-update:cargo-install-update"  # Keep cargo packages up to date
    "cargo-edit:cargo-add"               # Add dependencies from command line
    "cargo-watch:cargo-watch"            # Watch code for changes
    "cargo-audit:cargo-audit"            # Audit for security vulnerabilities
    "cargo-expand:cargo-expand"          # Show expanded macros
    "cargo-outdated:cargo-outdated"      # Show outdated dependencies
    "cargo-bloat:cargo-bloat"            # Find what takes most space
)

# Install each tool
for tool_entry in "${CARGO_TOOLS[@]}"; do
    # Split the entry into components
    IFS=':' read -r package_name binary_name <<< "$tool_entry"
    
    # Set defaults for empty fields
    binary_name=${binary_name:-$package_name}
    
    # Install the tool
    print_info "Installing $package_name..."
    if ! command -v $binary_name &> /dev/null; then
        cargo install $package_name
        
        if command -v $binary_name &> /dev/null; then
            print_success "$package_name installed successfully!"
            create_install_tracker "$package_name" "$HOME/.local/share/gui-dotfiles" "$(cargo install --list | grep $package_name | awk '{print $2}' | tr -d ':' || echo "installed")"
        else
            print_warning "Failed to install $package_name, continuing..."
        fi
    else
        print_info "$package_name is already installed."
    fi
done

print_success "Cargo tools installation completed successfully!"
return 0