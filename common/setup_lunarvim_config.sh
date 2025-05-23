#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Setup LunarVim configuration
print_info "Setting up LunarVim configuration..."

# Verify LunarVim is installed
if ! command -v lvim &> /dev/null; then
  print_error "LunarVim is not installed. Please install it first."
  exit 1
fi

# Create the LunarVim config directory if it doesn't exist
mkdir -p ~/.config/lvim

# Define source and target paths
config_source="$SCRIPT_DIR/../nvim/lunarvim/config.lua"
config_target="$HOME/.config/lvim/config.lua"

# Check if source file exists
if [ ! -f "$config_source" ]; then
  print_error "Configuration file not found: $config_source"
  exit 1
fi

# Copy the custom config to LunarVim's config location
print_info "Copying config.lua to ~/.config/lvim..."
cp "$config_source" "$config_target"

# Create a symbolic link to ensure future updates are reflected
print_info "Creating symlink for config.lua..."
ln -sf "$config_source" "$config_target"

if [ $? -eq 0 ]; then
  print_success "LunarVim configuration completed!"
  print_info "To use LunarVim, type 'lvim' in your terminal."
  print_info "First launch will install LSP servers and plugins, please be patient."
else
  print_error "Failed to create symlink for LunarVim configuration."
  exit 1
fi