#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# shellcheck disable=SC2016
declare -r DOTFILES_LOGO='
    ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
    ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝
    ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗
    ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
    ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║
    ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝

         *** One-click installation script for dotfiles setup ***
              Auto-install chezmoi and apply configurations
'

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Script configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_REPO_URL="https://github.com/NicodeSS/dotfiles.git"
readonly BRANCH_NAME="${BRANCH_NAME:-main}"
readonly CHEZMOI_BIN_DIR="${HOME}/.local/bin"

# Exit handlers
declare AT_EXIT=""

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_debug() {
    if [ "${DOTFILES_DEBUG:-}" ]; then
        echo -e "${PURPLE}[DEBUG]${NC} $1" >&2
    fi
}

# Exit handler management
at_exit() {
    AT_EXIT+="${AT_EXIT:+$'\n'}"
    AT_EXIT+="${*?}"
    # shellcheck disable=SC2064
    trap "${AT_EXIT}" EXIT
}

# Environment detection functions
is_ci() {
    [[ "${CI:-false}" == "true" ]]
}

is_tty() {
    [ -t 0 ]
}

is_not_tty() {
    ! is_tty
}

is_ci_or_not_tty() {
    is_ci || is_not_tty
}

get_os_type() {
    uname
}

detect_os() {
    case "$(uname -s)" in
    Darwin*)
        echo "macos"
        ;;
    Linux*)
        if command -v apt-get >/dev/null 2>&1; then
            echo "debian"
        elif command -v yum >/dev/null 2>&1; then
            echo "rhel"
        elif command -v dnf >/dev/null 2>&1; then
            echo "fedora"
        elif command -v pacman >/dev/null 2>&1; then
            echo "arch"
        elif command -v zypper >/dev/null 2>&1; then
            echo "suse"
        else
            echo "linux"
        fi
        ;;
    CYGWIN* | MINGW32* | MSYS* | MINGW*)
        echo "windows"
        ;;
    FreeBSD*)
        echo "freebsd"
        ;;
    *)
        echo "unknown"
        ;;
    esac
}

detect_arch() {
    case "$(uname -m)" in
    x86_64 | amd64)
        echo "amd64"
        ;;
    arm64 | aarch64)
        echo "arm64"
        ;;
    armv7l)
        echo "arm"
        ;;
    i386 | i686)
        echo "i386"
        ;;
    *)
        echo "unknown"
        ;;
    esac
}

# Utility functions
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

is_homebrew_installed() {
    command_exists brew
}

is_chezmoi_installed() {
    command_exists chezmoi
}

# Sudo management functions
keepalive_sudo_linux() {
    # Ask for password up-front
    log_info "Checking for sudo access which may request your password..."
    if ! sudo -n true 2>/dev/null; then
        sudo -v
    fi

    # Keep-alive: update existing sudo time stamp if set, otherwise do nothing
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done 2>/dev/null &
}

keepalive_sudo_macos() {
    # Store password in keychain for sudo operations
    (
        builtin read -r -s -p "Password: " </dev/tty
        builtin echo "add-generic-password -U -s 'dotfiles' -a '${USER}' -w '${REPLY}'"
    ) | /usr/bin/security -i
    printf "\n"

    at_exit "
        echo -e '${RED}Removing password from Keychain...${NC}'
        /usr/bin/security delete-generic-password -s 'dotfiles' -a '${USER}' 2>/dev/null || true
    "

    SUDO_ASKPASS="$(/usr/bin/mktemp)"
    at_exit "
        echo -e '${RED}Deleting SUDO_ASKPASS script...${NC}'
        /bin/rm -f '${SUDO_ASKPASS}'
    "

    {
        echo "#!/bin/sh"
        echo "/usr/bin/security find-generic-password -s 'dotfiles' -a '${USER}' -w"
    } >"${SUDO_ASKPASS}"

    /bin/chmod +x "${SUDO_ASKPASS}"
    export SUDO_ASKPASS

    if ! /usr/bin/sudo -A -kv 2>/dev/null; then
        log_error "Incorrect password."
        exit 1
    fi
}

keepalive_sudo() {
    local ostype
    ostype="$(get_os_type)"

    if [ "${ostype}" == "Darwin" ]; then
        keepalive_sudo_macos
    elif [ "${ostype}" == "Linux" ]; then
        keepalive_sudo_linux
    else
        log_error "Invalid OS type: ${ostype}"
        exit 1
    fi
}

# Package manager installation functions
install_homebrew() {
    if is_homebrew_installed; then
        log_info "Homebrew is already installed"
        return 0
    fi

    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Setup Homebrew environment variables
    local arch_name
    arch_name="$(arch)"
    if [[ "$arch_name" == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ "$arch_name" == "i386" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    else
        log_error "Invalid CPU architecture: $arch_name"
        exit 1
    fi

    log_success "Homebrew installed successfully"
}

install_package_manager() {
    local os="$1"

    case "$os" in
    macos)
        install_homebrew
        ;;
    debian)
        if ! command_exists curl; then
            log_info "Installing curl..."
            sudo apt-get update
            sudo apt-get install -y curl
        fi
        ;;
    rhel | fedora)
        if ! command_exists curl; then
            log_info "Installing curl..."
            if command_exists dnf; then
                sudo dnf install -y curl
            else
                sudo yum install -y curl
            fi
        fi
        ;;
    arch)
        if ! command_exists curl; then
            log_info "Installing curl..."
            sudo pacman -S --noconfirm curl
        fi
        ;;
    suse)
        if ! command_exists curl; then
            log_info "Installing curl..."
            sudo zypper install -y curl
        fi
        ;;
    esac
}

# OS-specific initialization
initialize_os_macos() {
    install_homebrew
}

initialize_os_linux() {
    local os
    os="$(detect_os)"
    install_package_manager "$os"
}

initialize_os_env() {
    local ostype
    ostype="$(get_os_type)"

    if [ "${ostype}" == "Darwin" ]; then
        initialize_os_macos
    elif [ "${ostype}" == "Linux" ]; then
        initialize_os_linux
    else
        log_error "Invalid OS type: ${ostype}"
        exit 1
    fi
}

# Chezmoi installation and setup
install_chezmoi() {
    local os="$1"
    local arch="$2"

    if is_chezmoi_installed; then
        log_info "chezmoi is already installed"
        return 0
    fi

    log_info "Installing chezmoi..."

    # Create bin directory if it doesn't exist
    mkdir -p "${CHEZMOI_BIN_DIR}"

    case "$os" in
    macos)
        if is_homebrew_installed; then
            brew install chezmoi
        else
            sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "${CHEZMOI_BIN_DIR}"
        fi
        ;;
    debian | rhel | fedora | linux)
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "${CHEZMOI_BIN_DIR}"
        ;;
    arch)
        if sudo pacman -S --noconfirm chezmoi 2>/dev/null; then
            log_success "chezmoi installed via pacman"
        else
            log_info "Falling back to official installer..."
            sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "${CHEZMOI_BIN_DIR}"
        fi
        ;;
    freebsd)
        if command_exists pkg && sudo pkg install -y chezmoi 2>/dev/null; then
            log_success "chezmoi installed via pkg"
        else
            log_info "Falling back to official installer..."
            sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "${CHEZMOI_BIN_DIR}"
        fi
        ;;
    windows)
        log_error "Windows is not supported by this script"
        log_error "Please use PowerShell and run: irm get.chezmoi.io | iex"
        exit 1
        ;;
    *)
        log_warning "Unknown OS, trying universal installation method..."
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "${CHEZMOI_BIN_DIR}"
        ;;
    esac

    # Add chezmoi to PATH
    export PATH="${PATH}:${CHEZMOI_BIN_DIR}"

    # Clean up downloaded binary if installed via package manager
    if [[ "$os" == "macos" ]] && is_homebrew_installed; then
        rm -f "${CHEZMOI_BIN_DIR}/chezmoi"
    fi

    if is_chezmoi_installed; then
        log_success "chezmoi installed successfully"
        chezmoi --version
    else
        log_error "chezmoi installation failed"
        exit 1
    fi
}

run_chezmoi() {
    local repo_url="$1"
    local chezmoi_cmd

    # Ensure chezmoi is in PATH
    export PATH="${PATH}:${CHEZMOI_BIN_DIR}"

    if command_exists chezmoi; then
        chezmoi_cmd="chezmoi"
    elif [[ -x "${CHEZMOI_BIN_DIR}/chezmoi" ]]; then
        chezmoi_cmd="${CHEZMOI_BIN_DIR}/chezmoi"
    else
        log_error "chezmoi not found in PATH or ${CHEZMOI_BIN_DIR}"
        exit 1
    fi

    log_info "Initializing chezmoi configuration..."

    # Set up no-tty option for CI/non-interactive environments
    local no_tty_option=""
    if is_ci_or_not_tty; then
        no_tty_option="--no-tty"
        log_debug "Running in non-interactive mode"
    fi

    # Check if running from dotfiles repository directory
    if [[ -f ".chezmoiroot" && -d "home" ]]; then
        log_info "Detected dotfiles repository, initializing from local path..."
        "${chezmoi_cmd}" init "$(pwd)" \
            --force \
            --branch "${BRANCH_NAME}" \
            --use-builtin-git true \
            ${no_tty_option}
    else
        log_info "Initializing chezmoi from remote repository: ${repo_url}"
        "${chezmoi_cmd}" init "${repo_url}" \
            --force \
            --branch "${BRANCH_NAME}" \
            --use-builtin-git true \
            ${no_tty_option}
    fi

    # Handle encrypted files in CI/non-interactive environments
    if is_ci_or_not_tty; then
        log_info "Removing encrypted files (not supported in non-interactive mode)..."
        local source_path
        source_path="$("${chezmoi_cmd}" source-path 2>/dev/null || echo "")"
        if [[ -n "$source_path" && -d "$source_path" ]]; then
            find "$source_path" -type f -name "encrypted_*" -exec rm -fv {} + 2>/dev/null || true
        fi
    fi

    # Apply chezmoi configuration
    log_info "Applying chezmoi configuration..."
    "${chezmoi_cmd}" apply ${no_tty_option}

    log_success "chezmoi configuration applied successfully"
}

# Installation script management
run_install_scripts() {
    local os="$1"

    log_info "Install scripts are located in the 'install' directory and should be run manually by the user"
    log_info "Common scripts: install/common/"
    log_info "OS-specific scripts: install/$os/"
    log_info "Please review and run these scripts manually as needed"
}

# Shell restart functionality
get_system_from_chezmoi() {
    if command_exists chezmoi && command_exists jq; then
        chezmoi data 2>/dev/null | jq -r '.system // "unknown"' 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

restart_shell_system() {
    local system
    system=$(get_system_from_chezmoi)

    log_info "Detected system type: ${system}"

    # Restart shell based on system type
    case "${system}" in
    client)
        log_info "Restarting with zsh (login shell)..."
        exec /bin/zsh --login
        ;;
    server)
        log_info "Restarting with bash (login shell)..."
        exec /bin/bash --login
        ;;
    *)
        log_info "Restarting with default shell..."
        exec "${SHELL}" --login 2>/dev/null || exec /bin/bash --login
        ;;
    esac
}

restart_shell() {
    # Only restart shell if not reading from stdin (pipe)
    if [ -p /dev/stdin ]; then
        log_info "Continuing without shell restart (piped execution detected)"
        log_info "Please restart your shell manually to load new configurations"
    else
        log_info "Restarting shell to load new configurations..."
        restart_shell_system
    fi
}

# Help and usage
show_help() {
    cat <<EOF
${DOTFILES_LOGO}

Usage: $SCRIPT_NAME [options]

One-click installation and configuration of chezmoi dotfiles environment

Options:
  -h, --help              Show this help message
  -r, --repo URL          Specify dotfiles repository URL (default: auto-detect or $DEFAULT_REPO_URL)
  -b, --branch BRANCH     Specify git branch (default: $BRANCH_NAME)
  -v, --verbose           Enable verbose output
  --chezmoi-only          Only install chezmoi, don't initialize configuration
  --no-restart            Don't restart shell after installation

Examples:
  $SCRIPT_NAME                                          # Use default settings
  $SCRIPT_NAME -r https://github.com/user/dots         # Specify repository
  $SCRIPT_NAME --chezmoi-only                           # Only install chezmoi
  $SCRIPT_NAME -v --branch develop                      # Verbose mode with custom branch

Environment Variables:
  DOTFILES_DEBUG          Enable debug output
  BRANCH_NAME             Git branch to use (default: main)

Note:
  Installation scripts in the 'install' directory are NOT automatically executed.
  Please review and run them manually as needed after the initial setup.

EOF
}

# Main initialization function
initialize_dotfiles() {
    local repo_url="$1"

    if ! is_ci_or_not_tty; then
        keepalive_sudo
    fi

    run_chezmoi "$repo_url"

    # Always show install script locations but don't run them
    local os
    os="$(detect_os)"
    run_install_scripts "$os"
}

# Main function
main() {
    local repo_url="$DEFAULT_REPO_URL"
    local branch="$BRANCH_NAME"
    local chezmoi_only=false
    local verbose=false
    local no_restart=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
        -h | --help)
            show_help
            exit 0
            ;;
        -r | --repo)
            if [[ -z "${2:-}" ]]; then
                log_error "Option $1 requires an argument"
                show_help
                exit 1
            fi
            repo_url="$2"
            shift 2
            ;;
        -b | --branch)
            if [[ -z "${2:-}" ]]; then
                log_error "Option $1 requires an argument"
                show_help
                exit 1
            fi
            branch="$2"
            export BRANCH_NAME="$branch"
            shift 2
            ;;
        -v | --verbose)
            verbose=true
            export DOTFILES_DEBUG=1
            set -x
            shift
            ;;
        --chezmoi-only)
            chezmoi_only=true
            shift
            ;;
        --no-restart)
            no_restart=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        esac
    done

    # Show logo and start installation
    echo "$DOTFILES_LOGO"

    log_info "Starting dotfiles environment setup..."
    log_info "Repository: $repo_url"
    log_info "Branch: $branch"

    # Detect system information
    local os arch ostype
    os="$(detect_os)"
    arch="$(detect_arch)"
    ostype="$(get_os_type)"

    log_info "Detected system: $ostype ($os) on $arch architecture"

    # Initialize OS environment
    initialize_os_env

    # Install chezmoi
    install_chezmoi "$os" "$arch"

    # Exit early if only installing chezmoi
    if [[ "$chezmoi_only" == true ]]; then
        log_success "chezmoi installation completed!"
        log_info "You can now initialize your dotfiles with:"
        log_info "  chezmoi init $repo_url"
        log_info "  chezmoi apply"
        return 0
    fi

    # Initialize dotfiles configuration
    initialize_dotfiles "$repo_url"

    log_success "Dotfiles environment setup completed!"
    log_info "You can manage your configuration with:"
    log_info "  chezmoi status    # Check status"
    log_info "  chezmoi diff      # Show differences"
    log_info "  chezmoi apply     # Apply changes"
    log_info "  chezmoi update    # Update from repository"

    # Restart shell unless disabled
    if [[ "$no_restart" == false ]] && ! is_ci; then
        restart_shell
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]] || [[ "${0}" == "bash" ]] || [[ "${0}" == "-bash" ]]; then
    main "$@"
fi
