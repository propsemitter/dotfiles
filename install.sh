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

  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    success "Already linked $dest → $src"
    return
  fi

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

# ── Zsh ─────────────────────────────────────────────────────────────────────
info "Setting up Zsh..."
backup_and_link "$DOTFILES/zsh/omp.zsh" "$HOME/.config/zsh/omp.zsh"

if [ ! -e "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
  touch "$HOME/.zshrc"
  success "Created $HOME/.zshrc"
fi

ZSH_OMP_SOURCE='[ -f "$HOME/.config/zsh/omp.zsh" ] && source "$HOME/.config/zsh/omp.zsh"'
if ! grep -Fqx "$ZSH_OMP_SOURCE" "$HOME/.zshrc"; then
  if [ -s "$HOME/.zshrc" ]; then
    printf '\n%s\n' "$ZSH_OMP_SOURCE" >> "$HOME/.zshrc"
  else
    printf '%s\n' "$ZSH_OMP_SOURCE" >> "$HOME/.zshrc"
  fi
  success "Added ompw to $HOME/.zshrc"
else
  success "ompw already configured in $HOME/.zshrc"
fi

# ── Oh My Pi ────────────────────────────────────────────────────────────────
info "Setting up Oh My Pi..."
backup_and_link "$DOTFILES/omp/agent/config.yml" "$HOME/.omp/agent/config.yml"
backup_and_link "$DOTFILES/omp/agent/lsp.json" "$HOME/.omp/agent/lsp.json"
backup_and_link "$DOTFILES/omp/agent/mcp.json" "$HOME/.omp/agent/mcp.json"

LSP_BINARIES=(
  tsc
  typescript-language-server
  vue-language-server
  vscode-eslint-language-server
  vscode-html-language-server
  vscode-css-language-server
  vscode-json-language-server
  tailwindcss-language-server
  yaml-language-server
)

missing_lsp_binaries=()
for binary in "${LSP_BINARIES[@]}"; do
  if ! command -v "$binary" >/dev/null 2>&1; then
    missing_lsp_binaries+=("$binary")
  fi
done

if [ "${#missing_lsp_binaries[@]}" -gt 0 ]; then
  command -v npm >/dev/null 2>&1 || error "npm is required to install OMP language servers"
  info "Installing OMP language servers (missing: ${missing_lsp_binaries[*]})..."
  npm install --global \
    typescript \
    typescript-language-server \
    @vue/language-server \
    vscode-langservers-extracted \
    @tailwindcss/language-server \
    yaml-language-server
  success "OMP language servers installed"
else
  success "OMP language servers already installed"
fi

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
