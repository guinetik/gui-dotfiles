#!/bin/bash

# Guinetik Backend Provisioning Script
# Sets up environment variables and utilities for Guinetik infrastructure
# Can be run interactively or in CI mode (--ci)

set -e

# Source common utilities if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
if [ -f "$SCRIPT_DIR/utils.sh" ]; then
  source "$SCRIPT_DIR/utils.sh"
else
  # Fallback print functions if utils.sh not available
  print_info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
  print_success() { echo -e "\033[0;32m[SUCCESS]\033[0m $1"; }
  print_warning() { echo -e "\033[0;33m[WARNING]\033[0m $1"; }
  print_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }
  print_header() { echo -e "\n\033[1;36m=== $1 ===\033[0m\n"; }
fi

# Configuration markers for idempotent updates
MARKER_BEGIN="# BEGIN GUINETIK CONFIG"
MARKER_END="# END GUINETIK CONFIG"

# CI mode flag
CI_MODE=false

# Parse arguments
for arg in "$@"; do
  case $arg in
    --ci)
      CI_MODE=true
      print_info "Running in CI mode (non-interactive)"
      ;;
  esac
done

# Determine which shell profile to use
detect_shell_profile() {
  if [ -n "$ZSH_VERSION" ] || [ "$SHELL" = "$(which zsh 2>/dev/null)" ]; then
    echo "$HOME/.zshrc"
  else
    echo "$HOME/.bashrc"
  fi
}

PROFILE_FILE=$(detect_shell_profile)

# Prompt for a value with current value display
# Usage: prompt_value "VAR_NAME" "Description" "default_value" "current_value"
prompt_value() {
  local var_name="$1"
  local description="$2"
  local default_value="$3"
  local current_value="$4"

  if [ "$CI_MODE" = true ]; then
    if [ -n "$current_value" ]; then
      echo "$current_value"
    elif [ -n "$default_value" ]; then
      echo "$default_value"
    else
      print_error "CI mode: $var_name is required but not set"
      exit 1
    fi
    return
  fi

  echo "" >/dev/tty
  print_info "$var_name" >/dev/tty
  echo "  Purpose: $description" >/dev/tty

  if [ -n "$default_value" ]; then
    echo "  Default: $default_value" >/dev/tty
  fi

  if [ -n "$current_value" ]; then
    echo "  Current: $current_value" >/dev/tty
    echo -n "  New value (press Enter to keep current, 'cancel' to abort): " >/dev/tty
  else
    if [ -n "$default_value" ]; then
      echo -n "  Enter value (press Enter for default): " >/dev/tty
    else
      echo -n "  Enter value: " >/dev/tty
    fi
  fi

  read -r input </dev/tty

  if [ "$input" = "cancel" ]; then
    print_warning "Setup cancelled by user" >/dev/tty
    exit 0
  fi

  if [ -z "$input" ]; then
    if [ -n "$current_value" ]; then
      echo "$current_value"
    elif [ -n "$default_value" ]; then
      echo "$default_value"
    else
      # Required field with no value
      print_error "$var_name is required" >/dev/tty
      prompt_value "$var_name" "$description" "$default_value" "$current_value"
    fi
  else
    echo "$input"
  fi
}

# Prompt for password (hidden input)
prompt_password() {
  local var_name="$1"
  local description="$2"
  local current_value="$3"

  if [ "$CI_MODE" = true ]; then
    if [ -n "$current_value" ]; then
      echo "$current_value"
    else
      print_error "CI mode: $var_name is required but not set"
      exit 1
    fi
    return
  fi

  echo "" >/dev/tty
  print_info "$var_name" >/dev/tty
  echo "  Purpose: $description" >/dev/tty
  print_warning "  ⚠️  Password will be stored in plaintext in $PROFILE_FILE" >/dev/tty
  print_warning "  ⚠️  TODO: Migrate to Bitwarden Secrets Manager (BWS) for secure storage" >/dev/tty

  if [ -n "$current_value" ]; then
    echo "  Current: [hidden]" >/dev/tty
    echo -n "  New password (press Enter to keep current, 'cancel' to abort): " >/dev/tty
  else
    echo -n "  Enter password: " >/dev/tty
  fi

  read -rs input </dev/tty
  echo "" >/dev/tty

  if [ "$input" = "cancel" ]; then
    print_warning "Setup cancelled by user" >/dev/tty
    exit 0
  fi

  if [ -z "$input" ]; then
    if [ -n "$current_value" ]; then
      echo "$current_value"
    else
      print_error "$var_name is required" >/dev/tty
      prompt_password "$var_name" "$description" "$current_value"
    fi
  else
    echo "$input"
  fi
}

# Handle SSH key setup with copy and permissions
prompt_ssh_key() {
  local var_name="$1"
  local description="$2"
  local current_value="$3"

  if [ "$CI_MODE" = true ]; then
    if [ -n "$current_value" ]; then
      if [ -f "$current_value" ]; then
        echo "$current_value"
        return
      else
        print_error "CI mode: $var_name points to non-existent file: $current_value"
        exit 1
      fi
    else
      print_error "CI mode: $var_name is required but not set"
      exit 1
    fi
  fi

  echo "" >/dev/tty
  print_info "$var_name" >/dev/tty
  echo "  Purpose: $description" >/dev/tty

  if [ -n "$current_value" ]; then
    if [ -f "$current_value" ]; then
      echo "  Current: $current_value (exists)" >/dev/tty
    else
      echo "  Current: $current_value (NOT FOUND)" >/dev/tty
    fi
    echo -n "  New path (press Enter to keep current, 'cancel' to abort): " >/dev/tty
  else
    echo -n "  Enter SSH key path: " >/dev/tty
  fi

  read -r input </dev/tty

  if [ "$input" = "cancel" ]; then
    print_warning "Setup cancelled by user" >/dev/tty
    exit 0
  fi

  # Determine the key path
  local key_path
  if [ -z "$input" ]; then
    if [ -n "$current_value" ]; then
      key_path="$current_value"
    else
      print_error "$var_name is required" >/dev/tty
      prompt_ssh_key "$var_name" "$description" "$current_value"
      return
    fi
  else
    key_path="$input"
  fi

  # Expand tilde
  key_path="${key_path/#\~/$HOME}"

  # Validate file exists
  if [ ! -f "$key_path" ]; then
    print_error "File not found: $key_path" >/dev/tty
    prompt_ssh_key "$var_name" "$description" "$current_value"
    return
  fi

  # Check if already in ~/.ssh/
  if [[ "$key_path" == "$HOME/.ssh/"* ]]; then
    # Already in .ssh, just fix permissions
    chmod 600 "$key_path"
    print_success "SSH key permissions set to 600" >/dev/tty
    echo "$key_path"
    return
  fi

  # Offer to copy to ~/.ssh/
  echo -n "  Copy to ~/.ssh/ for proper SSH usage? (y/n): " >/dev/tty
  read -r copy_choice </dev/tty

  if [[ "$copy_choice" =~ ^[Yy]$ ]]; then
    local key_name=$(basename "$key_path")
    local dest_path="$HOME/.ssh/$key_name"

    # Create .ssh dir if needed
    mkdir -p "$HOME/.ssh"

    # Copy and set permissions
    cp "$key_path" "$dest_path"
    chmod 600 "$dest_path"
    print_success "Copied to $dest_path with permissions 600" >/dev/tty
    echo "$dest_path"
  else
    # Use original path but warn about permissions
    chmod 600 "$key_path" 2>/dev/null || print_warning "Could not set permissions on $key_path (may need sudo)" >/dev/tty
    echo "$key_path"
  fi
}

# Main setup
main() {
  print_header "Guinetik Backend Provisioning"

  if [ "$CI_MODE" = false ]; then
    echo "This script will configure your Guinetik backend environment."
    echo "You can type 'cancel' at any prompt to abort."
    echo ""
  fi

  # Load current values from environment only (don't source profile to avoid hangs)
  # Just check if variables are already set in current environment
  # source "$PROFILE_FILE" 2>/dev/null || true

  # Collect all values
  print_header "Environment Configuration"

  GUINETIK_ROOT=$(prompt_value "GUINETIK_ROOT" \
    "Your local Guinetik project root directory" \
    "" \
    "${GUINETIK_ROOT:-}" | xargs)

  DOCKERC=$(prompt_value "DOCKERC" \
    "Docker Compose command (usually 'docker compose' or 'docker-compose')" \
    "docker compose" \
    "${DOCKERC:-}" | xargs)

  GUINETIK_SERVER=$(prompt_value "GUINETIK_SERVER" \
    "Your backend server IP address or hostname" \
    "" \
    "${GUINETIK_SERVER:-}" | xargs)

  GUINETIK_KEY=$(prompt_ssh_key "GUINETIK_KEY" \
    "SSH private key for server access" \
    "${GUINETIK_KEY:-}" | xargs)

  GUINETIK_LOGIN=$(prompt_value "GUINETIK_LOGIN" \
    "Your Guinetik API email/username" \
    "" \
    "${GUINETIK_LOGIN:-}" | xargs)

  GUINETIK_PASSWORD=$(prompt_password "GUINETIK_PASSWORD" \
    "Your Guinetik API password" \
    "${GUINETIK_PASSWORD:-}" | xargs)

  GUINETIK_API_URL=$(prompt_value "GUINETIK_API_URL" \
    "Your Guinetik API endpoint URL" \
    "https://api.guinetik.com" \
    "${GUINETIK_API_URL:-}" | xargs)

  BWS_ACCESS_TOKEN=$(prompt_value "BWS_ACCESS_TOKEN" \
    "Bitwarden Secrets Manager access token (get from vault.bitwarden.com)" \
    "" \
    "${BWS_ACCESS_TOKEN:-}" | xargs)

  # Validate and show summary
  echo ""
  print_info "Configuration Summary:"
  echo "  GUINETIK_ROOT: $GUINETIK_ROOT"
  echo "  DOCKERC: $DOCKERC"
  echo "  GUINETIK_SERVER: $GUINETIK_SERVER"
  echo "  GUINETIK_KEY: $GUINETIK_KEY"
  if [ -f "$GUINETIK_KEY" ]; then
    echo "    ✓ Key file exists"
  else
    print_warning "    ⚠️  Key file not found at this path!"
  fi
  echo "  GUINETIK_LOGIN: $GUINETIK_LOGIN"
  echo "  GUINETIK_PASSWORD: [hidden]"
  echo "  GUINETIK_API_URL: $GUINETIK_API_URL"
  echo "  BWS_ACCESS_TOKEN: ${BWS_ACCESS_TOKEN:0:20}..." # Show first 20 chars
  echo ""

  # Generate profile content
  print_header "Writing Configuration"

  local config_content="$MARKER_BEGIN
# Guinetik Backend Configuration
# Generated by install_guinetik.sh

# Project root directory
export GUINETIK_ROOT=\"$GUINETIK_ROOT\"

# Docker compose command
export DOCKERC=\"$DOCKERC\"

# Server connection details
export GUINETIK_SERVER=\"$GUINETIK_SERVER\"
export GUINETIK_KEY=\"$GUINETIK_KEY\"

# API credentials
export GUINETIK_LOGIN=\"$GUINETIK_LOGIN\"
export GUINETIK_PASSWORD=\"$GUINETIK_PASSWORD\"
export GUINETIK_API_URL=\"$GUINETIK_API_URL\"

# Bitwarden Secrets Manager token
export BWS_ACCESS_TOKEN=\"$BWS_ACCESS_TOKEN\"

# API token (generated at runtime by guinetik-login)
export GUINETIK_API_TOKEN=\"\"

# SSH helper function
guinetikssh() {
    if [ -n \"\$1\" ]; then
        ssh -i \"\$GUINETIK_KEY\" \"root@\$GUINETIK_SERVER\" \"\$@\"
    else
        ssh -i \"\$GUINETIK_KEY\" \"root@\$GUINETIK_SERVER\"
    fi
}
alias guinetikssh=\"guinetikssh\"

# API login function
guinetik-login() {
  if [[ -z \"\$GUINETIK_LOGIN\" || -z \"\$GUINETIK_PASSWORD\" || -z \"\$GUINETIK_API_URL\" ]]; then
    echo \"⚠️  Missing one or more required environment variables:\"
    echo \"    GUINETIK_LOGIN, GUINETIK_PASSWORD, GUINETIK_API_URL\"
    return 1
  fi

  local response token
  response=\$(curl -s -X POST \"\$GUINETIK_API_URL/auth/login-email\" \\
    -H \"Content-Type: application/json\" \\
    -d \"{\\\\"email\\\\":\\\"\$GUINETIK_LOGIN\\\\",\\\\"password\\\\":\\\"\$GUINETIK_PASSWORD\\\\"}\")

  token=\$(echo \"\$response\" | jq -r '.token // empty')

  if [[ -n \"\$token\" ]]; then
    export GUINETIK_API_TOKEN=\"\$token\"
    echo \"✅ Login successful. Token saved to \\\$GUINETIK_API_TOKEN\"
  else
    echo \"❌ Login failed.\"
    echo \"\$response\"
    return 1
  fi
}

alias guinetikapi=\"guinetik-login\"
$MARKER_END"

  # Remove old config if exists and append new
  if grep -q "$MARKER_BEGIN" "$PROFILE_FILE" 2>/dev/null; then
    print_info "Updating existing configuration in $PROFILE_FILE"
    # Remove old config between markers
    sed -i "/$MARKER_BEGIN/,/$MARKER_END/d" "$PROFILE_FILE"
  else
    print_info "Adding new configuration to $PROFILE_FILE"
  fi

  echo "$config_content" >> "$PROFILE_FILE"
  print_success "Configuration written to $PROFILE_FILE"

  # Don't source the profile automatically to avoid hangs from other initializations
  # The user can manually source it or restart their shell
  print_info "To apply changes, restart your shell or run: source $PROFILE_FILE"

  # Offer to test the API connection
  if [ "$CI_MODE" = false ]; then
    echo ""
    echo -n "Test API connection now? (y/n): "
    read -r test_choice

    if [[ "$test_choice" =~ ^[Yy]$ ]]; then
      print_info "Testing API login..."
      if guinetik-login; then
        print_success "API connection test successful!"
      else
        print_warning "API connection test failed (but configuration is saved)"
      fi
    fi
  fi

  print_header "Setup Complete!"
  echo ""
  print_success "Guinetik backend environment configured successfully!"
  echo ""
  print_info "Available commands:"
  echo "  guinetikssh         - SSH into your Guinetik server"
  echo "  guinetik-login      - Authenticate and get API token"
  echo "  guinetikapi         - Alias for guinetik-login"
  echo ""
  print_info "Restart your shell or run: source $PROFILE_FILE"
  echo ""
}

# Run main
main "$@"
