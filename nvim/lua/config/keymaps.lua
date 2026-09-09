local map = vim.keymap.set
local msg = '"Используй h j k l, лентяй!"'

map("n", "<Up>", "<cmd>echom " .. msg .. "<CR>", { noremap = true })
map("n", "<Down>", "<cmd>echom " .. msg .. "<CR>", { noremap = true })
map("n", "<Left>", "<cmd>echom " .. msg .. "<CR>", { noremap = true })
map("n", "<Right>", "<cmd>echom " .. msg .. "<CR>", { noremap = true })

map("i", "<Up>", "<cmd>echom " .. msg .. "<CR>", { noremap = true })
map("i", "<Down>", "<cmd>echom " .. msg .. "<CR>", { noremap = true })
map("i", "<Left>", "<cmd>echom " .. msg .. "<CR>", { noremap = true })
map("i", "<Right>", "<cmd>echom " .. msg .. "<CR>", { noremap = true })

map("v", "<Up>", "<cmd>echom " .. msg .. "<CR>", { noremap = true })
map("v", "<Down>", "<cmd>echom " .. msg .. "<CR>", { noremap = true })
map("v", "<Left>", "<cmd>echom " .. msg .. "<CR>", { noremap = true })
map("v", "<Right>", "<cmd>echom " .. msg .. "<CR>", { noremap = true })

-- Copy file path keymaps
map("n", "<leader>fr", function()
  local abs_path = vim.api.nvim_buf_get_name(0)
  if abs_path ~= "" then
    local rel_path = vim.fn.fnamemodify(abs_path, ":.")
    vim.fn.setreg("+", rel_path)
    vim.notify("Copied relative path: " .. rel_path, vim.log.levels.INFO)
  else
    vim.notify("No file name for current buffer", vim.log.levels.WARN)
  end
end, { desc = "Copy relative path" })

map("n", "<leader>fY", function()
  local abs_path = vim.api.nvim_buf_get_name(0)
  if abs_path ~= "" then
    vim.fn.setreg("+", abs_path)
    vim.notify("Copied absolute path: " .. abs_path, vim.log.levels.INFO)
  else
    vim.notify("No file name for current buffer", vim.log.levels.WARN)
  end
end, { desc = "Copy absolute path" })

vim.keymap.set("n", "<leader>ts", function()
  vim.opt.spell = not vim.o.spell
end, { desc = "Toggle spell check" })

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Toggle inline red/green diff directly in the buffer (no split)
map("n", "<leader>ght", function()
  local gs = require("gitsigns")
  local shown = gs.toggle_deleted()
  gs.toggle_word_diff(shown)
end, { desc = "Toggle inline diff (red/green)" })

-- Toggle Diffview side-by-side (overrides snacks modal diff)
local function toggle_diffview()
  local ok, dv_lib = pcall(require, "diffview.lib")
  if ok and #dv_lib.views > 0 then
    vim.cmd("DiffviewClose")
  else
    vim.cmd("DiffviewOpen")
  end
end

map("n", "<leader>gd", toggle_diffview, { desc = "Toggle Diffview (Side-by-Side)" })
map("n", "<leader>gv", toggle_diffview, { desc = "Toggle Diffview (Side-by-Side)" })
map("n", "<leader>gD", "<cmd>DiffviewClose<cr>", { desc = "Diffview: Close" })
