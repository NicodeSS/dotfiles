#!/bin/bash

# Color definitions
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to install n and LTS Node.js
install_n_node() {
    # Check if n and node are already installed
    if command -v n &>/dev/null && command -v node &>/dev/null; then
        echo -e "${GREEN}✓ n and Node.js are already installed${NC}"
        echo -e "${BLUE}Current versions:${NC}"
        echo -e "${GREEN}n: $(n --version)${NC}"
        echo -e "${GREEN}Node.js: $(node --version)${NC}"
        echo -e "${GREEN}npm: $(npm --version)${NC}"
        echo -e "${YELLOW}Skipping n and Node.js installation...${NC}"
        return 0
    fi

    echo "Starting n and Node.js LTS installation..."

    # Set N_PREFIX
    export N_PREFIX=~/.local/share/n

    # Create N_PREFIX directory if it doesn't exist
    mkdir -p "$N_PREFIX"

    echo -e "${BLUE}Installing n with N_PREFIX=$N_PREFIX${NC}"

    # Install n using the provided command
    if curl -L https://bit.ly/n-install | N_PREFIX=~/.local/share/n bash -s -- -y -n; then
        echo -e "${GREEN}✓ n installed successfully${NC}"
    else
        echo -e "${RED}✗ Error: n installation failed${NC}"
        return 1
    fi

    # Add n to PATH for this session
    export PATH="$N_PREFIX/bin:$PATH"

    # Install LTS Node.js
    echo -e "${BLUE}Installing Node.js LTS...${NC}"
    if ~/.local/share/n/bin/n lts; then
        echo -e "${GREEN}✓ Node.js LTS installed successfully${NC}"
    else
        echo -e "${RED}✗ Warning: Node.js LTS installation failed${NC}"
    fi

    # Display installed versions
    echo -e "${GREEN}Installation completed!${NC}"
    echo -e "${BLUE}Installed versions:${NC}"
    if command -v ~/.local/share/n/bin/node &>/dev/null; then
        echo -e "${GREEN}Node.js: $(~/.local/share/n/bin/node --version)${NC}"
    fi
    if command -v ~/.local/share/n/bin/npm &>/dev/null; then
        echo -e "${GREEN}npm: $(~/.local/share/n/bin/npm --version)${NC}"
    fi

    echo ""
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}         📝  IMPORTANT NOTICE  📝         ${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}Please add the following to your shell configuration:${NC}"
    echo -e "${GREEN}export N_PREFIX=~/.local/share/n${NC}"
    echo -e "${GREEN}export PATH=\"\$N_PREFIX/bin:\$PATH\"${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
}

# If script is executed directly, run the installation function
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    install_n_node
fi
