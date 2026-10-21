#!/usr/bin/env bash
# mac/install.sh - provision a Mac from this repo.
#
#   ./mac/install.sh           core dev environment (Brewfile, links, mise)
#   ./mac/install.sh --ai      core + local AI stack (Brewfile.ai, mlx-lm)
#   ./mac/install.sh --links   only (re)create symlinks
#
# Idempotent: brew bundle, mise install and ln -sfn all no-op when satisfied,
# so re-running is how you pick up manifest changes. bash 3.2 compatible —
# this runs before brew has installed a newer bash.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/common/utils.sh"

WITH_AI=""
LINKS_ONLY=""
for arg in "$@"; do
  case "$arg" in
    --ai) WITH_AI=1 ;;
    --links) LINKS_ONLY=1 ;;
    --help|-h) sed -n '2,10p' "$0"; exit 0 ;;
    *) print_error "Unknown option: $arg"; exit 1 ;;
  esac
done

link_dotfiles() {
  print_header "Symlinks"
  LINKS_FILE="$ROOT/mac/links.psv" bash "$ROOT/common/create_symlinks.sh"
}

check_prereqs() {
  print_header "Prerequisites"
  if ! xcode-select -p &>/dev/null; then
    print_error "Xcode Command Line Tools missing. Run: xcode-select --install"
    exit 1
  fi
  if ! command -v brew &>/dev/null; then
    if [ -x /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      print_error "Homebrew missing. Install it from https://brew.sh, then re-run."
      exit 1
    fi
  fi
  print_success "Xcode CLT and Homebrew present"
}

brew_bundle() {
  print_header "brew bundle ($(basename "$1"))"
  brew bundle --file="$1"
}

install_runtimes() {
  print_header "Runtimes (mise)"
  mise install
  # Globals go into mise's node, so they follow `mise use node@...` upgrades.
  mise exec node -- npm install -g branchlet typescript
}

install_ai() {
  brew_bundle "$ROOT/mac/Brewfile.ai"
  print_header "MLX"
  # Pinned: uv otherwise picks the newest Python on PATH (brew pulls one in as
  # a dependency), and sentencepiece/MLX lag new releases, so there's no wheel
  # and the source build fails. uv fetches its own 3.13 if needed.
  uv tool install --python 3.13 mlx-lm
  print_info "Ollama is installed but not running. Start it with: brew services start ollama"
}

main() {
  if [ -n "$LINKS_ONLY" ]; then
    link_dotfiles
    return
  fi
  check_prereqs
  brew_bundle "$ROOT/mac/Brewfile"
  link_dotfiles
  install_runtimes
  [ -n "$WITH_AI" ] && install_ai

  print_header "Done"
  print_info "Open a new Ghostty window (or: exec zsh -l), then run myenv."
}

main
