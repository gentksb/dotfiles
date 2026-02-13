#!/usr/bin/env bash
set -ue

# Detect OS
detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macos"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [ -n "${WSL_DISTRO_NAME:-}" ]; then
      echo "wsl"
    else
      echo "linux"
    fi
  else
    echo "unknown"
  fi
}

OS=$(detect_os)

# Install Homebrew on macOS
install_homebrew() {
  if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for this session
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
      # Apple Silicon
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
      # Intel Mac
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  else
    echo "Homebrew is already installed"
  fi
}

# Install packages on macOS
install_macos_packages() {
  echo "Installing macOS packages..."

  # Install CLI tools
  brew install direnv git curl fzf gh jq

  # Install uv (Python package manager)
  brew install uv

  # Install GUI applications (skip in CI environment)
  if [ -z "${CI:-}" ]; then
    echo "Installing GUI applications..."

    # Productivity & Utilities
    brew install --cask raycast
    brew install --cask macsyzones
    brew install --cask alt-tab

    # Development Tools
    brew install --cask visual-studio-code
    brew install --cask ghostty
    brew install --cask orbstack

    # Browsers
    brew install --cask google-chrome

    # Communication
    brew install --cask slack
    brew install --cask discord

    # Password Manager
    brew install --cask bitwarden
  else
    echo "Skipping GUI applications in CI environment"
  fi

  # Install fzf key bindings and fuzzy completion
  $(brew --prefix)/opt/fzf/install --all
}

# Install packages on Linux
install_linux_packages() {
  echo "Installing Linux packages..."
  sudo apt-get update
  sudo apt-get install -y direnv git curl

  # Install wslu for WSL
  if [[ "$OS" == "wsl" ]]; then
    sudo apt-get install -y wslu
  fi

  # Install fzf
  rm -rf ~/.fzf
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install --all
}

# Link dotfiles to home directory
link_to_homedir() {
  echo "Backing up old dotfiles..."

  if [ ! -d "$HOME/.dotbackup" ]; then
    echo "$HOME/.dotbackup not found. Creating it..."
    mkdir "$HOME/.dotbackup"
  fi

  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  for dotfile in "$script_dir"/.??* ; do
    local basename_file=$(basename "$dotfile")

    # Skip these directories
    [[ "$basename_file" == ".git" ]] && continue
    [[ "$basename_file" == ".github" ]] && continue
    [[ "$basename_file" == ".devcontainer" ]] && continue
    [[ "$basename_file" == ".claude" ]] && continue

    # Remove existing symlink
    if [[ -L "$HOME/$basename_file" ]]; then
      rm -f "$HOME/$basename_file"
    fi

    # Backup existing file
    if [[ -e "$HOME/$basename_file" ]]; then
      mv "$HOME/$basename_file" "$HOME/.dotbackup"
    fi

    # Create symlink
    ln -snf "$dotfile" "$HOME"
    echo "Linked: $dotfile"
  done
}

# Main installation flow
main() {
  echo "Detected OS: $OS"

  case "$OS" in
    macos)
      install_homebrew
      install_macos_packages
      ;;
    linux|wsl)
      install_linux_packages
      ;;
    *)
      echo "Unsupported OS: $OSTYPE"
      exit 1
      ;;
  esac

  link_to_homedir

  echo -e "\e[1;36m Install completed!!!! \e[m"
  echo ""
  if [[ "$OS" == "macos" ]]; then
    echo "Please restart your shell or run: source ~/.zshrc"
  else
    echo "Please restart your shell or run: source ~/.bashrc"
  fi

  if [[ "$OS" == "macos" ]]; then
    echo ""
    echo "macOS specific notes:"
    echo "  - Homebrew has been installed"
    if [ -z "${CI:-}" ]; then
      echo "  - GUI applications have been installed via Homebrew Cask"
      echo "  - Claude Code CLI need to installed manually (requires authentication)"
      echo "  - You may need to grant permissions to some applications (Karabiner-Elements, Rectangle)"
      echo "  - Consider configuring RayCast and Karabiner-Elements according to your preferences"
    else
      echo "  - GUI applications and Claude Code CLI were skipped (CI environment)"
    fi
  fi
}

main
