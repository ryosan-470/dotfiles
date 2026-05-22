#!/bin/sh
# Claude Code statusLine command
# Based on PS1 from ~/.dotconfig/dotfiles/zsh.d/zim.zsh (asciiship theme)
#
# Original PS1 structure:
#   [SSH: user in host in] cyan-bold-cwd [git-branch] [virtualenv] [duration]
#   [jobs] [exit-status] vimode

input=$(cat)

cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name // ""')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Shorten cwd: replace $HOME with ~
short_cwd=$(echo "$cwd" | sed "s|^$HOME|~|")

# Cyan bold for directory (matching %B%F{cyan}%~%f%b in original PS1)
printf '\033[1;36m%s\033[0m' "$short_cwd"

# Git branch in yellow bold (matching git_info prompt style)
git_branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
  || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
if [ -n "$git_branch" ]; then
  printf ' \033[1;33m(%s)\033[0m' "$git_branch"
fi

# Model name in magenta bold
if [ -n "$model" ]; then
  printf ' \033[1;35m[%s]\033[0m' "$model"
fi

# Context remaining percentage with color tiers (>=50% green, 20-50% yellow, <20% red)
if [ -n "$remaining" ]; then
  pct=$(printf '%.0f' "$remaining")
  if [ "$pct" -ge 50 ]; then
    color='1;32'
  elif [ "$pct" -ge 20 ]; then
    color='1;33'
  else
    color='1;31'
  fi
  printf ' \033[%smctx:%s%%\033[0m' "$color" "$pct"
fi
