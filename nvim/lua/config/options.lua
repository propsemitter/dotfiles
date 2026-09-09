-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Настройка для работы команд в русской раскладке
local ru = "ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ"
  .. "йцукенгшщзхъфывапролджэячсмитьбю"
local en = 'QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>' .. "qwertyuiop[]asdfghjkl;'zxcvbnm,."

vim.opt.langmap = vim.fn.escape(ru, '," ') .. ";" .. vim.fn.escape(en, '," ')

-- Размер шрифта для GUI-клиентов Neovim (Neovide, VimR и т.д.)
vim.opt.guifont = "IosevkaTerm Nerd Font:h15"

-- Современный пословный алгоритм диффов (GitHub-style linematch)
vim.opt.diffopt = {
  "internal",
  "filler",
  "closeoff",
  "algorithm:histogram",
  "linematch:60",
  "indent-heuristic",
}

-- Синхронизация вертикального и горизонтального скролла в сплитах
vim.opt.scrollopt = { "ver", "hor", "jump" }

-- Чистые разделители и заполнители без устаревших `---` и `~`
vim.opt.fillchars = {
  diff = " ",
  eob = " ",
  fold = " ",
  foldopen = "",
  foldclose = "",
  vert = "│",
  horiz = "─",
}

vim.opt.mousescroll = "ver:1,hor:1"
vim.opt.smoothscroll = true
vim.opt.scrolloff = 5
vim.opt.ttyfast = true
