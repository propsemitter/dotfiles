-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Настройка для работы команд в русской раскладке
local ru = "ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ"
  .. "йцукенгшщзхъфывапролджэячсмитьбю"
local en = 'QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>' .. "qwertyuiop[]asdfghjkl;'zxcvbnm,."

vim.opt.langmap = vim.fn.escape(ru, '," ') .. ";" .. vim.fn.escape(en, '," ')
