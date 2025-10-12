#!/bin/bash
set -eo pipefail  # Exit on error, pipefail

# Error handling
handle_error() {
  local line=$1
  local command=$2
  local code=$3
  echo "Error in line $line: Command '$command' exited with status $code"
  exit $code
}
trap 'handle_error ${LINENO} "$BASH_COMMAND" $?' ERR

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/common/utils.sh"

# Global variables
FORCE_FLAG=""
YOLO_FLAG=""
DISTRO=""
DISTRO_VERSION=""
USAGE="Usage: $0 [--force] [--yolo]
Options:
  --force    Force reinstallation of all components regardless of installation status
  --yolo     Install everything without asking for confirmations ('You Only Live Once' mode)
  --help     Show this help message
"

#
# Main function - Primary installation flow
#
main() {
  # Parse command line arguments
  parse_arguments "$@"
  
  # Print header and initialize
  print_header "GUI Dotfiles Installer"
  init_install_tracking
  
  # Detect Linux distribution
  detect_distribution
  print_success "Detected distribution: ${DISTRO} ${DISTRO_VERSION}"
  
  # Display active modes
  show_active_modes
  
  # Install based on detected distribution
  install_for_distribution
  
  # Print completion message
  show_completion_message
}

#
# Parse command line arguments
#
parse_arguments() {
  for arg in "$@"; do
    case $arg in
      --force)
        FORCE_FLAG="--force"
        shift
        ;;
      --yolo)
        YOLO_FLAG="--yolo"
        shift
        ;;
      --help)
        echo "$USAGE"
        exit 0
        ;;
      *)
        # Unknown option
        echo "Unknown option: $arg"
        echo "$USAGE"
        exit 1
        ;;
    esac
  done
}

#
# Detect Linux distribution
#
detect_distribution() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    DISTRO_VERSION=$VERSION_ID
  else
    print_error "Unable to determine Linux distribution."
    exit 1
  fi
}

#
# Show active install modes
#
show_active_modes() {
  if [[ "$FORCE_FLAG" == "--force" ]]; then
    print_warning "Force mode enabled. Will re-run all installation steps regardless of previous runs."
  fi

  if [[ "$YOLO_FLAG" == "--yolo" ]]; then
    print_warning "YOLO mode enabled. Will install all components without asking for confirmation."
  fi
}

#
# Install based on distribution
#
install_for_distribution() {
  case "$DISTRO" in
    ubuntu|debian|pop|linuxmint|elementary)
      print_info "Running Ubuntu/Debian installer..."
      cd distros/ubuntu && bash install.sh $FORCE_FLAG $YOLO_FLAG
      ;;
    arch|manjaro|endeavouros)
      print_info "Running Arch installer..."
      cd distros/arch && bash install.sh $FORCE_FLAG $YOLO_FLAG
      ;;
    fedora)
      print_error "Fedora is not supported yet."
      print_info "You could contribute by adding Fedora support!"
      exit 1
      ;;
    *)
      print_error "Unsupported distribution: ${DISTRO}"
      print_info "Currently supported distributions:"
      echo "- Ubuntu/Debian-based (ubuntu, debian, pop, linuxmint, elementary)"
      echo "- Arch-based (arch, manjaro, endeavouros)"
      echo ""
      print_info "You could contribute by adding support for your distribution!"
      exit 1
      ;;
  esac
}

#
# Show completion message
#
show_completion_message() {
  print_header "Installation Complete!"

  # Get installed component count
  COMPONENT_COUNT=$(grep -v "^#" "$INSTALL_MASTER_FILE" | wc -l)

  print_success "GUI Dotfiles installed successfully!"
  print_info "Installed ${COMPONENT_COUNT} components/scripts"
  print_info ""
  print_info "To reinstall or update in the future, run with options:"
  print_info "./install.sh --force    # Force reinstall all components"
  print_info "./install.sh --yolo     # Install everything without prompts"
  print_info "./install.sh --force --yolo  # Reinstall everything automatically"
  echo ""

  # Offer to restart the shell to apply all changes
  print_warning "A shell restart is recommended to apply all configurations."
  echo ""
  if ask_yes_no "Restart your shell now to apply all changes?" "y"; then
    print_info "Restarting shell..."
    exec "$SHELL" -l
  else
    print_info "Please restart your shell manually or run:"
    print_info "source ~/.bashrc  # or ~/.zshrc"
  fi
}

# Run the main function
main "$@"