# ~/.zshrc: executed by zsh for interactive shells.

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# ============================================================
# Load common shell configuration
# ============================================================
[ -f ~/.shell_common ] && source ~/.shell_common

# ============================================================
# Zsh-specific options
# ============================================================

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=2000
setopt HIST_IGNORE_DUPS       # Don't record duplicate entries
setopt HIST_IGNORE_SPACE      # Don't record entries starting with space
setopt APPEND_HISTORY         # Append to history file
setopt SHARE_HISTORY          # Share history between sessions

# Directory options
setopt AUTO_CD                # cd by typing directory name
setopt AUTO_PUSHD             # Push directories onto stack
setopt PUSHD_IGNORE_DUPS      # Don't push duplicates

# Completion options
setopt COMPLETE_IN_WORD       # Complete from cursor position
setopt ALWAYS_TO_END          # Move cursor to end after completion

# Other useful options
setopt INTERACTIVE_COMMENTS   # Allow comments in interactive shell
setopt NO_BEEP                # Disable beep

# ============================================================
# Completion system
# ============================================================
autoload -Uz compinit
compinit

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# ============================================================
# Prompt (Codespaces-style theme)
# ============================================================
autoload -Uz vcs_info
precmd() { vcs_info }
setopt PROMPT_SUBST

# Git info format
zstyle ':vcs_info:git:*' formats '(%F{red}%b%f) '
zstyle ':vcs_info:*' enable git

# Build prompt
if [ -n "${GITHUB_USER}" ]; then
  PROMPT='%F{green}@${GITHUB_USER}%f %(?..%F{red})➜%f %F{blue}%~%f ${vcs_info_msg_0_}%# '
else
  PROMPT='%F{green}%n%f %(?..%F{red})➜%f %F{blue}%~%f ${vcs_info_msg_0_}%# '
fi

# ============================================================
# Less pager (Linux only)
# ============================================================
if [ "$IS_MACOS" -eq 0 ]; then
  [ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
fi

# ============================================================
# Disable flow control (Linux only)
# ============================================================
if [ "$IS_MACOS" -eq 0 ]; then
  stty stop undef
fi

# ============================================================
# Tool integrations
# ============================================================

# direnv
if command -v direnv &> /dev/null; then
  eval "$(direnv hook zsh)"
fi

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# uv (Python package manager)
if [ "$IS_MACOS" -eq 1 ]; then
  if command -v uv &> /dev/null; then
    eval "$(uv generate-shell-completion zsh)"
  fi
fi

# ============================================================
# Load local settings (not tracked in git)
# ============================================================
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# for Claude code Path completion
export PATH="$HOME/.local/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
