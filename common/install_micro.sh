#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Install micro editor
print_info "Installing micro (modern terminal editor)..."

# Check if already installed
if is_app_installed "micro"; then
  version=$(get_installed_version "micro")
  print_info "micro is already installed (version $version)"
  print_info "To reinstall, remove ~/.local/share/gui-dotfiles/micro.info"

  # Check if micro executable exists
  if ! command -v micro &> /dev/null; then
    print_warning "micro is tracked as installed but command is not found. Reinstalling..."
  else
    print_success "micro installation verified."
    exit 0
  fi
fi

# Create temporary directory for installation
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Download and install micro
print_info "Downloading micro from getmic.ro..."
if curl https://getmic.ro | bash; then
  print_success "micro downloaded successfully"
else
  print_error "Failed to download micro"
  rm -rf "$TEMP_DIR"
  exit 1
fi

# Move to /usr/local/bin
print_info "Installing micro to /usr/local/bin..."
/usr/bin/sudo mv micro /usr/local/bin/
/usr/bin/sudo chmod +x /usr/local/bin/micro

# Clean up temp directory
cd - > /dev/null
rm -rf "$TEMP_DIR"

# Verify installation
if verify_installation "micro" "command -v micro"; then
  micro_version=$(micro --version 2>&1 | head -1 | grep -oP 'Version: \K[0-9.]+' || echo "unknown")
  create_install_tracker "micro" "$HOME/.local/share/gui-dotfiles" "$micro_version"
  print_success "micro installed successfully!"
  print_info "micro version: $micro_version"

  # Configure micro
  print_info "Configuring micro editor..."

  # Get the repository root directory
  repo_root=""
  current_dir="$SCRIPT_DIR"

  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/common" ]; then
      repo_root="$current_dir"
      break
    fi
    current_dir="$(cd "$current_dir/.." && pwd)"
  done

  if [ -z "$repo_root" ]; then
    print_error "Could not find repository root directory"
    print_warning "Skipping micro configuration"
  else
    # Create micro config directory
    mkdir -p "$HOME/.config/micro"

    # Symlink settings.json from dotfiles
    settings_source="$repo_root/micro/settings.json"
    settings_target="$HOME/.config/micro/settings.json"

    if [ -f "$settings_source" ]; then
      # Remove existing file/link
      rm -f "$settings_target"

      # Create symlink
      ln -s "$settings_source" "$settings_target"
      print_success "micro configured with darcula theme"
      print_info "Settings symlinked from $settings_source"
    else
      print_warning "Settings file not found at $settings_source"
    fi
  fi

  # Set dark theme (darcula is a popular dark theme)
  print_info "Installing darcula theme..."
  micro --plugin install darcula 2>/dev/null || print_warning "Could not auto-install darcula theme"

  # Ask if user wants to set micro as default editor
  echo ""
  if ask_yes_no "Set micro as your default editor (EDITOR environment variable)?" "y"; then
    # Add to shell profiles
    profile_marker="# EDITOR - Set by micro installer"

    # Update .bashrc
    if [ -f "$HOME/.bashrc" ]; then
      if ! grep -q "export EDITOR=micro" "$HOME/.bashrc"; then
        # Remove old EDITOR settings
        sed -i '/^export EDITOR=/d' "$HOME/.bashrc"
        echo "" >> "$HOME/.bashrc"
        echo "$profile_marker" >> "$HOME/.bashrc"
        echo "export EDITOR=micro" >> "$HOME/.bashrc"
        print_success "Updated .bashrc with EDITOR=micro"
      fi
    fi

    # Update .zshrc
    if [ -f "$HOME/.zshrc" ]; then
      if ! grep -q "export EDITOR=micro" "$HOME/.zshrc"; then
        # Remove old EDITOR settings
        sed -i '/^export EDITOR=/d' "$HOME/.zshrc"
        echo "" >> "$HOME/.zshrc"
        echo "$profile_marker" >> "$HOME/.zshrc"
        echo "export EDITOR=micro" >> "$HOME/.zshrc"
        print_success "Updated .zshrc with EDITOR=micro"
      fi
    fi

    export EDITOR=micro
    print_success "Default editor set to micro!"
  else
    print_info "Keeping current default editor"
  fi

  echo ""
  print_info "Quick start:"
  print_info "  micro <filename>  - Edit a file"
  print_info "  Ctrl+Q            - Quit"
  print_info "  Ctrl+S            - Save"
  print_info "  Ctrl+E            - Command menu"
  print_info "  Ctrl+G            - Help"
  print_info ""
  print_info "Full documentation: https://github.com/zyedidia/micro"
else
  print_error "micro installation failed!"
  exit 1
fi
