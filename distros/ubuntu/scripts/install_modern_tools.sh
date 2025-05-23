#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../../../common/utils.sh"

# Install modern CLI tools
print_info "Installing modern CLI tools..."

# Define the tools to install with their details
# Format: "package_name:binary_name:github_repo:asset_pattern:cargo_name"
MODERN_TOOLS=(
  "fd-find:fd:sharkdp/fd:fd-v[0-9.]+-x86_64-unknown-linux-gnu\.tar\.gz:fd-find"
  "tealdeer:tldr:tealdeer-rs/tealdeer:tealdeer-linux-x86_64-musl"
  "git-delta:delta:dandavison/delta:delta-[0-9.]+-x86_64-unknown-linux-gnu\.tar\.gz:git-delta"
  "procs::dalance/procs:procs-v[0-9.]+-x86_64-linux\.zip"
  "du-dust:dust:bootandy/dust:dust-v[0-9.]+-x86_64-unknown-linux-gnu\.tar\.gz:du-dust"
  "bottom:btm:ClementTsang/bottom:bottom(-musl)?_[0-9.]+-1_amd64\.deb:bottom"
  "bandwhich::imsnif/bandwhich:bandwhich-v[0-9.]+-x86_64-unknown-linux-musl\.tar\.gz"
  "bat::sharkdp/bat:bat-v[0-9.]+-x86_64-unknown-linux-gnu\.tar\.gz"
)

# Install each tool
for tool_entry in "${MODERN_TOOLS[@]}"; do
  # Split the entry into components
  IFS=':' read -r package_name binary_name github_repo asset_pattern cargo_name specific_tag <<< "$tool_entry"
  
  # Set defaults for empty fields
  binary_name=${binary_name:-$package_name}
  cargo_name=${cargo_name:-$package_name}
  
  # Install the tool with fallbacks
  install_tool_with_fallbacks "$package_name" "$binary_name" "$github_repo" "$asset_pattern" "/usr/local/bin" "" "$cargo_name"
  
  # Handle special case for fd
  if [ "$package_name" = "fd-find" ] && command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
    print_info "Creating fd symlink for fdfind..."
    mkdir -p ~/.local/bin
    ln -sf $(which fdfind) ~/.local/bin/fd
    add_to_path "$HOME/.local/bin"
  fi
done

print_success "Modern CLI tools installation completed!"