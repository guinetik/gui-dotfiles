# .zshenv - Loaded for all zsh instances

# Set default editors
export EDITOR="vim"
if command -v nvim &> /dev/null; then
  export EDITOR="nvim"
fi
export VISUAL=$EDITOR

# Set default pager to less with colors
export PAGER="less"
export LESS="-R"

# Set language and locale
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# XDG Base Directory Specification
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# Ensure various bin directories are in PATH
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
. "$HOME/.cargo/env"
