#!/bin/bash

# Common Utility Functions
# This script provides utility functions for installation scripts

# Source package manager functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/pkg_manager.sh"

# Print colored output
print_info() {
  echo -e "\033[0;34m[INFO]\033[0m $1"
}

print_success() {
  echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

print_warning() {
  echo -e "\033[0;33m[WARNING]\033[0m $1"
}

print_error() {
  echo -e "\033[0;31m[ERROR]\033[0m $1"
}

# Check if a directory exists in PATH
check_path() {
  local dir="$1"
  if [[ ":$PATH:" == *":$dir:"* ]]; then
    return 0
  else
    return 1
  fi
}

# Add directory to PATH in bashrc if not already there
add_to_path() {
  local dir="$1"
  local bashrc_file=~/.bashrc
  
  if ! check_path "$dir"; then
    print_info "Adding $dir to PATH in $bashrc_file"
    echo 'export PATH="'$dir':$PATH"' >> "$bashrc_file"
    return 0
  else
    print_info "$dir already in PATH, skipping."
    return 1
  fi
}

# Add entry to bashrc if not already present
add_to_bashrc() {
  local entry="$1"
  local bashrc_file=~/.bashrc
  
  if ! grep -q "$entry" "$bashrc_file"; then
    print_info "Adding entry to $bashrc_file"
    echo "$entry" >> "$bashrc_file"
    return 0
  else
    print_info "Entry already in $bashrc_file, skipping."
    return 1
  fi
}

# Check if a tool is installed and meets the minimum version
check_version() {
  local command="$1"
  local min_version="$2"
  local version_cmd="${3:-"$command --version | cut -d' ' -f2"}"
  
  if ! command -v "$command" &> /dev/null; then
    print_error "$command is not installed."
    return 1
  fi
  
  if [ -n "$min_version" ]; then
    local current_version
    current_version=$(eval "$version_cmd")
    
    # Simple version comparison (assumes semantic versioning)
    if [[ "$current_version" < "$min_version" ]]; then
      print_warning "$command version ($current_version) is less than minimum required version ($min_version)."
      return 2
    else
      print_success "$command version ($current_version) meets minimum requirements."
      return 0
    fi
  fi
  
  print_success "$command is installed."
  return 0
}

# Install Rust and Cargo if needed
ensure_rust() {
  # Check for C compiler (cc)
  if ! command -v cc &> /dev/null; then
    print_info "C compiler (cc) not found. Attempting to install build-essential..."
    if install_packages "build-essential"; then
      if ! command -v cc &> /dev/null; then
        print_error "Installed build-essential, but cc is still not found. Please check your C compiler installation."
        return 1
      fi
      print_success "build-essential installed successfully, cc is now available."
    else
      print_error "Failed to install build-essential. A C compiler (cc) is required for some Cargo packages."
      return 1
    fi
  else
    print_info "C compiler (cc) is available."
  fi

  if ! command -v cargo &> /dev/null; then
    print_info "Installing Rust and Cargo..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    if command -v cargo &> /dev/null; then
      print_success "Rust and Cargo installed successfully!"
      return 0
    else
      print_error "Failed to install Rust and Cargo"
      return 1
    fi
  else
    print_info "Rust and Cargo are already installed."
    return 0
  fi
}

# Install a package using Cargo
install_cargo_tool() {
  local tool_name=$1
  local binary_name="${2:-$tool_name}"
  local result=0
  
  print_info "Installing ${tool_name} via Cargo..."
  
  # Ensure Rust and Cargo are installed
  ensure_rust || return 1
  
  # Install the tool and capture the exit code
  cargo install "${tool_name}" || result=$?
  
  # If cargo command failed
  if [ $result -ne 0 ]; then
    print_error "Cargo installation command failed with exit code: $result"
    return $result
  fi
  
  # Verify installation
  if command -v "$binary_name" &> /dev/null; then
    print_success "${tool_name} installed successfully!"
    return 0
  else
    print_error "Failed to install ${tool_name} - binary not found in PATH"
    return 1
  fi
}

# Install a tool from GitHub release
install_from_github() {
  local repo="$1"
  local asset_pattern="$2"
  local bin_path="${3:-/usr/local/bin}"
  local install_cmd="${4:-""}"
  local expected_binary_name="$5"
  local specific_tag="$6" # New optional argument
  local result=0
  
  print_info "Installing from GitHub: $repo (expecting binary: ${expected_binary_name:-not specified}, specific tag: ${specific_tag:-latest})"
  
  # Ensure we have curl
  ensure_command curl || return 1
  
  # Create temporary directory
  local tmp_dir=$(mktemp -d)
  cd "$tmp_dir" || return 1
  
  # Get release information
  local release_url
  if [ -n "$specific_tag" ]; then
    release_url="https://api.github.com/repos/$repo/releases/tags/$specific_tag"
    print_info "Fetching release info for specific tag: $specific_tag from $release_url"
  else
    release_url="https://api.github.com/repos/$repo/releases/latest"
    print_info "Fetching latest release info from $release_url"
  fi
  
  local latest_release
  latest_release=$(curl -s "$release_url")
  
  # Check if we got a valid response (contains tag_name or name, depending on endpoint)
  if ! echo "$latest_release" | grep -q -E '"(tag_name|name)":'; then
    print_error "Failed to get release information for $repo (tag: ${specific_tag:-latest}) from $release_url"
    echo "$latest_release" # Print the response for debugging
    cd - &>/dev/null || true
    rm -rf "$tmp_dir"
    return 1
  fi
  
  # Extract version (use 'name' for specific tag, 'tag_name' for latest)
  local version
  if [ -n "$specific_tag" ]; then
    version=$(echo "$latest_release" | grep -Po '"name": "\K[^"]*' | sed 's/^v//') # Often specific tag 'name' is the version, strip leading 'v'
    if [ -z "$version" ]; then # Fallback to tag_name if name is not suitable
        version=$(echo "$latest_release" | grep -Po '"tag_name": "\K[^"]*' | sed 's/^v//')
    fi
  else
    version=$(echo "$latest_release" | grep -Po '"tag_name": "\K[^"]*' | sed 's/^v//')
  fi
  print_info "Using version: $version (derived from tag: ${specific_tag:-latest})"
  
  # Extract download URL
  local download_url
  download_url=$(echo "$latest_release" | grep -Po "\"browser_download_url\": \"[^\"]*/$asset_pattern\"" | grep -Po "https://[^\"]*" | head -1)
  
  if [ -z "$download_url" ]; then
    print_error "Could not find download URL for $repo matching pattern $asset_pattern"
    print_error "DEBUG: Asset pattern was: $asset_pattern"
    print_error "DEBUG: Here are the available assets:"
    echo "$latest_release" | grep -Po '"browser_download_url": "\K[^\"]*'
    cd - &>/dev/null || true
    rm -rf "$tmp_dir"
    return 1
  fi
  
  print_info "Downloading from: $download_url"
  
  # Download file
  local filename
  filename=$(basename "$download_url")
  curl -sL "$download_url" -o "$filename" || {
    print_error "Failed to download $download_url"
    cd - &>/dev/null || true
    rm -rf "$tmp_dir"
    return 1
  }
  
  # Handle installation based on file type
  if [[ "$filename" == *.tar.gz ]] || [[ "$filename" == *.tgz ]]; then
    tar xzf "$filename" || { result=1; print_error "Failed to extract tar archive"; }
    if [ $result -eq 0 ]; then
      if [ -n "$install_cmd" ]; then
        eval "$install_cmd" || result=$?
      else
        # Default search path is the root of the extraction
        local search_path="."
        local original_pwd=$(pwd) # Should be $tmp_dir

        # Check if the expected binary is directly at the root of the extraction
        if [ -n "$expected_binary_name" ] && [ -f "./${expected_binary_name}" ]; then
          print_info "Expected binary '${expected_binary_name}' found at the root of the extraction ($original_pwd)."
          search_path="." # Confirm search_path is current directory
        else
          # If not at root, try to determine if there's a single top-level directory
          local extracted_dir
          extracted_dir=$(tar -tzf "$filename" | head -1 | cut -d/ -f1 | grep -v '\.tar\.gz$') # also ensure it is not the archive itself
          
          if [ -n "$extracted_dir" ] && [ -d "$extracted_dir" ] && [ "$extracted_dir" != "." ]; then
            print_info "Potential top-level directory found: '$extracted_dir'. Checking for binary inside."
            cd "$extracted_dir" || { print_warning "Failed to cd into $extracted_dir, will search in root ($original_pwd)."; search_path="."; cd "$original_pwd"; } # Stay in tmp_dir if cd fails
            # If cd was successful, search_path remains "." but relative to the new CWD ($original_pwd/$extracted_dir)
          else
            print_info "No single top-level directory found or binary not at root. Searching in root ($original_pwd)."
            search_path="." # Ensure we are searching in the original tmp_dir root
            cd "$original_pwd" # Ensure we are in the correct directory if previous cd failed or was skipped
          fi
        fi
        # At this point, PWD should be set correctly (either $tmp_dir or $tmp_dir/$extracted_dir)
        # and search_path is "." relative to that PWD.

        print_info "Final search directory: $PWD/${search_path}"

        if [ -f "${search_path}/install.sh" ]; then
          (cd "$search_path" && bash ./install.sh) || result=$?
        else
          print_info "DEBUG: Listing contents of search path ($PWD/${search_path}) before attempting to find binary:"
          ls -la "${search_path}"

          local binary_to_install=""
          # Try to find the specifically expected binary name first in the search_path
          print_info "DEBUG: Checking for expected binary file at: $PWD/${search_path}/${expected_binary_name}"
          if [ -n "$expected_binary_name" ] && [ -f "${search_path}/${expected_binary_name}" ]; then
            binary_to_install="${search_path}/${expected_binary_name}"
            print_info "Found expected binary by name: $binary_to_install"
          else
            # Fallback: find any executable not in a hidden path, in the search_path
            print_info "Expected binary '$expected_binary_name' not found by name, searching for any executable in '${search_path}'..."
            binary_to_install=$(find "${search_path}" -maxdepth 1 -type f -executable -not -path "*/\.*" | head -1)
          fi

          if [ -n "$binary_to_install" ];
          then # Ensure it is executable if we found it (either by name or by find)
            if [ ! -x "$binary_to_install" ]; then
              print_info "Making $binary_to_install executable..."
              chmod +x "$binary_to_install" || print_warning "Failed to chmod +x $binary_to_install"
            fi
            print_info "Installing $binary_to_install to $bin_path/"
            sudo cp "$binary_to_install" "$bin_path/" || result=$?
            
            # If the copied name isn't the expected_binary_name, and expected_binary_name is meaningful, create symlink.
            local found_binary_basename=$(basename "$binary_to_install")
            if [ -n "$expected_binary_name" ] && [ "$found_binary_basename" != "$expected_binary_name" ]; then
                print_info "Symlinking $bin_path/$found_binary_basename to $bin_path/$expected_binary_name"
                sudo ln -sf "$bin_path/$found_binary_basename" "$bin_path/$expected_binary_name"
            fi
          elif [ -n "$expected_binary_name" ] && [ -f "${search_path}/${expected_binary_name}" ]; then
            # This case means it was found by name, but was not executable and chmod failed above, or initial find didn't pick it up.
            print_info "Found '${search_path}/${expected_binary_name}' but it seems it could not be made executable or copied. Attempting direct copy."
            chmod +x "${search_path}/${expected_binary_name}" || { print_error "Failed to make ${search_path}/${expected_binary_name} executable"; result=1; }
            if [ $result -eq 0 ]; then
              sudo cp "${search_path}/${expected_binary_name}" "$bin_path/" || result=$?
            fi 
          else
            print_warning "No executable found, and expected binary '${expected_binary_name:-not specified}' not present in ${search_path}."
            result=1
          fi
        fi
      fi
    fi
  elif [[ "$filename" == *.zip ]]; then
    unzip -q "$filename" || { result=1; print_error "Failed to extract zip archive"; }
    if [ $result -eq 0 ]; then
      if [ -n "$install_cmd" ]; then
        eval "$install_cmd" || result=$?
      else
        local extracted_dir
        extracted_dir=$(unzip -l "$filename" | awk '{print $4}' | grep '/$' | head -1 | sed 's/\/$//')
        
        # Check if we are already in the correct directory or need to cd
        local search_dir="." # Default to current directory
        if [ -n "$extracted_dir" ] && [ -d "$extracted_dir" ]; then
          # If a valid subdirectory was found, try to cd into it
          cd "$extracted_dir" || { print_warning "Failed to enter extracted directory '$extracted_dir', searching in current dir."; search_dir="."; result=0; } # stay in tmp_dir
        fi
        # If we successfully cd'd, search_dir remains "." relative to the new CWD.
        # If cd failed or no extracted_dir, search_dir is "." relative to tmp_dir.

        if [ -f "${search_dir}/install.sh" ]; then
          (cd "$search_dir" && bash ./install.sh) || result=$?
        else
          local binary
          # Find executable in the determined search directory
          binary=$(find "${search_dir}" -maxdepth 1 -type f -executable -not -path "*/\\.*" | head -1)
          if [ -n "$binary" ]; then
            # Ensure binary path is correct if it was found in current dir (search_dir=".")
            # or in a subdirectory.
            sudo cp "$binary" "$bin_path/" || result=$?
          else
            print_warning "No executable found in extracted files (searched in '$tmp_dir/$search_dir')"
            result=1
          fi
        fi
      fi
    fi
  elif [[ "$filename" == *.deb ]]; then
    sudo dpkg -i "$filename" || result=$?
  elif [[ "$filename" == *.rpm ]]; then
    sudo rpm -i "$filename" || result=$?
  elif [[ "$filename" == *.sh ]]; then
    chmod +x "$filename" || { result=1; print_error "Failed to make script executable"; }
    if [ $result -eq 0 ]; then
      bash "./$filename" || result=$?
    fi
  elif [[ "$filename" == *.appimage ]]; then
    # Handle AppImage files - run them directly without extraction
    print_info "Handling AppImage file: $filename"
    chmod +x "$filename" || { result=1; print_error "Failed to make AppImage executable"; }
    if [ $result -eq 0 ]; then
      local install_target_name="$expected_binary_name"
      if [ -z "$install_target_name" ]; then
        # If expected_binary_name is empty, use the downloaded filename without .appimage extension
        install_target_name=$(basename "$filename" .appimage)
        print_warning "expected_binary_name was empty, using filename without extension: $install_target_name"
      fi
      
      local target_path="$bin_path/$install_target_name"
      
      # Remove any existing file or dangling symlink at the target location
      if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        print_info "Removing existing file/symlink at $target_path"
        sudo rm -f "$target_path" || print_warning "Failed to remove existing $target_path"
      fi
      
      print_info "Installing AppImage '$filename' as '$install_target_name' to $bin_path/"
      sudo cp "$filename" "$target_path" || result=$?
      
      if [ $result -eq 0 ]; then
        # Ensure the installed file is executable
        sudo chmod +x "$target_path" || print_warning "Failed to ensure $target_path is executable"
        print_success "Successfully installed AppImage as '$target_path'"
      else
        print_error "Failed to copy AppImage '$filename' to '$target_path'"
      fi
    fi
  else # This is for direct binaries or unknown types
    print_info "Handling direct binary or unknown file type: $filename"
    chmod +x "$filename" || { result=1; print_error "Failed to make '$filename' executable"; }
    if [ $result -eq 0 ]; then
      local install_target_name="$expected_binary_name"
      if [ -z "$install_target_name" ]; then
        # If expected_binary_name is somehow empty, use the downloaded filename
        install_target_name=$(basename "$filename")
        print_warning "expected_binary_name was empty, using downloaded filename: $install_target_name"
      fi
      
      print_info "Installing '$filename' as '$install_target_name' to $bin_path/"
      sudo cp "$filename" "$bin_path/$install_target_name" || result=$?
      
      if [ $result -eq 0 ] && [ "$filename" != "$install_target_name" ]; then
          # If the original filename was different and we copied it to expected_binary_name,
          # ensure there's also a copy/link with the original filename if it's different,
          # just in case some scripts expect that. However, primary should be expected_binary_name.
          # For now, we'll assume copying as expected_binary_name is sufficient.
          print_info "Successfully copied '$filename' to '$bin_path/$install_target_name'"
      elif [ $result -ne 0 ]; then
          print_error "Failed to copy '$filename' to '$bin_path/$install_target_name'"
      fi
    fi
  fi
  
  # Clean up
  cd - &>/dev/null || true
  rm -rf "$tmp_dir"
  
  if [ $result -eq 0 ]; then
    print_success "GitHub installation completed successfully."
  else
    print_error "GitHub installation failed with exit code: $result"
  fi
  
  return $result
}

# Install a tool with fallbacks (package manager -> snap -> GitHub -> cargo)
install_tool_with_fallbacks() {
  local package_name=$1
  local binary_name="${2:-$package_name}"
  local github_repo="$3"
  local asset_pattern="$4"
  local binary_path="${5:-/usr/local/bin}"
  local install_cmd="$6"
  local cargo_name="${7:-$package_name}"
  local specific_tag="$8" # Optional argument for specific GitHub tag
  
  # Check if already installed
  if is_app_installed "$binary_name"; then
    version=$(get_installed_version "$binary_name")
    print_info "$binary_name is already installed (version $version)"
    
    if ! command -v "$binary_name" &> /dev/null; then
      print_warning "$binary_name is tracked as installed but command is not found. Reinstalling..."
    else
      print_success "$binary_name installation verified."
      return 0
    fi
  fi
  
  print_info "Installing $package_name (Priority: GitHub > Package Manager > Snap > Cargo)..."
  
  local install_success=false

  # 1. Try GitHub first if GitHub repo and asset pattern are provided
  if [ -n "$github_repo" ] && [ -n "$asset_pattern" ]; then
    print_info "DEBUG: Attempting GitHub install for $package_name with asset pattern: '$asset_pattern' (Tag: '${specific_tag:-latest}')"
    print_info "Trying GitHub installation first..."
    if install_from_github "$github_repo" "$asset_pattern" "$binary_path" "$install_cmd" "$binary_name" "$specific_tag"; then
      if command -v "$binary_name" &> /dev/null; then
        print_success "Installed $package_name from GitHub."
        install_success=true
      else
        print_warning "GitHub installation completed but binary '$binary_name' not found. Trying other methods."
      fi
    else
      print_warning "GitHub installation failed for $package_name. Trying other methods."
    fi
  fi
  
  # 2. Try to install using package manager if GitHub failed or was not applicable
  if [ "$install_success" = "false" ]; then
    print_info "Attempting package manager installation for $package_name..."
    if install_packages "$package_name"; then
      if command -v "$binary_name" &> /dev/null || command -v "${binary_name}cat" &> /dev/null; then
        print_success "Installed $package_name using package manager."
        install_success=true
        
        if [ "$package_name" = "bat" ] && ! command -v bat &> /dev/null && command -v batcat &> /dev/null; then
          print_info "Installed batcat, creating bat symlink..."
          mkdir -p ~/.local/bin
          ln -sf /usr/bin/batcat ~/.local/bin/bat
          add_to_path "$HOME/.local/bin"
        fi
      else
        print_warning "Package manager reported success for $package_name but binary '$binary_name' not found. Trying other methods."
      fi
    else
      print_warning "Package manager installation failed for $package_name."
    fi
  fi
  
  # 3. If previous methods fail, try snap if it's available
  if [ "$install_success" = "false" ] && command -v snap &> /dev/null; then
    print_info "Attempting snap installation for $package_name..."
    if sudo snap install "$package_name" 2>/dev/null; then
      if command -v "$binary_name" &> /dev/null; then
        print_success "Installed $package_name using snap."
        install_success=true
      else
        print_warning "Snap installation reported success for $package_name but binary '$binary_name' not found. Trying other methods."
      fi
    else
      print_warning "Snap installation failed for $package_name."
    fi
  fi
  
  # 4. If all previous methods fail, try cargo
  if [ "$install_success" = "false" ] && [ -n "$cargo_name" ]; then
    print_info "Attempting cargo installation for $package_name..."
    if install_cargo_tool "$cargo_name" "$binary_name"; then
      if command -v "$binary_name" &> /dev/null; then
        print_success "Installed $package_name using cargo."
        install_success=true
      else
        print_warning "Cargo installation completed for $package_name but binary '$binary_name' not found."
      fi
    else
      print_warning "Cargo installation failed for $package_name."
    fi
  fi
  
  # Verify and track installation
  if [ "$install_success" = "true" ] || command -v "$binary_name" &> /dev/null; then
    version=$("$binary_name" --version 2>/dev/null | head -n 1 || echo "installed")
    create_install_tracker "$binary_name" "$HOME/.local/share/gui-dotfiles" "$version"
    print_success "$binary_name installed successfully!"
    return 0
  else
    print_error "All installation methods failed for $package_name."
    return 1
  fi
}

# Define tracking directory
INSTALL_TRACKER_DIR="$HOME/.local/share/gui-dotfiles"
INSTALL_MASTER_FILE="$INSTALL_TRACKER_DIR/.installed"

# Initialize installation tracking environment
init_install_tracking() {
  # Create tracking directory if it doesn't exist
  mkdir -p "$INSTALL_TRACKER_DIR" || {
    print_error "Failed to create tracking directory: $INSTALL_TRACKER_DIR"
    # Don't exit - we'll just operate without tracking
    return 1
  }
  
  # Create master tracking file if it doesn't exist
  if [ ! -f "$INSTALL_MASTER_FILE" ]; then
    {
      echo "# GUI Dotfiles - Installation Tracking" 
      echo "# Format: component_name|version|status|timestamp"
      echo "# File generated on $(date '+%Y-%m-%d %H:%M:%S')"
      echo "dotfiles_initialized|1.0|completed|$(date '+%Y-%m-%d %H:%M:%S')"
    } > "$INSTALL_MASTER_FILE" || {
      print_error "Failed to create master tracking file: $INSTALL_MASTER_FILE"
      # Don't exit - we'll just operate without tracking
      return 1
    }
  fi
  
  return 0
}

# Mark a script as completed in the master tracking file
mark_script_completed() {
  local script_name="$1"
  local script_version="${2:-1.0}"
  local date_completed=$(date '+%Y-%m-%d %H:%M:%S')
  
  # Initialize tracking if needed
  init_install_tracking
  
  # Try to safely update the file with awk - this is more reliable than sed
  if [ -f "$INSTALL_MASTER_FILE" ]; then
    # Create a temporary file
    local tmp_file="${INSTALL_MASTER_FILE}.tmp"
    
    # Use awk to find and update the entry, or pass through unchanged lines
    awk -F'|' -v name="$script_name" -v version="$script_version" -v timestamp="$date_completed" \
      'BEGIN { OFS="|" } 
       $1 == name { print name, version, "completed", timestamp; next } 
       { print }' "$INSTALL_MASTER_FILE" > "$tmp_file" 2>/dev/null || {
      # If awk fails, fall back to simpler approach
      print_warning "Failed to update tracking file with awk, using simpler approach"
      cp "$INSTALL_MASTER_FILE" "$tmp_file" 2>/dev/null
    }
    
    # Check if the script was found in the file
    if grep -q "^${script_name}|" "$tmp_file" 2>/dev/null; then
      # Entry was updated, move temp file to master file
      mv "$tmp_file" "$INSTALL_MASTER_FILE" 2>/dev/null || true
    else
      # Entry wasn't found, add it to the file
      echo "${script_name}|${script_version}|completed|${date_completed}" >> "$INSTALL_MASTER_FILE" 2>/dev/null || true
      # Remove the temp file
      rm -f "$tmp_file" 2>/dev/null || true
    fi
  else
    # File doesn't exist yet, create it with just this entry
    {
      echo "# GUI Dotfiles - Installation Tracking"
      echo "# Format: component_name|version|status|timestamp"
      echo "# File generated on $(date '+%Y-%m-%d %H:%M:%S')"
      echo "${script_name}|${script_version}|completed|${date_completed}"
    } > "$INSTALL_MASTER_FILE" 2>/dev/null || true
  fi
  
  print_info "Marked script '$script_name' as completed"
}

# Check if a script has been completed previously
is_script_completed() {
  local script_name="$1"
  
  # Initialize tracking if needed
  init_install_tracking
  
  # Check for script in master file
  if grep -q "^${script_name}|.*|completed|" "$INSTALL_MASTER_FILE" 2>/dev/null; then
    return 0  # Found (true)
  else
    return 1  # Not found (false)
  fi
}

# Get timestamp of when a script was completed
get_script_completion_time() {
  local script_name="$1"
  
  # Check if script exists in master file
  if is_script_completed "$script_name"; then
    grep "^${script_name}|" "$INSTALL_MASTER_FILE" 2>/dev/null | cut -d'|' -f4 || echo "unknown date"
    return 0
  else
    echo ""
    return 1
  fi
}

# Create installation tracker file (for individual components)
create_install_tracker() {
  local app_name="$1"
  local install_dir="${2:-$INSTALL_TRACKER_DIR}"
  local version="$3"
  local date_installed
  date_installed=$(date +"%Y-%m-%d %H:%M:%S")
  
  # Initialize tracking
  init_install_tracking
  
  # Create or update tracker file
  cat > "$install_dir/$app_name.info" << EOF 2>/dev/null || true
app_name=$app_name
version=$version
date_installed="$date_installed"
EOF
  
  # Add to master tracking file using the same awk approach
  local component_name="component_${app_name}"
  
  # Try to safely update the file with awk
  if [ -f "$INSTALL_MASTER_FILE" ]; then
    # Create a temporary file
    local tmp_file="${INSTALL_MASTER_FILE}.tmp"
    
    # Use awk to find and update the entry, or pass through unchanged lines
    awk -F'|' -v name="$component_name" -v version="$version" -v timestamp="$date_installed" \
      'BEGIN { OFS="|" } 
       $1 == name { print name, version, "completed", timestamp; next } 
       { print }' "$INSTALL_MASTER_FILE" > "$tmp_file" 2>/dev/null || {
      # If awk fails, fall back to simpler approach
      print_warning "Failed to update tracking file with awk, using simpler approach"
      cp "$INSTALL_MASTER_FILE" "$tmp_file" 2>/dev/null
    }
    
    # Check if the component was found in the file
    if grep -q "^${component_name}|" "$tmp_file" 2>/dev/null; then
      # Entry was updated, move temp file to master file
      mv "$tmp_file" "$INSTALL_MASTER_FILE" 2>/dev/null || true
    else
      # Entry wasn't found, add it to the file
      echo "${component_name}|${version}|completed|${date_installed}" >> "$INSTALL_MASTER_FILE" 2>/dev/null || true
      # Remove the temp file
      rm -f "$tmp_file" 2>/dev/null || true
    fi
  else
    # File doesn't exist yet, create it with just this entry
    {
      echo "# GUI Dotfiles - Installation Tracking"
      echo "# Format: component_name|version|status|timestamp"
      echo "# File generated on $(date '+%Y-%m-%d %H:%M:%S')"
      echo "${component_name}|${version}|completed|${date_installed}"
    } > "$INSTALL_MASTER_FILE" 2>/dev/null || true
  fi
  
  print_info "Created installation tracker for $app_name version $version"
}

# Check if an app is installed from tracker
is_app_installed() {
  local app_name="$1"
  local install_dir="${2:-$INSTALL_TRACKER_DIR}"
  
  # Check individual tracker file
  if [ -f "$install_dir/$app_name.info" ]; then
    return 0
  fi
  
  # Check master tracking file as fallback
  if grep -q "^component_${app_name}|" "$INSTALL_MASTER_FILE" 2>/dev/null; then
    return 0
  fi
  
  return 1
}

# Get installed app version from tracker
get_installed_version() {
  local app_name="$1"
  local install_dir="${2:-$INSTALL_TRACKER_DIR}"
  
  # Try individual tracker file first
  if [ -f "$install_dir/$app_name.info" ]; then
    grep "version=" "$install_dir/$app_name.info" 2>/dev/null | cut -d'=' -f2 || echo "unknown"
    return 0
  fi
  
  # Try master tracking file as fallback
  if grep -q "^component_${app_name}|" "$INSTALL_MASTER_FILE" 2>/dev/null; then
    grep "^component_${app_name}|" "$INSTALL_MASTER_FILE" 2>/dev/null | cut -d'|' -f2 || echo "unknown"
    return 0
  fi
  
  echo ""
  return 1
}

# List all installed components
list_installed_components() {
  # Initialize tracking if needed
  init_install_tracking
  
  echo "Installed Components:"
  echo "====================="
  echo "Component Name | Version | Status | Installation Date"
  echo "------------------------------------------------------"
  grep -v "^#" "$INSTALL_MASTER_FILE" 2>/dev/null | sort || echo "No components installed yet"
}

# Check if a specific script should be skipped (for idempotent runs)
should_skip_script() {
  local script_name="$1"
  local force_run="${2:-false}"
  
  # If force run is set, never skip
  if [[ "$force_run" == "true" ]]; then
    return 1  # Don't skip
  fi
  
  # Check if script has been completed previously
  if is_script_completed "$script_name"; then
    print_info "Script '$script_name' was previously completed on $(get_script_completion_time "$script_name")"
    print_info "Skipping script execution"
    return 0  # Skip
  fi
  
  return 1  # Don't skip
}

# Ask user for confirmation with colored prompt
# If YOLO_MODE is set to true, automatically returns true without asking
ask_yes_no() {
  local prompt="$1"
  local default="${2:-y}"  # Default to "yes" if not specified
  local yolo_mode="${YOLO_MODE:-false}"  # Default to false if not set
  
  # If in YOLO mode, automatically return yes without prompting
  if [[ "$yolo_mode" == "true" ]]; then
    # Still show info about what would have been prompted
    echo -e "\033[0;33m$prompt [YOLO mode: automatic YES]\033[0m"
    return 0
  fi
  
  local yn_prompt
  if [[ "$default" == "y" ]]; then
    yn_prompt="[Y/n]"
  else
    yn_prompt="[y/N]"
  fi
  
  echo -e "\033[0;33m$prompt $yn_prompt\033[0m "
  read -r answer
  
  # Default value if empty
  if [[ -z "$answer" ]]; then
    answer="$default"
  fi
  
  # Convert to lowercase
  answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
  
  # Return 0 (success) if yes, 1 (failure) if no
  if [[ "$answer" == "y" || "$answer" == "yes" ]]; then
    return 0
  else
    return 1
  fi
}

# Display a header with description
print_header() {
  local title="$1"
  local length=${#title}
  local separator=$(printf "%0.s=" $(seq 1 $((length + 10))))
  
  echo ""
  echo -e "\033[1;36m$separator\033[0m"
  echo -e "\033[1;36m     $title     \033[0m"
  echo -e "\033[1;36m$separator\033[0m"
  echo ""
}

# Display a section header
print_section() {
  local title="$1"
  
  echo ""
  echo -e "\033[1;33m>>> $title\033[0m"
  echo ""
}

# Display a menu and get user choice
show_menu() {
  local title="$1"
  shift
  local options=("$@")
  
  print_section "$title"
  
  for i in "${!options[@]}"; do
    echo "  $((i+1)). ${options[$i]}"
  done
  
  echo ""
  echo -e "\033[0;33mEnter your choice (1-${#options[@]}):\033[0m "
  read -r choice
  
  # Validate choice
  if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
    return "$choice"
  else
    print_error "Invalid choice. Please try again."
    show_menu "$title" "${options[@]}"
  fi
}

# Export all functions
export -f print_info
export -f print_success
export -f print_warning
export -f print_error
export -f check_path
export -f add_to_path
export -f add_to_bashrc
export -f check_version
export -f ensure_rust
export -f install_cargo_tool
export -f install_from_github
export -f install_tool_with_fallbacks
export -f init_install_tracking
export -f mark_script_completed
export -f is_script_completed
export -f get_script_completion_time
export -f create_install_tracker
export -f is_app_installed
export -f get_installed_version
export -f list_installed_components
export -f should_skip_script
export -f ask_yes_no
export -f print_header
export -f print_section
export -f show_menu

# Export variables
export INSTALL_TRACKER_DIR