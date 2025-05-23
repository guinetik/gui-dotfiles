#!/bin/bash

# Source common utilities
JAVA_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$JAVA_SCRIPT_DIR/../../common/utils.sh"

# Java Development Environment Setup
print_info "Setting up Java Development Environment..."

# Create installation tracking directory
mkdir -p "$HOME/.local/share/gui-dotfiles"

# Install Jabba
print_info "Installing Jabba (Java Version Manager)..."
bash "$JAVA_SCRIPT_DIR/install_jabba.sh"
if [ $? -ne 0 ]; then
    print_error "Failed to install Jabba!"
    exit 1
fi

# Install Maven and Maven Daemon
print_info "Installing Maven and Maven Daemon..."
bash "$JAVA_SCRIPT_DIR/install_maven.sh"
if [ $? -ne 0 ]; then
    print_error "Failed to install Maven and Maven Daemon!"
    exit 1
fi

# Source the Jabba environment
source "$HOME/.jabba/jabba.sh"

print_success "Java Development Environment setup completed successfully!"
echo ""
print_info "Installed components:"
echo "- Jabba (Java Version Manager)"
echo "- OpenJDK 17 (default Java version)"
echo "- Maven"
echo "- Maven Daemon (mvnd)"
echo ""
print_info "Java version:"
java -version
echo ""
print_info "Maven version:"
mvn --version | head -n 1
echo ""
print_info "You may need to restart your terminal or run 'source ~/.bashrc' to use all tools."