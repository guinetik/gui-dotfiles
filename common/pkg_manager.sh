#!/bin/bash

# Common Package Management Functions
# This script provides unified functions for package management across different distributions

# Determine the package manager
detect_pkg_manager() {
  if command -v apt &> /dev/null; then
    echo "apt"
  elif command -v pacman &> /dev/null; then
    echo "pacman"
  elif command -v dnf &> /dev/null; then
    echo "dnf"
  elif command -v zypper &> /dev/null; then
    echo "zypper"
  else
    echo "unknown"
  fi
}

# Update package repositories
update_pkg_repos() {
  local pkg_manager=$(detect_pkg_manager)
  
  echo "Updating package repositories..."
  case "$pkg_manager" in
    "apt")
      sudo apt update
      ;;
    "pacman")
      sudo pacman -Sy
      ;;
    "dnf")
      sudo dnf check-update
      ;;
    "zypper")
      sudo zypper refresh
      ;;
    *)
      echo "Unsupported package manager. Please update manually."
      return 1
      ;;
  esac
  
  return 0
}

# Install packages
install_pkg() {
  local packages=("$@")
  local pkg_manager=$(detect_pkg_manager)
  local install_output
  local exit_code=0
  
  if [ ${#packages[@]} -eq 0 ]; then
    echo "No packages specified."
    return 1
  fi
  
  echo "Installing packages: ${packages[*]}"
  case "$pkg_manager" in
    "apt")
      install_output=$(sudo apt install -y "${packages[@]}" 2>&1) || exit_code=$?
      ;;
    "pacman")
      install_output=$(sudo pacman -S --noconfirm "${packages[@]}" 2>&1) || exit_code=$?
      ;;
    "dnf")
      install_output=$(sudo dnf install -y "${packages[@]}" 2>&1) || exit_code=$?
      ;;
    "zypper")
      install_output=$(sudo zypper install -y "${packages[@]}" 2>&1) || exit_code=$?
      ;;
    *)
      echo "Unsupported package manager. Please install packages manually."
      return 1
      ;;
  esac
  
  # Display the installation output
  echo "$install_output"
  
  # For apt, check for "E: Unable to locate package" message
  if [[ "$pkg_manager" == "apt" && "$install_output" == *"E: Unable to locate package"* ]]; then
    return 1
  fi
  
  # Check exit code
  return $exit_code
}

# Check if a package is installed
is_pkg_installed() {
  local package="$1"
  local pkg_manager=$(detect_pkg_manager)
  
  case "$pkg_manager" in
    "apt")
      dpkg -l "$package" &> /dev/null
      return $?
      ;;
    "pacman")
      pacman -Q "$package" &> /dev/null
      return $?
      ;;
    "dnf")
      rpm -q "$package" &> /dev/null
      return $?
      ;;
    "zypper")
      rpm -q "$package" &> /dev/null
      return $?
      ;;
    *)
      echo "Unsupported package manager. Cannot check if package is installed."
      return 1
      ;;
  esac
}

# Get package mapping for different distributions
# Usage: get_pkg_name <package-name>
get_pkg_name() {
  local generic_name="$1"
  local pkg_manager=$(detect_pkg_manager)
  
  # Define mappings for different package managers
  case "$generic_name" in
    "curl")
      echo "curl"  # Same name across distributions
      ;;
    "zip")
      echo "zip"  # Same name across distributions
      ;;
    "unzip")
      echo "unzip"  # Same name across distributions
      ;;
    "git")
      echo "git"  # Same name across distributions
      ;;
    "python")
      case "$pkg_manager" in
        "apt")
          echo "python3"
          ;;
        "pacman")
          echo "python"
          ;;
        "dnf" | "zypper")
          echo "python3"
          ;;
        *)
          echo "$generic_name"
          ;;
      esac
      ;;
    "maven")
      case "$pkg_manager" in
        "apt" | "dnf" | "zypper")
          echo "maven"
          ;;
        "pacman")
          echo "maven"
          ;;
        *)
          echo "$generic_name"
          ;;
      esac
      ;;
    "gradle")
      echo "gradle"  # Same name across distributions
      ;;
    "node")
      case "$pkg_manager" in
        "apt")
          echo "nodejs"
          ;;
        "pacman" | "dnf" | "zypper")
          echo "nodejs"
          ;;
        *)
          echo "$generic_name"
          ;;
      esac
      ;;
    "rust")
      case "$pkg_manager" in
        "apt")
          echo "rustc"
          ;;
        "pacman")
          echo "rust"
          ;;
        "dnf" | "zypper")
          echo "rust"
          ;;
        *)
          echo "$generic_name"
          ;;
      esac
      ;;
    # Add more package mappings as needed
    *)
      echo "$generic_name"
      ;;
  esac
}

# Install multiple packages with distribution-specific names
# Usage: install_packages <package1> <package2> ...
install_packages() {
  local generic_packages=("$@")
  local system_packages=()
  
  # Convert generic package names to distribution-specific package names
  for pkg in "${generic_packages[@]}"; do
    local system_pkg=$(get_pkg_name "$pkg")
    system_packages+=("$system_pkg")
  done
  
  # Install the packages and capture return code
  install_pkg "${system_packages[@]}"
  local result=$?
  
  # Return the result code from install_pkg
  return $result
}

# Check if a command is available, if not install the corresponding package
ensure_command() {
  local command="$1"
  local package="${2:-$command}"
  
  if ! command -v "$command" &> /dev/null; then
    echo "$command is not installed. Installing $package..."
    install_packages "$package"
    
    # Verify installation
    if ! command -v "$command" &> /dev/null; then
      echo "Failed to install $package or $command is not in PATH."
      return 1
    fi
  else
    echo "$command is already installed."
  fi
  
  return 0
}

# Verify an installation was successful and log result
verify_installation() {
  local name="$1"
  local check_command="$2"
  local version_flag="${3:---version}"
  
  echo "Verifying $name installation..."
  
  if bash -c "$check_command &> /dev/null"; then
    echo "✅ $name is correctly installed."
    # Try to get version information
    local version_output
    version_output=$(bash -c "$check_command $version_flag 2>&1 | head -n 1")
    if [ $? -eq 0 ]; then
      echo "   Version: $version_output"
    fi
    return 0
  else
    echo "❌ $name installation failed or is not working correctly."
    return 1
  fi
}

# Check if a distribution type is being used
is_ubuntu_debian() {
  if [ -f /etc/os-release ]; then
    source /etc/os-release
    if [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID" == "pop" || "$ID" == "linuxmint" || "$ID" == "elementary" ]]; then
      return 0
    fi
  fi
  return 1
}

is_arch() {
  if [ -f /etc/os-release ]; then
    source /etc/os-release
    if [[ "$ID" == "arch" || "$ID" == "manjaro" || "$ID" == "endeavouros" ]]; then
      return 0
    fi
  fi
  return 1
}

is_fedora() {
  if [ -f /etc/os-release ]; then
    source /etc/os-release
    if [[ "$ID" == "fedora" ]]; then
      return 0
    fi
  fi
  return 1
}

# Export all functions
export -f detect_pkg_manager
export -f update_pkg_repos
export -f install_pkg
export -f is_pkg_installed
export -f get_pkg_name
export -f install_packages
export -f ensure_command
export -f verify_installation
export -f is_ubuntu_debian
export -f is_arch
export -f is_fedora