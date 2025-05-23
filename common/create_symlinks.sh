#!/bin/bash

# Source common utilities
SYMLINKS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SYMLINKS_SCRIPT_DIR/utils.sh"

# Create required directories
mkdir -p ~/.config
mkdir -p ~/.config/shell

# Create symlinks
print_info "Creating symlinks..."

# Define symlinks to create
SYMLINKS=(
  "bash/.bashrc:$HOME/.bashrc"
  "zsh/.zshrc:$HOME/.zshrc"
  "zsh/.zshenv:$HOME/.zshenv"
  "zsh/.zsh_plugins.txt:$HOME/.zsh_plugins.txt"
  "shell/aliases.sh:$HOME/.config/shell/aliases.sh"
  "starship/starship.toml:$HOME/.config/starship.toml"
  "git/.gitconfig:$HOME/.gitconfig"
)

# Create symlinks
for symlink in "${SYMLINKS[@]}"; do
  IFS=':' read -r source target <<< "$symlink"
  
  # Get the absolute path
  source_path="$(cd "$SYMLINKS_SCRIPT_DIR/.." && pwd)/$source"
  
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
print_info "Shell aliases are now available in both bash and zsh"
print_info "Modern CLI tools will be available after running install_modern_tools.sh"