-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_autocmd("BufNewFile", {
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

-- Optional macOS helper; without it (or on another platform) this is a no-op.
local function set_english_input_source()
  if vim.fn.has("mac") ~= 1 then
    return
  end

  local macism = vim.fn.exepath("macism")
  if macism ~= "" then
    vim.fn.jobstart({ macism, "com.apple.keylayout.ABC", "0" }, { detach = true })
    return
  end

  local im_select = vim.fn.exepath("im-select")
  if im_select ~= "" then
    vim.fn.jobstart({ im_select, "com.apple.keylayout.ABC" }, { detach = true })
  end
end

vim.api.nvim_create_autocmd({
  "VimEnter",
  "FocusGained",
  "BufEnter",
  "WinEnter",
  "InsertLeave",
  "CmdlineLeave",
}, {
  group = vim.api.nvim_create_augroup("english_input_source", { clear = true }),
  callback = set_english_input_source,
})
