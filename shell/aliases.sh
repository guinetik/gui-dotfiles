# Shared aliases for modern CLI tools
# This file is sourced by both .bashrc and .zshrc

# Basic navigation aliases
alias cb='z ..'   # cd back (go up one directory)
alias cls='clear'
alias gh='history | grep'

# Modern ls alternative (eza/exa) - available as standalone commands
# Users can use 'eza' or 'exa' directly for the modern features
# We do NOT alias these to 'ls' to maintain GNU compatibility

# Modern cat/less alternative (bat) - available as standalone command
# Users can use 'bat' directly for syntax highlighting
# We do NOT alias these to 'cat' or 'less' to maintain GNU compatibility

# Modern grep alternative (ripgrep) - available as standalone command
# Users can use 'rg' directly for fast, smart searching
# We do NOT alias these to 'grep' to maintain GNU compatibility
# Convenience aliases for ripgrep features:
if command -v rg &> /dev/null; then
  alias rgf='rg --files | rg'               # Search filenames only
  alias rgh='rg --hidden'                   # Include hidden files
  alias rgl='rg -l'                         # List files with matches only
  alias rgc='rg --count'                    # Count matches per file
  alias rgn='rg --no-ignore'                # Don't respect ignore files
  alias rgj='rg --json | jq'                # Output as JSON and pipe to jq
  alias find-code='rg -t py -t js -t html'  # Search only in code files
fi

# Modern find alternative (fd) - available as standalone command
# Users can use 'fd' directly for simpler, faster file searching
# We do NOT alias this to 'find' to maintain GNU compatibility

# Modern du alternative (dust) - available as standalone command
# Users can use 'dust' directly for disk usage analysis
# We do NOT alias this to 'du' to maintain GNU compatibility

# Modern ps alternative (procs) - available as standalone command
# Users can use 'procs' directly for process listing
# We do NOT alias this to 'ps' to maintain GNU compatibility

# Modern top alternative (bottom) - available as standalone command
# Users can use 'btm' directly for system monitoring
# We do NOT alias this to 'top' to maintain GNU compatibility

# Bandwhich (network monitoring)
if command -v bandwhich &> /dev/null; then
  alias netmon='bandwhich'
fi

# Tealdeer (tldr replacement)
if command -v tldr &> /dev/null; then
  alias tldr='tealdeer'
  alias help='tldr'
fi

# Zoxide (cd alternative) - universal setup
if command -v zoxide &> /dev/null; then
  # Note: eval "$(zoxide init <shell>)" should be done in shell-specific configs
  # Zoxide provides 'z' command for smart directory jumping
  alias zz='z -'   # Go back to previous directory
  alias zh='z -l'  # Show zoxide history
  # Uncomment the line below if you want to replace 'cd' with 'z'
  # alias cd='z'
fi

# Oxker (Docker TUI) - use custom config
if command -v oxker &> /dev/null; then
  # Detect the dotfiles directory
  if [ -f "$HOME/gui-dotfiles/oxker/oxker.config.jsonc" ]; then
    alias oxker='oxker --config-file "$HOME/gui-dotfiles/oxker/oxker.config.jsonc"'
  elif [ -f "$HOME/.config/gui-dotfiles/oxker/oxker.config.jsonc" ]; then
    alias oxker='oxker --config-file "$HOME/.config/gui-dotfiles/oxker/oxker.config.jsonc"'
  fi
fi 