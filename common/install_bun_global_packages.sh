#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Install global Bun packages
print_info "Installing global Bun packages..."

# Check for YOLO mode from parent process
YOLO_MODE="${YOLO_MODE:-false}"

# Check if Bun is installed
if ! command -v bun &> /dev/null; then
  print_error "Bun is not installed. Please install Bun first."
  print_info "Run the Bun development environment installer to set up Bun."
  exit 1
fi

print_info "Using Bun $(bun --version)"
echo ""

# Define global Bun packages to install
# Format: "package-name|binary-name|description"
# If binary-name is empty, it defaults to package-name
BUN_PACKAGES=(
  "https://github.com/tobi/qmd|qmd|QMD - Local markdown search engine"
)

# Function to install a single Bun package
install_bun_package() {
  local pkg_entry="$1"

  # Parse the package entry
  IFS='|' read -r pkg_name binary_name description <<< "$pkg_entry"

  # Set defaults
  binary_name=${binary_name:-$pkg_name}
  description=${description:-$pkg_name}

  # Check if already installed
  local tracker_id="bun-global-${binary_name}"

  if is_app_installed "$tracker_id"; then
    version=$(get_installed_version "$tracker_id")
    print_info "$binary_name is already installed (version $version)"

    # Verify executable exists
    if ! command -v "$binary_name" &> /dev/null; then
      print_warning "$binary_name is tracked as installed but command not found. Reinstalling..."
    else
      print_success "$binary_name installation verified."
      return 0
    fi
  fi

  # Install the package
  print_info "Installing $binary_name via Bun..."
  if bun install -g "$pkg_name"; then
    # Get version
    if command -v "$binary_name" &> /dev/null; then
      pkg_version=$("$binary_name" --version 2>/dev/null | head -1 || echo "installed")
      create_install_tracker "$tracker_id" "$HOME/.local/share/gui-dotfiles" "$pkg_version"
      print_success "$binary_name installed successfully! (version $pkg_version)"
    else
      create_install_tracker "$tracker_id" "$HOME/.local/share/gui-dotfiles" "installed"
      print_success "$binary_name installed successfully!"
    fi
    return 0
  else
    print_error "Failed to install $binary_name"
    return 1
  fi
}

# Install packages
if [ ${#BUN_PACKAGES[@]} -eq 0 ]; then
  print_warning "No Bun packages configured for installation."
  print_info "Edit this script to add packages to the BUN_PACKAGES array."
  print_info "Format: \"package-name|binary-name|description\""
  exit 0
fi

print_section "Global Bun Packages"

for pkg_entry in "${BUN_PACKAGES[@]}"; do
  # Parse for display
  IFS='|' read -r pkg_name binary_name description <<< "$pkg_entry"
  description=${description:-$pkg_name}

  # Check if already installed and skip confirmation
  local tracker_id="bun-global-${binary_name}"
  if is_app_installed "$tracker_id"; then
    install_bun_package "$pkg_entry"
    continue
  fi

  # Ask for confirmation unless in YOLO mode
  if [ "$YOLO_MODE" = "true" ]; then
    install_bun_package "$pkg_entry"
  else
    if ask_yes_no "Install $description?" "y"; then
      install_bun_package "$pkg_entry"
    else
      print_info "Skipping $binary_name"
    fi
  fi
done

print_success "Global Bun packages installation completed!"
