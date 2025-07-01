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

    # Set N_PREFIX. Use $HOME for a more robust path.
    export N_PREFIX="$HOME/.local/share/n"

    # Create N_PREFIX directory if it doesn't exist
    mkdir -p "$N_PREFIX"

    echo -e "${BLUE}Installing n with N_PREFIX=$N_PREFIX${NC}"

    # --- START: MODIFIED INSTALLATION LOGIC ---
    # This is the robust way to handle scripts that exit prematurely.

    # 1. Define a temporary file for the installer
    local n_install_script="/tmp/n-install.sh"

    # 2. Download the installer script first
    if ! curl -L https://bit.ly/n-install -o "$n_install_script"; then
        echo -e "${RED}✗ Error: Failed to download n-install script.${NC}"
        return 1
    fi

    # 3. Execute the downloaded script with bash in a subshell.
    #    This prevents exec/exit in the script from terminating our process.
    local exit_code
    (
        N_INSTALL_TEST_OVERRIDE_SKIP_EXISTING_INSTALLATION_TEST=1 \
            N_PREFIX="$N_PREFIX" \
            bash "$n_install_script" -y -n lts
    )
    # 4. Capture the exit code of the subshell execution.
    exit_code=$?

    # 5. Clean up the temporary script file.
    rm "$n_install_script"

    # 6. Check the exit code and verify installation
    if [ "$exit_code" -eq 0 ] || [ -x "$N_PREFIX/bin/n" ]; then
        echo -e "${GREEN}✓ n installed successfully${NC}"
    else
        echo -e "${RED}✗ Error: n installation failed (exit code: $exit_code)${NC}"
        echo -e "${YELLOW}Attempting manual verification...${NC}"

        # Check if n was actually installed despite exit code
        if [ -x "$N_PREFIX/bin/n" ]; then
            echo -e "${GREEN}✓ n binary found, continuing with installation${NC}"
        else
            return 1
        fi
    fi
    # --- END: MODIFIED INSTALLATION LOGIC ---

    # Add n to PATH for the rest of this session's execution
    export PATH="$N_PREFIX/bin:$PATH"

    # Install LTS Node.js
    echo -e "${BLUE}Installing Node.js LTS...${NC}"
    # Use the full path to the newly installed 'n' binary
    if "$N_PREFIX/bin/n" lts; then
        echo -e "${GREEN}✓ Node.js LTS installed successfully${NC}"
    else
        echo -e "${RED}✗ Warning: Node.js LTS installation failed${NC}"
    fi

    # Display installed versions
    echo -e "${GREEN}Installation completed!${NC}"
    echo -e "${BLUE}Installed versions:${NC}"
    if command -v "$N_PREFIX/bin/node" &>/dev/null; then
        echo -e "${GREEN}Node.js: $("$N_PREFIX/bin/node" --version)${NC}"
    fi
    if command -v "$N_PREFIX/bin/npm" &>/dev/null; then
        echo -e "${GREEN}npm: $("$N_PREFIX/bin/npm" --version)${NC}"
    fi

    echo ""
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}         📝  IMPORTANT NOTICE  📝         ${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}Please add the following to your shell configuration file (e.g., ~/.zshrc or ~/.bashrc):${NC}"
    echo -e "${GREEN}export N_PREFIX=\"\$HOME/.local/share/n\"${NC}"
    echo -e "${GREEN}export PATH=\"\$N_PREFIX/bin:\$PATH\"${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
}

# If script is executed directly, run the installation function
# This construct ensures the function runs only when you execute the script file itself.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_n_node
fi
