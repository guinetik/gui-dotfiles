#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Create required directories
mkdir -p ~/.config

# Create symlinks
print_info "Creating symlinks..."

# Define symlinks to create
SYMLINKS=(
  "../bash/.bashrc:$HOME/.bashrc"
  "../zsh/.zshrc:$HOME/.zshrc"
  "../zsh/.zshenv:$HOME/.zshenv"
  "../zsh/.zsh_plugins.txt:$HOME/.zsh_plugins.txt"
  "../starship/starship.toml:$HOME/.config/starship.toml"
  "../git/.gitconfig:$HOME/.gitconfig"
)

# Create symlinks
for symlink in "${SYMLINKS[@]}"; do
  IFS=':' read -r source target <<< "$symlink"
  
  # Get the absolute path
  source_path="$(cd "$SCRIPT_DIR/.." && pwd)/$source"
  
  # Create the symlink
  if [ -f "$source_path" ]; then
    print_info "Linking $source_path to $target"
    ln -sf "$source_path" "$target"
    if [ $? -eq 0 ]; then
      print_success "Created symlink: $target -> $source_path"
    else
      print_error "Failed to create symlink: $target"
    fi
  else
    print_warning "Source file not found: $source_path"
  fi
done

print_success "Symlinks created successfully!"