#!/bin/bash

set -Eeuo pipefail

#
# Homebrew
#
# This installs some of the common dependencies needed (or at least desired)
# using Homebrew.

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function is_homebrew_installed() {
    type -P brew &>/dev/null
}

function install_homebrew() {
    if is_homebrew_installed; then
        echo "> Initial installation - Homebrew: already installed."
        return
    fi

    # Hack: create a /run/.containerenv to bypass Homebrew root detection
    if [[ $EUID -eq 0 ]]; then
        echo "> Running as root, creating /run/.containerenv to bypass Homebrew root detection"
        mkdir -p /run
        echo "# Created by dotfiles homebrew install script for root detection bypass" >/run/.containerenv
        echo "DOTFILES_HOMEBREW_HACK=1" >>/run/.containerenv
    fi

    echo "> Installing Homebrew."

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Setup Homebrew environment variables for current session
    echo "> Setting up Homebrew environment variables..."
    
    # Collect all possible Homebrew installation paths
    local possible_brew_paths=(
        "/opt/homebrew/bin/brew"          # Apple Silicon Mac (ARM64)
        "/usr/local/bin/brew"             # Intel Mac (x86_64)
        "/home/linuxbrew/.linuxbrew/bin/brew"  # Linux Homebrew
        "/usr/local/homebrew/bin/brew"    # Alternative Linux path
        "$HOME/.linuxbrew/bin/brew"       # User-specific Linux installation
        "/opt/local/bin/brew"             # Alternative installation
    )
    
    # Find the actual brew installation
    local brew_path=""
    for path in "${possible_brew_paths[@]}"; do
        if [[ -x "$path" ]]; then
            brew_path="$path"
            echo "> Found Homebrew at: $brew_path"
            break
        fi
    done
    
    # If not found in common paths, try to find it in PATH or use which/type
    if [[ -z "$brew_path" ]]; then
        if command -v brew &>/dev/null; then
            brew_path="$(command -v brew)"
            echo "> Found Homebrew in PATH at: $brew_path"
        elif type -P brew &>/dev/null; then
            brew_path="$(type -P brew)"
            echo "> Found Homebrew using type at: $brew_path"
        fi
    fi
    
    # Setup environment if brew was found
    if [[ -n "$brew_path" && -x "$brew_path" ]]; then
        echo "> Setting up Homebrew environment using: $brew_path"
        eval "$("$brew_path" shellenv)"
        echo "> Homebrew environment configured successfully."
    else
        echo "> Warning: Could not locate Homebrew installation. You may need to restart your shell or manually run 'eval \"\$(brew shellenv)\"'"
        echo "> Common installation paths checked:"
        printf "  - %s\n" "${possible_brew_paths[@]}"
    fi
    
    echo "> Homebrew installation completed."
}

function opt_out_of_analytics() {
    command -v brew &>/dev/null && brew analytics off
    return 0
}

function uninstall_homebrew() {
    if ! is_homebrew_installed; then
        echo "> Uninstall - Homebrew: not installed."
        return
    fi

    echo "> Uninstalling Homebrew."

    # Uninstall Homebrew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"

    # Clean up the script-created .containerenv file
    if [[ -f /run/.containerenv ]] && grep -q "DOTFILES_HOMEBREW_HACK=1" /run/.containerenv 2>/dev/null; then
        echo "> Removing script-created /run/.containerenv"
        rm -f /run/.containerenv
    fi
}

function main() {
    case "${1:-install}" in
    install)
        install_homebrew
        opt_out_of_analytics
        ;;
    uninstall)
        uninstall_homebrew
        ;;
    *)
        echo "Usage: $0 [install|uninstall]"
        echo "  install   - Install Homebrew (default)"
        echo "  uninstall - Uninstall Homebrew"
        exit 1
        ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
