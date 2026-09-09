-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

local function make_transparent()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local win_ft = vim.bo[buf].filetype
    if win_ft == "snacks_picker_list" or win_ft == "snacks_picker_input" or win_ft == "snacks_picker_preview" then
      vim.api.nvim_set_option_value(
        "winhighlight",
        "Normal:NONE,NormalNC:NONE,NormalFloat:NONE,FloatBorder:NONE",
        { win = win }
      )
    end
  end
end

vim.api.nvim_create_autocmd({ "WinEnter", "WinNew" }, {
  callback = function()
    vim.schedule(make_transparent)
  end,
})

vim.opt.mouse = "a"
