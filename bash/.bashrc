# ~/.bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# User specific aliases and functions
# Use exa instead of ls - https://github.com/ogham/exa
alias ls='exa'
alias ll='exa -la'
alias lt='exa -T --git-ignore'      # Tree view
alias lg='exa -l --git'             # Show git status
alias lh='exa -la --sort=modified'  # Show latest modified files
alias grep='grep --color=auto'
# Note: cd is aliased to z (zoxide) below
alias cb='z ..'
alias cls='clear'
alias gh='history | grep'

# Initialize zoxide (smarter cd command)
eval "$(zoxide init bash)"

# Zoxide aliases - replace cd with smarter navigation
alias cd='z'    # z is the zoxide alternative to cd
alias zz='z -'  # Go back to previous directory
alias zi='zi'   # Interactive selection using fzf

# Ripgrep aliases - powerful search tool
alias rg='rg --smart-case'                # Case-insensitive if pattern is all lowercase
alias rgf='rg --files | rg'               # Search filenames only
alias rgh='rg --hidden'                   # Include hidden files
alias rgl='rg -l'                         # List files with matches only
alias rgc='rg --count'                    # Count matches per file
alias rgn='rg --no-ignore'                # Don't respect ignore files
alias rgj='rg --json | jq'                # Output as JSON and pipe to jq
alias find-code='rg -t py -t js -t html'  # Search only in code files

# Modern replacements for standard tools
alias find='fd'                           # Use fd instead of find
alias ps='procs'                          # Use procs instead of ps
alias du='dust'                           # Use dust instead of du
alias top='btm'                           # Use bottom instead of top
alias cat='bat --paging=never'            # Use bat instead of cat
alias less='bat --paging=always'          # Use bat instead of less
alias tldr='tealdeer'                     # tldr for command examples

# Network monitoring
alias netmon='bandwhich'                  # Network bandwidth utilization

# Enable starship prompt
eval "$(starship init bash)"

# Enable color support
export TERM=xterm-256color

# Set editor
export EDITOR=nano