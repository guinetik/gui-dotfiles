#!/bin/bash

# Source common utilities
SYMLINKS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SYMLINKS_SCRIPT_DIR/utils.sh"

# Create required directories
mkdir -p ~/.config
mkdir -p ~/.config/shell
mkdir -p ~/.claude

# Create symlinks
print_info "Creating symlinks..."

LINKS_FILE="$(cd "$SYMLINKS_SCRIPT_DIR/.." && pwd)/linux/links.psv"
source "$(cd "$SYMLINKS_SCRIPT_DIR/.." && pwd)/shell/lib/psv.sh"

if [ ! -f "$LINKS_FILE" ]; then
  print_error "Link map not found: $LINKS_FILE"
  return 1 2>/dev/null || exit 1
fi

while IFS='|' read -r source target; do
  # Expand $HOME in the target without eval.
  target="${target/\$HOME/$HOME}"
  source_path="$(cd "$SYMLINKS_SCRIPT_DIR/.." && pwd)/$source"

  # -e not -f: some sources are directories (ai/claude/skills, ai/claude/commands).
  if [ -e "$source_path" ]; then
    print_info "Linking $source_path to $target"
    mkdir -p "$(dirname "$target")"
    # -n matters for directory targets. Without it, `ln -sf dir existing_dir`
    # creates the link INSIDE existing_dir instead of replacing it, which looks
    # like success and produces ~/.claude/skills/skills.
    if ln -sfn "$source_path" "$target"; then
      print_success "Created symlink: $target -> $source_path"
    else
      print_error "Failed to create symlink: $target"
    fi
  else
    print_warning "Source not found: $source_path"
  fi
done < <(psv_filter "$LINKS_FILE")

print_success "Symlinks created successfully!"
print_info "Shell aliases and functions are now available in both bash and zsh"
print_info "Run 'myenv' command to discover all installed tools and environment setup"
print_info "Run 'tradecraft' command to see working preferences and philosophy"
print_info "Modern CLI tools will be available after running install_modern_tools.sh"