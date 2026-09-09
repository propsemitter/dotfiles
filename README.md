# dotfiles

Personal configuration for **Neovim** (LazyVim), **tmux**, **Yazi**, and **Zsh**.

## What's included

| Tool | Config |
|------|--------|
| [Neovim](https://neovim.io) | LazyVim + extras: TypeScript, Vue, Copilot, JSON + ESLint formatting via `eslint_d` |
| [tmux](https://github.com/tmux/tmux) | Catppuccin Mocha theme, sensible keymaps, mouse support |
| [Yazi](https://github.com/sxyazi/yazi) | Catppuccin Mocha theme |
| [Ghostty](https://ghostty.org) | IosevkaTerm Nerd Font, Catppuccin Mocha, hidden titlebar |
| [Oh My Pi](https://github.com/can1357/oh-my-pi) | Agent, TUI, frontend LSP, and official Figma MCP settings |
| [Zsh](https://www.zsh.org/) | `ompw` wrapper that keeps Oh My Pi awake while it runs |

## Install

```bash
git clone git@github.com:idaldu/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

The script creates symlinks and backs up any existing linked configs to `~/.dotfiles-backup-<timestamp>/`.
The OMP repository configs are linked to `~/.omp/agent/config.yml`, `~/.omp/agent/lsp.json`, and `~/.omp/agent/mcp.json`; runtime databases, logs, and caches remain outside the repository.

### Zsh and `ompw`

The installer links `zsh/omp.zsh` to `~/.config/zsh/omp.zsh`, creates `~/.zshrc` only when it does not exist, and adds the conditional source line once. It never replaces an existing `~/.zshrc`.

Use the wrapper with the same arguments as `omp`:

```bash
ompw --help
```

On macOS, `ompw` runs OMP through `caffeinate -i`. On Linux, it uses `systemd-inhibit --what=sleep --why="Oh My Pi agent is running" --mode=block` when that command is available; otherwise it falls back to a regular `omp` invocation.

Open a new Zsh session after installation, or load the configuration in the current session:

```bash
source ~/.zshrc
```

## Requirements

Install these first:

```bash
# macOS
brew install neovim tmux yazi ghostty node git ripgrep fd lazygit

# Neovim extras (for LazyVim)
brew install luarocks stylua
```

The current `typescript-language-server` requires Node.js 22.22.2 or newer.

### After install

- **Neovim** — open `nvim`, plugins install automatically via lazy.nvim. Run `:MasonInstall eslint_d` once for ESLint formatting.
- **Oh My Pi** — frontend LSP servers are installed globally through npm; project-local binaries in `node_modules/.bin` still take precedence. Complete the [Figma MCP setup](#figma-mcp) on each machine.
- **tmux** — press `C-s + I` (prefix + I) to install plugins (catppuccin theme).
- **Zsh / `ompw`** — run `ompw` with the same arguments as `omp`; it keeps the system awake during the agent run.
- **Yazi** — runs as-is with Catppuccin theme.

## Neovim extras enabled

- `lazyvim.plugins.extras.ai.copilot`
- `lazyvim.plugins.extras.lang.json`
- `lazyvim.plugins.extras.lang.typescript`
- `lazyvim.plugins.extras.lang.vue`

## Oh My Pi frontend LSP

The installer configures language intelligence for:

- TypeScript, JavaScript, and React (`typescript-native` with TypeScript 7+, `typescript-language-server` with TypeScript 6 and older)
- Vue (`vue-language-server`)
- ESLint (`vscode-eslint-language-server`)
- HTML, CSS, SCSS, Less, and JSON (`vscode-langservers-extracted`)
- Tailwind CSS, including v4 projects without `tailwind.config.*`
- YAML (`yaml-language-server`)

Run `omp` from the project root. OMP 18.1.11 checks root markers only in its current working directory; launching it from a parent directory without `package.json`, `tsconfig.json`, or another matching marker can legitimately show `No LSP servers`.

Use the LSP `status` action after changing `~/.omp/agent/lsp.json`, or reload the workspace so OMP rebuilds its cached server selection. A project-local language server is preferred over the global fallback installed by this repository.

## Figma MCP

The installer includes Figma's desktop MCP server in OMP. Before using it on each machine, make sure you have:

- The latest Figma desktop app.
- A paid Figma plan with a Dev or Full seat.
- A Figma Design file open in the desktop app.
- Dev Mode enabled with `Shift+D`.
- **Inspect → MCP server → Enable desktop MCP server** enabled.

Keep the Figma app and its MCP server running while using OMP. Then run these commands inside OMP:

```text
/mcp reload
/mcp test figma-desktop
```

To work from a design, copy a Figma selection URL and include it in the prompt, for example:

```text
Inspect this Figma selection: https://www.figma.com/design/AbCdEf1234567890/Checkout?node-id=123-456&m=dev
```
