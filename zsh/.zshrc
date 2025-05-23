# .zshrc - Zsh Configuration File

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt sharehistory
setopt incappendhistory
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_verify

# Basic zsh options
setopt autocd
setopt extended_glob
setopt nomatch
setopt notify
unsetopt beep
bindkey -e  # Use emacs key bindings

# Load colors for the terminal
autoload -U colors && colors

# Set up Antidote (Plugin Manager)
ANTIDOTE_HOME="$HOME/.antidote"
if [[ ! -d $ANTIDOTE_HOME ]]; then
  echo "Antidote not found. Installing..."
  git clone --depth=1 https://github.com/mattmc3/antidote.git ${ANTIDOTE_HOME}
fi
source ${ANTIDOTE_HOME}/antidote.zsh

# Load plugins (static)
if [[ -f ${ZDOTDIR:-$HOME}/.zsh_plugins.zsh ]]; then
  source ${ZDOTDIR:-$HOME}/.zsh_plugins.zsh
# If static file doesn't exist, generate it
elif [[ -f ${ZDOTDIR:-$HOME}/.zsh_plugins.txt ]]; then
  echo "Generating static plugins file..."
  antidote bundle < ${ZDOTDIR:-$HOME}/.zsh_plugins.txt > ${ZDOTDIR:-$HOME}/.zsh_plugins.zsh
  source ${ZDOTDIR:-$HOME}/.zsh_plugins.zsh
fi

# Completion system initialization (should be after plugin loading)
autoload -Uz compinit
compinit

# Prompt - Use starship if available
if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
else
  # Basic prompt if starship isn't available
  PROMPT="%B%F{green}%n@%m%f%b:%B%F{blue}%~%f%b$ "
fi

# Enable correction
setopt correct

# Include useful aliases
if [ -f ~/.aliases ]; then
  source ~/.aliases
fi

# Add aliases for directory management
alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# Modern CLI tool aliases - if installed

# exa (ls replacement)
if command -v exa &> /dev/null; then
  alias ls='exa'
  alias ll='exa -la'
  alias lt='exa -T'
  alias la='exa -a'
fi

# bat (cat replacement)
if command -v bat &> /dev/null; then
  alias cat='bat'
fi

# ripgrep (grep replacement)
if command -v rg &> /dev/null; then
  alias grep='rg'
  alias rgf='rg --files-with-matches'
  alias rgh='rg --hidden'
  alias rgl='rg -l'
  alias rgc='rg --count'
  alias rgn='rg --no-ignore'
  alias rgj='rg --json'
  alias find-code='rg --type py --type js --type html --type ts --type css'
fi

# fd (find replacement)
if command -v fd &> /dev/null; then
  alias find='fd'
fi

# dust (du replacement)
if command -v dust &> /dev/null; then
  alias du='dust'
fi

# procs (ps replacement)
if command -v procs &> /dev/null; then
  alias ps='procs'
fi

# bottom (top replacement)
if command -v btm &> /dev/null; then
  alias top='btm'
fi

# bandwhich (network monitoring)
if command -v bandwhich &> /dev/null; then
  alias netmon='bandwhich'
fi

# tldr (command examples)
if command -v tldr &> /dev/null; then
  alias help='tldr'
fi

# Zoxide (cd alternative) 
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
  alias cd="z"
  alias zz="z -"
  alias zi="z -i"
fi

# Development environment setup

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Pyenv (Python Version Manager)
if command -v pyenv &> /dev/null; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi

# Jabba (Java Version Manager)
[ -s "$HOME/.jabba/jabba.sh" ] && source "$HOME/.jabba/jabba.sh"

# Rust
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# Local bin directory
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

# Custom functions

# Create a directory and cd into it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Extract common archive formats
extract() {
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1     ;;
      *.tar.gz)    tar xzf $1     ;;
      *.bz2)       bunzip2 $1     ;;
      *.rar)       unrar e $1     ;;
      *.gz)        gunzip $1      ;;
      *.tar)       tar xf $1      ;;
      *.tbz2)      tar xjf $1     ;;
      *.tgz)       tar xzf $1     ;;
      *.zip)       unzip $1       ;;
      *.Z)         uncompress $1  ;;
      *.7z)        7z x $1        ;;
      *)           echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Interactive way to choose commands from history
fh() {
  print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed -E 's/ *[0-9]*\*? *//' | sed -E 's/\\/\\\\/g')
}

# Load custom user configurations if they exist
[ -f ~/.zshrc.local ] && source ~/.zshrc.local