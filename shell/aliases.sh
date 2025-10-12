# Shared aliases for modern CLI tools
# This file is sourced by both .bashrc and .zshrc

# Basic navigation aliases
alias cb='z ..'   # cd back (go up one directory)
alias cls='clear'
alias gh='history | grep'

# Eza/Exa (ls replacement) - comprehensive aliases
# Eza is the maintained fork of exa, check for both
if command -v eza &> /dev/null; then
  alias ls='eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions'
  alias ll='eza -la --icons=always --git'
  alias lt='eza -T --git-ignore --icons=always'      # Tree view
  alias lg='eza -l --git --icons=always'             # Show git status
  alias lh='eza -la --sort=modified --icons=always'  # Show latest modified files
  alias la='eza -a --icons=always'
elif command -v exa &> /dev/null; then
  alias ls='exa --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions'
  alias ll='exa -la --icons=always --git'
  alias lt='exa -T --git-ignore --icons=always'      # Tree view
  alias lg='exa -l --git --icons=always'             # Show git status
  alias lh='exa -la --sort=modified --icons=always'  # Show latest modified files
  alias la='exa -a --icons=always'
fi

# Bat (cat/less replacement)
if command -v bat &> /dev/null; then
  alias cat='bat --paging=never'      # Use bat instead of cat
  alias less='bat --paging=always'    # Use bat instead of less
fi

# Ripgrep (grep replacement) - comprehensive aliases
if command -v rg &> /dev/null; then
  alias grep='rg --smart-case'                # Case-insensitive if pattern is all lowercase
  alias rgf='rg --files | rg'               # Search filenames only
  alias rgh='rg --hidden'                   # Include hidden files
  alias rgl='rg -l'                         # List files with matches only
  alias rgc='rg --count'                    # Count matches per file
  alias rgn='rg --no-ignore'                # Don't respect ignore files
  alias rgj='rg --json | jq'                # Output as JSON and pipe to jq
  alias find-code='rg -t py -t js -t html'  # Search only in code files
else
  alias grep='grep --color=auto'
fi

# Fd (find replacement)
if command -v fd &> /dev/null; then
  alias find='fd'
fi

# Dust (du replacement)
if command -v dust &> /dev/null; then
  alias du='dust'
fi

# Procs (ps replacement)
if command -v procs &> /dev/null; then
  alias ps='procs'
fi

# Bottom (top replacement)
if command -v btm &> /dev/null; then
  alias top='btm'
fi

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