#!/bin/bash

# Print header
echo "====================================="
echo "  Installing GUI Dotfiles (Arch)"
echo "====================================="

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to run a script and log its execution
run_script() {
  local script=$1
  echo -e "\n${YELLOW}Running: ${script}${NC}"
  bash "./scripts/${script}"
  
  # Check if the script executed successfully
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Completed: ${script}${NC}"
  else
    echo -e "\033[0;31m✗ Failed: ${script}${NC}"
    exit 1
  fi
}

# TODO: Implement Arch Linux specific installation scripts
echo -e "${YELLOW}Arch Linux installation scripts not yet implemented.${NC}"
echo -e "${YELLOW}Feel free to contribute by adding pacman-based installation scripts!${NC}"

echo -e "\n${GREEN}==========================================${NC}"
echo -e "${GREEN}  Please update the Arch installation scripts${NC}"
echo -e "${GREEN}  in distros/arch/scripts/ directory${NC}"
echo -e "${GREEN}==========================================${NC}"

echo -e "\n${YELLOW}==========================================${NC}"
echo -e "${YELLOW}  Never gonna give you up,${NC}"
echo -e "${YELLOW}  Never gonna let you down,${NC}"
echo -e "${YELLOW}  Never gonna run around and desert you,${NC}"
echo -e "${YELLOW}  Never gonna make you cry,${NC}"
echo -e "${YELLOW}  Never gonna say goodbye,${NC}"
echo -e "${YELLOW}  Never gonna tell a lie and hurt you,${NC}"
echo -e "${YELLOW}==========================================${NC}"