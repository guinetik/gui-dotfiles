#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Install global npm packages
print_info "Installing global npm packages..."

# Check for YOLO mode from parent process
YOLO_MODE="${YOLO_MODE:-false}"

# Source NVM to ensure npm is available
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

# Check if Node.js and npm are installed
if ! command -v npm &> /dev/null; then
  print_error "npm is not installed. Please install Node.js first."
  print_info "Run the Node.js development environment installer to set up npm."
  exit 1
fi

print_info "Using Node.js $(node --version) and npm $(npm --version)"
echo ""

# Define global npm packages to install
# Format: "package-name:binary-name:description"
# If binary-name is empty, it defaults to package-name
NPM_PACKAGES=(
  "branchlet::Git Worktree Manager"
  "@anthropic-ai/claude-code:claude:Claude Code CLI"
)

# Function to install a single npm package
install_npm_package() {
  local pkg_entry="$1"

  # Parse the package entry
  IFS=':' read -r pkg_name binary_name description <<< "$pkg_entry"

  # Set defaults
  binary_name=${binary_name:-$pkg_name}
  description=${description:-$pkg_name}

  # Check if already installed
  local tracker_id="npm-global-${pkg_name//\//-}"  # Replace / with - for tracking

  if is_app_installed "$tracker_id"; then
    version=$(get_installed_version "$tracker_id")
    print_info "$pkg_name is already installed (version $version)"

    # Verify executable exists
    if ! command -v "$binary_name" &> /dev/null; then
      print_warning "$pkg_name is tracked as installed but '$binary_name' command not found. Reinstalling..."
    else
      print_success "$pkg_name installation verified."
      return 0
    fi
  fi

  # Install the package
  print_info "Installing $pkg_name..."
  if npm install -g "$pkg_name"; then
    # Get version
    if command -v "$binary_name" &> /dev/null; then
      pkg_version=$("$binary_name" --version 2>/dev/null | head -1 || echo "installed")
      create_install_tracker "$tracker_id" "$HOME/.local/share/gui-dotfiles" "$pkg_version"
      print_success "$pkg_name installed successfully! (version $pkg_version)"
    else
      create_install_tracker "$tracker_id" "$HOME/.local/share/gui-dotfiles" "installed"
      print_success "$pkg_name installed successfully!"
    fi
    return 0
  else
    print_error "Failed to install $pkg_name"
    return 1
  fi
}

# Install packages
if [ ${#NPM_PACKAGES[@]} -eq 0 ]; then
  print_warning "No npm packages configured for installation."
  print_info "Edit this script to add packages to the NPM_PACKAGES array."
  print_info "Format: \"package-name:binary-name:description\""
  exit 0
fi

print_section "Global NPM Packages"

for pkg_entry in "${NPM_PACKAGES[@]}"; do
  # Parse for display
  IFS=':' read -r pkg_name binary_name description <<< "$pkg_entry"
  description=${description:-$pkg_name}

  # Check if already installed and skip confirmation
  local tracker_id="npm-global-${pkg_name//\//-}"
  if is_app_installed "$tracker_id"; then
    install_npm_package "$pkg_entry"
    continue
  fi

  # Ask for confirmation unless in YOLO mode
  if [ "$YOLO_MODE" = "true" ]; then
    install_npm_package "$pkg_entry"
  else
    if ask_yes_no "Install $description ($pkg_name)?" "y"; then
      install_npm_package "$pkg_entry"
    else
      print_info "Skipping $pkg_name"
    fi
  fi
done

print_success "Global npm packages installation completed!"
