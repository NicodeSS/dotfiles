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

    echo "> Installing Homebrew."

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

}

function opt_out_of_analytics() {
    brew analytics off
}

function main() {
    install_homebrew
    opt_out_of_analytics
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
