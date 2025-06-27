# Dotfiles

> ❕ Personal use only.

## Quick Start

### Linux/macOS (Bash)

```bash
# Direct execution from GitHub 
bash -c "$(curl -fsSL https://raw.githubusercontent.com/NicodeSS/dotfiles/main/install.sh)"

# Or clone and run locally
git clone https://github.com/NicodeSS/dotfiles.git
cd dotfiles
./install.sh
```

## Features

- **Automatic chezmoi installation**: Downloads and installs chezmoi on systems where it's not available
- **Package manager support**:
  - Linux: apt, yum, dnf, pacman, zypper
  - macOS: Homebrew
  - WSL: depends on base system
- **CI/CD friendly**: Works in non-interactive environments
- **Robust error handling**: Comprehensive logging and fallback mechanisms
- **Shell restart**: Automatically restarts shell to load new configurations

## Script Options

### Bash Script (`install.sh`)

```bash
./install.sh [options]

Options:
  -h, --help              Show help message
  -r, --repo URL          Specify dotfiles repository URL
  -b, --branch BRANCH     Specify git branch (default: main)
  -v, --verbose           Enable verbose output
  --skip-install-scripts  Skip running installation scripts
  --chezmoi-only          Only install chezmoi, don't initialize configuration
  --no-restart            Don't restart shell after installation

Examples:
  ./install.sh                                          # Use default settings
  ./install.sh -r https://github.com/user/dots         # Specify repository
  ./install.sh --chezmoi-only                           # Only install chezmoi
  ./install.sh -v --branch develop                      # Verbose mode with custom branch
```

## Environment Variables

- `DOTFILES_DEBUG`: Enable debug output
- `BRANCH_NAME`: Git branch to use (default: main)
- `CI`: Detect CI environment for non-interactive mode

## Customization

Before using the scripts, update the repository URL in both files:

**install.sh**:

```bash
readonly DEFAULT_REPO_URL="https://github.com/YOUR_USERNAME/dotfiles.git"
```

### Debug Mode

Enable debug output for troubleshooting:

```bash
# Linux/macOS
DOTFILES_DEBUG=1 ./install.sh -v
```
