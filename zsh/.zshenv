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
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Homebrew (macOS). Here for non-interactive shells; .zshrc re-applies it
# because /etc/zprofile's path_helper pushes /usr/bin back in front for login shells.
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

# Local model storage. When the external drive is mounted, Ollama and the
# Hugging Face cache (MLX-LM, transformers) keep models on it; when it isn't,
# both fall back to their defaults on the internal disk. To use another
# volume, set AI_MODELS_ROOT in ~/.zshenv.local (machine-local, not in the
# repo; ~/.zshrc.local loads too late for this). LM Studio has no env var for
# this — point it at $AI_MODELS_ROOT/lmstudio in its settings.
# Note: launchd-started servers (brew services ollama) don't read this file.
[ -f "$HOME/.zshenv.local" ] && . "$HOME/.zshenv.local"
AI_MODELS_ROOT="${AI_MODELS_ROOT:-/Volumes/Models}"
if [ -d "$AI_MODELS_ROOT" ]; then
  export OLLAMA_MODELS="$AI_MODELS_ROOT/ollama"
  export HF_HOME="$AI_MODELS_ROOT/huggingface"
fi
