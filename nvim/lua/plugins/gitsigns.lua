return {
  "gitsigns.nvim",
  opts = {
    -- otherwise files created by an agent (not yet `git add`-ed) are invisible to gitsigns
    attach_to_untracked = true,
  },
  keys = {
    {
      "<leader>ghn",
      function()
        local gs = require("gitsigns")
        gs.stage_hunk()
        vim.schedule(function()
          gs.nav_hunk("next")
        end)
      end,
      desc = "Stage Hunk & Next",
    },
  },
}
