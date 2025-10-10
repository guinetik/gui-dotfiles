/~/.ssh/email@guinetik.com# ~/.bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Initialize zoxide (smarter cd command)
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init bash)"
fi

# Source shared aliases
if [ -f "$HOME/.config/shell/aliases.sh" ]; then
    source "$HOME/.config/shell/aliases.sh"
fi

# Enable starship prompt
if command -v starship &> /dev/null; then
  eval "$(starship init bash)"
fi

# Enable color support
export TERM=xterm-256color

# Set editor
export EDITOR=nano[ -s "/root/.jabba/jabba.sh" ] && source "/root/.jabba/jabba.sh"
export JABBA_HOME="$HOME/.jabba"
[ -s "$JABBA_HOME/jabba.sh" ] && source "$JABBA_HOME/jabba.sh"
# Maven Daemon (mvnd)
export MVND_HOME="/root/.mvnd/maven-mvnd-1.0.2-linux-amd64"
export PATH="$MVND_HOME/bin:$PATH"

# pyenv setup
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

#VPS setup
export GUINETIK_SERVER = "45.32.174.122"
export BWS_ACCESS_TOKEN = "0.b6b3e709-6a95-42dc-8fd8-b36c0078dc60.JVOjV0v9CAAHDDNcV9wynr6iZo8RpX:FJj/X6sYYth7/xlSr16nag=="
export GUINETIK_KEY = "~/.ssh/email@guinetik.com"

guinetikssh() {
    if [ -n "$1" ]; then
        ssh -i "$GUINETIK_KEY" "root@$GUINETIK_SERVER" "$@"
    else
        ssh -i "$GUINETIK_KEY" "root@$GUINETIK_SERVER"
    fi
}
alias gssh='guinetikssh'
