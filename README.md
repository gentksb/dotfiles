# dotfiles

takagen's dotfiles

Console theme by Codespaces default.

![CI](https://github.com/gentksb/dotfiles/workflows/CI/badge.svg)

## Supported Platforms

- **macOS** (Apple Silicon / Intel)
- **Linux** (Ubuntu/Debian-based distributions)
- **WSL** (Windows Subsystem for Linux)

## Features

### Common Tools
- Git configuration
- direnv
- fzf (fuzzy finder)
- Codespaces-optimized bash prompt

### macOS Specific
- Homebrew package manager (auto-installed)
- GitHub CLI (gh)
- jq (JSON processor)
- Bitwarden CLI
- Claude Code CLI
- uv (Python package manager)
- GUI Applications:
  - **Productivity & Utilities**:
    - RayCast (launcher)
    - Rectangle (window manager)
    - Karabiner-Elements (keyboard customizer)
    - Alt-Tab (window switcher)
  - **Development Tools**:
    - Visual Studio Code (code editor)
    - Ghostty (terminal emulator)
    - OrbStack (container runtime)
  - **Browsers**:
    - Google Chrome
  - **Communication**:
    - Slack
    - Discord

### Development Environment
- **Node.js**: Managed via pnpm
- **Python**: Managed via uv

## Installation

### macOS

```bash
git clone https://github.com/gentksb/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installation script will:
1. Install Homebrew (if not already installed)
2. Install all CLI tools and GUI applications
3. Create symlinks for dotfiles in your home directory
4. Backup existing dotfiles to `~/.dotbackup`

After installation:
- Restart your terminal or run `source ~/.bash_profile`
- Authenticate Claude Code CLI: Run `claude` and follow the OAuth authentication flow (requires Claude Pro/Max or active billing)
- Grant necessary permissions to GUI applications (Karabiner-Elements, Rectangle)
- Configure RayCast and other applications according to your preferences

### Linux / WSL

```bash
git clone https://github.com/gentksb/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installation script will:
1. Install required packages via apt-get
2. Install fzf from source
3. Create symlinks for dotfiles in your home directory
4. Backup existing dotfiles to `~/.dotbackup`

After installation, restart your terminal or run `source ~/.bashrc`

## Automatic Installation

Dotfiles are automatically installed when:
- GitHub Codespaces is created
- VSCode remote container is created

## Configuration

### Shell
- `.bashrc` - Main bash configuration (cross-platform)
- `.bash_profile` - macOS login shell configuration

### Git
- `.gitconfig` - Git user configuration
- `.gitignore_global` - Global gitignore patterns

## Notes

### macOS
- Uses system default color scheme (no custom terminal colors)
- Homebrew is installed to `/opt/homebrew` (Apple Silicon) or `/usr/local` (Intel)
- GUI applications and Claude Code CLI can be skipped in CI environments by setting `CI=true`
- Claude Code CLI requires authentication after installation (Claude Pro/Max subscription or active billing)

### Linux/WSL
- Uses dircolors for terminal color customization
- WSL-specific browser integration via wslview

## Development

This repository includes:
- CI/CD testing on both Ubuntu and macOS
- DevContainer configuration for VSCode
- Claude AI integration with Japanese language support

## License

Personal dotfiles - use at your own discretion
