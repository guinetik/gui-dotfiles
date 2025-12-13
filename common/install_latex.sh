#!/bin/bash

# Install LaTeX (TeX Live) - document preparation system
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/utils.sh"

print_info "Installing LaTeX (TeX Live document preparation system)..."

# Check if already installed
if is_app_installed "texlive"; then
  version=$(get_installed_version "texlive")
  print_info "LaTeX (TeX Live) is already installed (version $version)"

  if ! command -v pdflatex &> /dev/null; then
    print_warning "LaTeX tracked but not found. Reinstalling..."
  else
    print_success "LaTeX installation verified."
    exit 0
  fi
fi

# Install minimal TeX Live distribution
# Full distribution is HUGE (~6GB), so we install the base packages
print_info "Installing TeX Live base distribution (minimal)..."
install_packages texlive-latex-base texlive-latex-recommended texlive-latex-extra

# Verify installation
if verify_installation "texlive" "command -v pdflatex" "--version"; then
  latex_version=$(pdflatex --version 2>&1 | head -1 | awk '{print $2}')
  create_install_tracker "texlive" "$HOME/.local/share/gui-dotfiles" "$latex_version"
  print_success "LaTeX (TeX Live) installed successfully!"
  print_info "Installed minimal TeX Live distribution for document preparation."
else
  print_error "LaTeX installation failed!"
  exit 1
fi
