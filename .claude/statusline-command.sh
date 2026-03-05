#!/bin/sh
# Claude Code statusline script
# Displays: user@host cwd [git branch] | model | context usage

input=$(cat)

# Extract fields
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Shorten cwd: replace $HOME with ~
home="$HOME"
short_cwd="${cwd/#$home/~}"

# Git branch (skip lock to avoid blocking)
git_branch=""
if [ -d "$cwd/.git" ] || git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  git_branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
fi

# Build context usage display
context_str=""
if [ -n "$used_pct" ]; then
  # Round to integer
  used_int=$(printf "%.0f" "$used_pct")
  context_str="ctx: ${used_int}% used"
fi

# Build location segment
location="${short_cwd}"
if [ -n "$git_branch" ]; then
  location="${location} (${git_branch})"
fi

# Build model segment
model_str=""
if [ -n "$model" ]; then
  model_str="${model}"
fi

# Assemble statusline with ANSI colors
# Colors will be dimmed by Claude Code's terminal
printf "\033[32m%s\033[0m \033[34m%s\033[0m" "$(whoami)@$(hostname -s)" "$location"

if [ -n "$model_str" ]; then
  printf " \033[0m|\033[0m \033[36m%s\033[0m" "$model_str"
fi

if [ -n "$context_str" ]; then
  printf " \033[0m|\033[0m \033[33m%s\033[0m" "$context_str"
fi

printf "\n"
