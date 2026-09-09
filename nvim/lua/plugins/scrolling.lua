return {
  {
    "karb94/neoscroll.nvim",
    config = function()
      require("neoscroll").setup({
        time_step = 1,
        fps = 120,
        easing_function = "quadratic",
        hide_cursor = true,
        stop_eof = true,
        performance_mode = false,
        duration_multiplier = 0.5,
        pre_hook = function()
          vim.opt.eventignore:add("WinScrolled")
        end,
        post_hook = function()
          vim.opt.eventignore:remove("WinScrolled")
        end,
      })
    end,
  },
}
