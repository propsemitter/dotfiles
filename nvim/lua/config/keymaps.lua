-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set
local msg = '"Используй h j k l, лентяй!"'

-- Normal mode
map("n", "<Up>", "<cmd>echom " .. msg .. "<CR>", { noremap = true })
map("n", "<Down>", "<cmd>echom " .. msg .. "<CR>", { noremap = true })
map("n", "<Left>", "<cmd>echom " .. msg .. "<CR>", { noremap = true })
map("n", "<Right>", "<cmd>echom " .. msg .. "<CR>", { noremap = true })

-- Insert mode
map("i", "<Up>", "<cmd>echom " .. msg .. "<CR>", { noremap = true })
map("i", "<Down>", "<cmd>echom " .. msg .. "<CR>", { noremap = true })
map("i", "<Left>", "<cmd>echom " .. msg .. "<CR>", { noremap = true })
map("i", "<Right>", "<cmd>echom " .. msg .. "<CR>", { noremap = true })

-- Visual mode
map("v", "<Up>", "<cmd>echom " .. msg .. "<CR>", { noremap = true })
map("v", "<Down>", "<cmd>echom " .. msg .. "<CR>", { noremap = true })
map("v", "<Left>", "<cmd>echom " .. msg .. "<CR>", { noremap = true })
map("v", "<Right>", "<cmd>echom " .. msg .. "<CR>", { noremap = true })

-- Copy file path keymaps
map("n", "<leader>fr", function()
  local path = vim.fn.expand("%")
  if path ~= "" then
    vim.fn.setreg("+", path)
    vim.notify("Copied relative path: " .. path, vim.log.levels.INFO)
  else
    vim.notify("No file name for current buffer", vim.log.levels.WARN)
  end
end, { desc = "Copy relative path" })

map("n", "<leader>fY", function()
  local path = vim.fn.expand("%:p")
  if path ~= "" then
    vim.fn.setreg("+", path)
    vim.notify("Copied absolute path: " .. path, vim.log.levels.INFO)
  else
    vim.notify("No file name for current buffer", vim.log.levels.WARN)
  end
end, { desc = "Copy absolute path" })


