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
source "$SCRIPT_DIR/../../common/utils.sh"

# Global variables
FORCE_RUN="false"
YOLO_MODE="false"

#
# Main function - Primary installation flow
#
main() {
  # Print header and initialize
  print_header "GUI Dotfiles Installation (Ubuntu)"
  init_install_tracking
  
  # Process arguments
  parse_arguments "$@"
  
  # Install zsh and basic packages FIRST
  print_section "Installing Zsh and Basic Packages"
  run_script "install_packages.sh" "$FORCE_RUN"
  
  # Create symlinks for shell configuration files
  # This ensures .zsh_plugins.txt exists when we generate the plugin cache
  setup_symlinks

  # Configure shell (Zsh with Antidote) immediately after symlinks
  configure_shell
  
  # Essential CLI tools (excluding packages which were already installed)
  install_essential_tools
  
  # Additional CLI tools
  install_additional_tools

  # Multimedia & Document tools
  install_multimedia_tools

  # Infrastructure & Services
  install_infrastructure_services

  # Development environments
  install_development_environments

  # Global npm packages (requires Node.js)
  install_npm_global_packages

  # Global Bun packages (requires Bun)
  install_bun_global_packages

  # Editors and IDEs
  install_editors

  # Guinetik backend provisioning
  setup_guinetik_backend

  # Show completion summary
  show_completion_message
}

#
# Process command line arguments
#
parse_arguments() {
  # Process all arguments
  for arg in "$@"; do
    case $arg in
      --force)
        FORCE_RUN="true"
        print_warning "Force mode enabled. Will re-run all installation steps regardless of previous runs."
        ;;
      --yolo)
        YOLO_MODE="true"
        print_warning "YOLO mode enabled. Will install all components without asking for confirmation."
        ;;
    esac
  done
}

#
# Install essential CLI tools
#
install_essential_tools() {
  print_section "Installing Essential CLI Tools"
  
  # Essential installations (no confirmation needed)
  # Note: install_packages.sh is now run at the very beginning of main()
  run_script "install_eza.sh" "$FORCE_RUN"
  run_script "install_zoxide.sh" "$FORCE_RUN"
  run_script "install_ripgrep.sh" "$FORCE_RUN"
}

#
# Install additional CLI tools
#
install_additional_tools() {
  print_section "Additional CLI Tools"

  run_script_with_confirmation "install_tokei.sh" "Tokei (code statistics tool)" "y" "$FORCE_RUN"
  run_script_with_confirmation "install_modern_tools.sh" "Modern CLI replacements" "y" "$FORCE_RUN"
  run_script_with_confirmation "install_fzf_git.sh" "FZF + Git integration" "y" "$FORCE_RUN"
  run_script_with_confirmation "install_atuin.sh" "Atuin (shell history management)" "y" "$FORCE_RUN"
  run_script_with_confirmation "install_superfile.sh" "Superfile (terminal file manager)" "y" "$FORCE_RUN"
  run_script_with_confirmation "install_w3m.sh" "w3m (text-based web browser)" "y" "$FORCE_RUN"
  run_script_with_confirmation "install_googler.sh" "googler (Google search from CLI)" "y" "$FORCE_RUN"
  run_script_with_confirmation "install_starship.sh" "Starship prompt" "y" "$FORCE_RUN"
  run_script_with_confirmation "install_nushell.sh" "Nushell (modern shell)" "n" "$FORCE_RUN"
}

#
# Install multimedia and document tools
#
install_multimedia_tools() {
  print_section "Multimedia & Document Tools"

  run_script_with_confirmation "install_ffmpeg.sh" "FFmpeg (multimedia framework - video/audio processing)" "n" "$FORCE_RUN"
  run_script_with_confirmation "install_imagemagick.sh" "ImageMagick (image manipulation toolkit)" "n" "$FORCE_RUN"
  run_script_with_confirmation "install_latex.sh" "LaTeX (TeX Live - document preparation system)" "n" "$FORCE_RUN"
}

#
# Install infrastructure and services
#
install_infrastructure_services() {
  print_section "Infrastructure & Services"

  run_script_with_confirmation "install_docker.sh" "Docker Engine & Docker Compose" "y" "$FORCE_RUN"
  run_script_with_confirmation "install_ollama.sh" "Ollama (Local LLM inference engine)" "n" "$FORCE_RUN"
  run_script_with_confirmation "install_powershell.sh" "PowerShell (pwsh)" "n" "$FORCE_RUN"
  run_script_with_confirmation "install_bitwarden_bws.sh" "Bitwarden Secrets CLI (bws)" "n" "$FORCE_RUN"
  run_script_with_confirmation "install_openssh_server.sh" "OpenSSH Server" "n" "$FORCE_RUN"
}

#
# Install development environments
#
install_development_environments() {
  print_header "Development Environments"
  
  print_info "Select which development environments you'd like to install:"
  echo ""
  
  # Install development environments
  install_dev_with_confirmation "java" "Java" "n" "$FORCE_RUN"
  install_dev_with_confirmation "node" "Node.js" "n" "$FORCE_RUN"
  run_script_with_confirmation "install_bun.sh" "Bun (JavaScript/TypeScript runtime)" "n" "$FORCE_RUN"
  install_dev_with_confirmation "python" "Python" "n" "$FORCE_RUN"
  install_dev_with_confirmation "rust" "Rust" "n" "$FORCE_RUN"

  # Go/Golang
  run_script_with_confirmation "install_go.sh" "Go (Golang programming language)" "n" "$FORCE_RUN"
}

#
# Install global npm packages
#
install_npm_global_packages() {
  # Only run if Node.js was installed
  if ! command -v npm &> /dev/null && ! command -v node &> /dev/null; then
    print_info "Node.js is not installed. Skipping global npm packages."
    return 0
  fi

  local script_id="npm_global_packages"

  # Check if already run (unless force run)
  if [[ "$FORCE_RUN" != "true" ]] && should_skip_script "$script_id"; then
    print_info "Global npm packages already installed. Skipping."
    return 0
  fi

  print_section "Global NPM Packages"

  # Run the npm packages script with YOLO_MODE passed through
  export YOLO_MODE
  bash "../../common/install_npm_global_packages.sh"

  if [ $? -eq 0 ]; then
    mark_script_completed "$script_id" "1.0"
    return 0
  else
    print_warning "Some npm packages may have failed to install"
    return 0  # Don't fail the entire installation
  fi
}

#
# Install global Bun packages
#
install_bun_global_packages() {
  # Only run if Bun is installed
  if ! command -v bun &> /dev/null; then
    print_info "Bun is not installed. Skipping global Bun packages."
    return 0
  fi

  local script_id="bun_global_packages"

  # Check if already run (unless force run)
  if [[ "$FORCE_RUN" != "true" ]] && should_skip_script "$script_id"; then
    print_info "Global Bun packages already installed. Skipping."
    return 0
  fi

  # Run the Bun packages script with YOLO_MODE passed through
  export YOLO_MODE
  bash "../../common/install_bun_global_packages.sh"

  if [ $? -eq 0 ]; then
    mark_script_completed "$script_id" "1.0"
    return 0
  else
    print_warning "Some Bun packages may have failed to install"
    return 0  # Don't fail the entire installation
  fi
}

#
# Configure shell (Bash/Zsh)
#
configure_shell() {
  if ! should_skip_script "shell_configuration"; then
    configure_default_shell
    mark_script_completed "shell_configuration" "1.0"
  else
    print_info "Shell already configured. Skipping configuration."
  fi
}

#
# Install editors and IDEs
#
install_editors() {
  print_section "Editors and IDEs"

  run_script_with_confirmation "install_micro.sh" "Micro (modern terminal editor)" "y" "$FORCE_RUN"
  run_script_with_confirmation "install_neovim_lunarvim.sh" "Neovim & LunarVim" "n" "$FORCE_RUN"
}

#
# Setup symlinks for configuration files
#
setup_symlinks() {
  if [[ "$FORCE_RUN" == "true" ]] || ! should_skip_script "create_symlinks"; then
    print_info "Creating symlinks..."
    bash "../../common/create_symlinks.sh"
    if [ $? -eq 0 ]; then
      print_success "Completed: create_symlinks"
      mark_script_completed "create_symlinks" "1.0"
    else
      print_error "Failed: create_symlinks"
      exit 1
    fi
  else
    print_info "Symlinks already configured. Skipping."
  fi
}

#
# Setup Guinetik backend provisioning
#
setup_guinetik_backend() {
  local script_id="guinetik_backend_provisioning"

  # Check if already configured (unless force run)
  if [[ "$FORCE_RUN" != "true" ]] && should_skip_script "$script_id"; then
    print_info "Guinetik backend already provisioned. Skipping."
    return 0
  fi

  print_section "Guinetik Backend Provisioning"

  # In YOLO mode, skip this (too sensitive for auto-config)
  if [[ "$YOLO_MODE" == "true" ]]; then
    print_info "YOLO mode enabled but skipping Guinetik setup (requires manual configuration)"
    return 0
  fi

  if ask_yes_no "Do you want to provision Guinetik backend environment?" "n"; then
    print_info "Running Guinetik provisioning script..."

    # Get the repository root directory
    local repo_root=""
    local current_dir="$SCRIPT_DIR"

    while [ "$current_dir" != "/" ]; do
      if [ -d "$current_dir/common" ]; then
        repo_root="$current_dir"
        break
      fi
      current_dir="$(cd "$current_dir/.." && pwd)"
    done

    if [ -z "$repo_root" ]; then
      print_error "Could not find repository root directory"
      return 1
    fi

    local guinetik_script="$repo_root/common/install_guinetik.sh"

    if [ ! -f "$guinetik_script" ]; then
      print_error "Guinetik provisioning script not found: $guinetik_script"
      return 1
    fi

    # Run with explicit terminal for interactive input
    bash "$guinetik_script" </dev/tty

    if [ $? -eq 0 ]; then
      print_success "Guinetik backend provisioned successfully!"
      mark_script_completed "$script_id" "1.0"
      return 0
    else
      print_error "Guinetik backend provisioning failed"
      return 1
    fi
  else
    print_info "Skipping Guinetik backend provisioning"
    mark_script_completed "${script_id}_skipped" "1.0"
    return 0
  fi
}

#
# Show completion message and summary
#
show_completion_message() {
  print_header "Installation Complete!"
  print_success "Dotfiles installed successfully!"

  # Mark overall installation as completed
  mark_script_completed "ubuntu_dotfiles_installation" "1.0"

  # Display installation summary
  echo ""
  print_info "Installation Summary:"
  if command -v column &>/dev/null; then
    list_installed_components | grep -v "^#" | column -t -s"|"
  else
    list_installed_components | grep -v "^#"
  fi
  echo ""

  print_info "To reinstall or update, run with flags:"
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

# Function to run a script and log its execution
# First checks common/, then falls back to local scripts/
run_script() {
  local script=$1
  local force_run="${2:-false}"
  local script_id="ubuntu_scripts_${script%.*}"

  # Try common scripts first, then local scripts
  local script_path
  if [ -f "../../common/${script}" ]; then
    script_path="../../common/${script}"
  elif [ -f "./scripts/${script}" ]; then
    script_path="./scripts/${script}"
  else
    print_error "Script not found: ${script}"
    return 1
  fi

  # Check if script should be skipped (already completed)
  if [[ "$force_run" != "true" ]] && should_skip_script "$script_id"; then
    print_info "Skipping: ${script} (already completed)"
    return 0
  fi

  print_info "Running: ${script}"
  bash "$script_path"

  # Check if the script executed successfully
  if [ $? -eq 0 ]; then
    print_success "Completed: ${script}"
    # Mark script as completed in tracking system
    mark_script_completed "$script_id" "1.0"
    return 0
  else
    print_error "Failed: ${script}"
    return 1
  fi
}

# Run script with confirmation
run_script_with_confirmation() {
  local script=$1
  local description=$2
  local default=${3:-y}
  local script_id="ubuntu_scripts_${script%.*}"
  local force_run="${4:-false}"
  
  # Check if script should be skipped (already completed)
  if [[ "$force_run" != "true" ]] && should_skip_script "$script_id"; then
    print_info "Skipping: ${script} (already completed)"
    return 0
  fi
  
  if ask_yes_no "Do you want to install $description?" "$default"; then
    run_script "$script" "$force_run"
    return $?
  else
    print_info "Skipping installation of $description"
    # Still mark as completed but with "skipped" status
    mark_script_completed "${script_id}_skipped" "1.0"
    return 0
  fi
}

# Run dev environment installation
install_dev_environment() {
  local env=$1
  local description=$2
  local env_id="dev_environment_${env}"
  local force_run="${3:-false}"
  
  # Check if environment should be skipped (already completed)
  if [[ "$force_run" != "true" ]] && should_skip_script "$env_id"; then
    print_info "Skipping: $description environment (already installed)"
    return 0
  fi
  
  # Get the repository root directory - find it by looking for the dev directory
  local repo_root=""
  local current_dir="$SCRIPT_DIR"
  
  # Look for the repository root by checking for the dev directory
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/dev" ] && [ -d "$current_dir/common" ]; then
      repo_root="$current_dir"
      break
    fi
    current_dir="$(cd "$current_dir/.." && pwd)"
  done
  
  if [ -z "$repo_root" ]; then
    print_error "Could not find repository root directory"
    return 1
  fi
  
  local dev_script="$repo_root/dev/$env/install.sh"
  
  print_info "Installing $description development environment..."
  print_info "DEBUG: SCRIPT_DIR is: $SCRIPT_DIR"
  print_info "DEBUG: repo_root calculated as: $repo_root"
  print_info "DEBUG: Looking for script at: $dev_script"
  
  if [ ! -f "$dev_script" ]; then
    print_error "Development environment script not found: $dev_script"
    return 1
  fi
  
  bash "$dev_script"
  
  if [ $? -eq 0 ]; then
    print_success "$description environment installed successfully!"
    # Mark environment as completed in tracking system
    mark_script_completed "$env_id" "1.0"
    return 0
  else
    print_error "Failed to install $description environment"
    return 1
  fi
}

# Install development environment with confirmation
install_dev_with_confirmation() {
  local env=$1
  local description=$2
  local default=${3:-n}
  local env_id="dev_environment_${env}"
  local force_run="${4:-false}"
  
  # Check if environment should be skipped (already completed)
  if [[ "$force_run" != "true" ]] && should_skip_script "$env_id"; then
    print_info "Skipping: $description environment (already installed)"
    return 0
  fi
  
  if ask_yes_no "Do you want to install $description development environment?" "$default"; then
    install_dev_environment "$env" "$description" "$force_run"
    local result=$?
    
    # Special handling for Rust: source the environment immediately
    if [ $result -eq 0 ] && [ "$env" = "rust" ]; then
      print_info "Sourcing Rust environment for current session..."
      source "$HOME/.cargo/env" 2>/dev/null || true
      # Export RUST_INSTALLED flag for subsequent installers
      export RUST_INSTALLED_THIS_SESSION="true"
    fi
    
    # Special handling for Java: source the Jabba environment immediately
    if [ $result -eq 0 ] && [ "$env" = "java" ]; then
      print_info "Sourcing Java environment for current session..."
      source "$HOME/.jabba/jabba.sh" 2>/dev/null || true
      # Export JAVA_INSTALLED flag for subsequent installers
      export JAVA_INSTALLED_THIS_SESSION="true"
    fi
    
    # Export general flag for any dev environment installed this session
    if [ $result -eq 0 ]; then
      export "${env^^}_INSTALLED_THIS_SESSION"="true"
    fi
    
    return $result
  else
    print_info "Skipping installation of $description development environment"
    # Still mark as completed but with "skipped" status
    mark_script_completed "${env_id}_skipped" "1.0"
    return 0
  fi
}

# Function to configure default shell
configure_default_shell() {
  print_section "Shell Configuration"
  
  if ! command -v zsh &> /dev/null; then
    print_error "Zsh is not installed. Please make sure it was installed in the basic packages step."
    return 1
  fi
  
  # Check current shell
  current_shell=$(basename "$SHELL")
  
  # Make sure Antidote (Zsh plugin manager) is installed
  if [ ! -d "$HOME/.antidote" ]; then
    print_info "Installing Antidote (Zsh plugin manager)..."
    git clone --depth=1 https://github.com/mattmc3/antidote.git "$HOME/.antidote"
    if [ $? -eq 0 ]; then
      print_success "Antidote installed successfully."
    else 
      print_warning "Failed to install Antidote. Zsh will still work, but without plugins."
    fi
  else
    print_info "Antidote is already installed."
  fi
  
  # Pre-generate the static plugins file
  if [ -f "$HOME/.zsh_plugins.txt" ]; then
    if [ -d "$HOME/.antidote" ]; then
      print_info "Generating static plugins file..."
      zsh -c "source $HOME/.antidote/antidote.zsh && antidote bundle < $HOME/.zsh_plugins.txt > $HOME/.zsh_plugins.zsh"
      if [ $? -eq 0 ]; then
        print_success "Plugin file generated successfully."
      else
        print_warning "Failed to generate static plugins file. Will be generated on first shell startup."
      fi
    fi
  fi
  
  # Set default shell
  if [ "$current_shell" = "zsh" ]; then
    print_info "Zsh is already your default shell."
  else
    if ask_yes_no "Do you want to set Zsh as your default shell?" "y"; then
      # Get zsh path
      zsh_path=$(which zsh)
      
      # Add zsh to /etc/shells if not already there
      if ! grep -q "$zsh_path" /etc/shells; then
        print_info "Adding $zsh_path to /etc/shells"
        echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
      fi
      
      # Change default shell
      print_info "Changing default shell to Zsh..."
      chsh -s "$zsh_path"
      
      if [ $? -eq 0 ]; then
        print_success "Default shell changed to Zsh. You'll need to log out and log back in for the change to take effect."
      else
        print_error "Failed to change default shell. You can do it manually with: chsh -s $zsh_path"
      fi
    else
      print_info "Keeping $current_shell as default shell."
    fi
  fi
}

# Run the main function
main "$@"