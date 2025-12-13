#!/bin/bash

# Install Go (Golang) - programming language and toolchain
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/utils.sh"

print_info "Installing Go (Golang programming language)..."

# Check if already installed
if is_app_installed "go"; then
  version=$(get_installed_version "go")
  print_info "Go is already installed (version $version)"

  if ! command -v go &> /dev/null; then
    print_warning "Go tracked but not found. Reinstalling..."
  else
    print_success "Go installation verified."
    exit 0
  fi
fi

# Ensure curl is available
ensure_command curl

# Determine architecture
ARCH=$(uname -m)
case "$ARCH" in
  x86_64) GO_ARCH="amd64" ;;
  aarch64) GO_ARCH="arm64" ;;
  armv7l) GO_ARCH="armv6l" ;;
  *) print_error "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Get latest Go version
print_info "Fetching latest Go version..."
GO_VERSION=$(curl -sL https://go.dev/VERSION?m=text 2>/dev/null | head -1)

if [ -z "$GO_VERSION" ]; then
  print_error "Failed to determine Go version"
  exit 1
fi

GO_TAR="${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
GO_URL="https://go.dev/dl/${GO_TAR}"

print_info "Installing Go ${GO_VERSION} (architecture: ${GO_ARCH})..."

# Download and extract
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

cd "$TEMP_DIR" || exit 1

if ! curl -L -o "$GO_TAR" "$GO_URL"; then
  print_error "Failed to download Go from $GO_URL"
  exit 1
fi

# Remove old Go installation if exists
if [ -d /usr/local/go ]; then
  print_info "Removing old Go installation..."
  sudo rm -rf /usr/local/go
fi

# Extract to /usr/local
print_info "Extracting Go..."
if ! sudo tar -C /usr/local -xzf "$GO_TAR"; then
  print_error "Failed to extract Go"
  exit 1
fi

# Add to PATH in shell configs if not already present
if ! grep -q '/usr/local/go/bin' ~/.bashrc; then
  echo '' >> ~/.bashrc
  echo '# Go (Golang) - added by gui-dotfiles' >> ~/.bashrc
  echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
fi

if ! grep -q '/usr/local/go/bin' ~/.zshrc; then
  echo '' >> ~/.zshrc
  echo '# Go (Golang) - added by gui-dotfiles' >> ~/.zshrc
  echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc
fi

# Add GOPATH if not set
if ! grep -q 'GOPATH' ~/.bashrc; then
  echo 'export GOPATH=$HOME/go' >> ~/.bashrc
  echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
fi

if ! grep -q 'GOPATH' ~/.zshrc; then
  echo 'export GOPATH=$HOME/go' >> ~/.zshrc
  echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.zshrc
fi

# Verify installation
export PATH=$PATH:/usr/local/go/bin
if verify_installation "go" "command -v go" "version"; then
  go_version=$(go version | awk '{print $3}')
  create_install_tracker "go" "$HOME/.local/share/gui-dotfiles" "$go_version"
  print_success "Go installed successfully!"
  print_info "Go version: $go_version"
  print_info "GOPATH: $HOME/go"
  print_info "You may need to reload your shell (exec zsh or exec bash) for PATH changes to take effect"
else
  print_error "Go installation failed!"
  exit 1
fi
