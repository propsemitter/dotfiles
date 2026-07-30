#!/usr/bin/env bash

set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d_%H%M%S)"

info()    { echo -e "\033[0;34m[INFO]\033[0m  $1"; }
success() { echo -e "\033[0;32m[OK]\033[0m    $1"; }
warning() { echo -e "\033[0;33m[WARN]\033[0m  $1"; }
error()   { echo -e "\033[0;31m[ERROR]\033[0m $1"; exit 1; }

backup_and_link() {
  local src="$1"
  local dest="$2"

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$BACKUP_DIR"
    warning "Backing up existing $dest → $BACKUP_DIR/"
    mv "$dest" "$BACKUP_DIR/"
  fi

  mkdir -p "$(dirname "$dest")"
  ln -sf "$src" "$dest"
  success "Linked $dest → $src"
}

echo ""
echo "╔═══════════════════════════════╗"
echo "║     idaldu/dotfiles setup     ║"
echo "╚═══════════════════════════════╝"
echo ""

# Update git submodules
git -C "$DOTFILES" submodule update --init --recursive


# ── Neovim ──────────────────────────────────────────────────────────────────
info "Setting up Neovim (LazyVim)..."
backup_and_link "$DOTFILES/nvim" "$HOME/.config/nvim"

# ── tmux ────────────────────────────────────────────────────────────────────
info "Setting up tmux..."
backup_and_link "$DOTFILES/tmux/.tmux.conf" "$HOME/.tmux.conf"

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  info "Installing tmux plugin manager (tpm)..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  success "tpm installed. Press prefix + I inside tmux to install plugins."
else
  success "tpm already installed"
fi

# ── Yazi ────────────────────────────────────────────────────────────────────
info "Setting up Yazi..."
backup_and_link "$DOTFILES/yazi" "$HOME/.config/yazi"

# ── Ghostty ─────────────────────────────────────────────────────────────────
info "Setting up Ghostty..."
backup_and_link "$DOTFILES/ghostty" "$HOME/.config/ghostty"

# ── Done ────────────────────────────────────────────────────────────────────
echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║  ✓ All done! Next steps:                              ║"
echo "║                                                       ║"
echo "║  Neovim: run 'nvim' — plugins install automatically   ║"
echo "║  tmux:   press prefix (C-s) + I to install plugins    ║"
echo "║  yazi:   run 'yazi' — theme applied automatically     ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""
