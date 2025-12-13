#!/bin/bash

# Install Ollama - Local LLM inference engine
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/utils.sh"

print_info "Installing Ollama (Local LLM inference engine)..."

# Check if already installed
if is_app_installed "ollama"; then
  version=$(get_installed_version "ollama")
  print_info "Ollama is already installed (version $version)"

  if ! command -v ollama &> /dev/null; then
    print_warning "Ollama tracked but not found. Reinstalling..."
  else
    print_success "Ollama installation verified."
    exit 0
  fi
fi

# Ensure curl is available
ensure_command curl

print_info "Downloading and installing Ollama..."

# Use official Ollama installer
if ! curl -fsSL https://ollama.ai/install.sh | sh; then
  print_error "Failed to download/install Ollama"
  exit 1
fi

# Verify installation
if verify_installation "ollama" "command -v ollama" "--version"; then
  ollama_version=$(ollama --version 2>/dev/null | head -1)
  create_install_tracker "ollama" "$HOME/.local/share/gui-dotfiles" "$ollama_version"
  print_success "Ollama installed successfully!"
  print_info "Ollama version: $ollama_version"
  print_info ""
  print_info "Next steps:"
  print_info "1. Start Ollama service: ollama serve"
  print_info "2. In another terminal, pull a model: ollama pull <model-name>"
  print_info "3. Available models: https://ollama.ai/library"
  print_info ""
  print_info "Example: ollama pull mistral"
else
  print_error "Ollama installation failed!"
  exit 1
fi
