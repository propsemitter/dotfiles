-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPost" }, {
  pattern = "*.vue",
  callback = function()
    local buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    if #buf_lines == 1 and buf_lines[1] == "" then
      local template = vim.fn.expand("~/.config/nvim/templates/vue.vue")
      local lines = vim.fn.readfile(template)
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    end
  end,
})

local input_source_switcher = "/opt/homebrew/bin/macism"

local function set_english_input_source()
  if vim.fn.executable(input_source_switcher) == 1 then
    vim.fn.jobstart({
      input_source_switcher,
      "com.apple.keylayout.ABC",
      "0",
    }, { detach = true })
  end
end

vim.api.nvim_create_autocmd({ "VimEnter", "FocusGained", "InsertLeave", "CmdlineLeave" }, {
  group = vim.api.nvim_create_augroup("english_input_source", { clear = true }),
  callback = set_english_input_source,
})
