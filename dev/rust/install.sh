#!/bin/bash

# Source common utilities
RUST_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$RUST_SCRIPT_DIR/../../common/utils.sh"

# Rust Development Environment Setup
print_info "Setting up Rust Development Environment..."

# Create installation tracking directory
mkdir -p "$HOME/.local/share/gui-dotfiles"

# Run individual installation scripts
print_info "Installing Rustup and Rust toolchain..."
bash "$RUST_SCRIPT_DIR/install_rustup.sh"
if [ $? -ne 0 ]; then
    print_error "Failed to install Rustup!"
    exit 1
fi

# Re-source cargo environment to ensure it's available
source "$HOME/.cargo/env" 2>/dev/null || true

# Ensure C compiler and Rust/Cargo are properly set up before installing further tools
print_info "Verifying C compiler and Rust installation..."
ensure_rust # This function now checks for cc and build-essential
if [ $? -ne 0 ]; then
    print_error "Rust environment (including C compiler) not properly set up by ensure_rust. Aborting Cargo tools installation."
    exit 1
fi

# Install Cargo tools
print_info "Installing Cargo tools..."
bash "$RUST_SCRIPT_DIR/install_cargo_tools.sh"
if [ $? -ne 0 ]; then
    print_error "Failed to install Cargo tools!"
    exit 1
fi

print_success "Rust Development Environment setup completed successfully!"
echo ""
print_info "Installed components:"
echo "- Rust (via rustup)"
echo "- Cargo (Rust package manager)"
echo "- rustfmt (code formatter)"
echo "- clippy (linter)"
echo "- cargo-update (for updating packages)"
echo "- cargo-edit (for managing dependencies)"
echo "- cargo-watch (for watching code changes)"
echo "- cargo-audit (for security audits)"
echo "- cargo-expand (for expanding macros)"
echo "- cargo-outdated (for checking outdated dependencies)"
echo "- cargo-bloat (for analyzing binary size)"
echo ""
print_info "You may need to restart your terminal or run the following to start using Rust:"
echo 'source "$HOME/.cargo/env"'