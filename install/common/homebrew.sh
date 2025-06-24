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
