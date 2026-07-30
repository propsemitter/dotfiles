return {
  {
    "NakLast/antigravity-cli.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    event = "VeryLazy",
    opts = {
      cmd = "agy",
      style = "float",
      width_ratio = 0.85,
      height_ratio = 0.85,
      border = "rounded",
    },
    config = function(_, opts)
      require("antigravity").setup(opts)
      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "*",
        callback = function(ev)
          local name = vim.api.nvim_buf_get_name(ev.buf)
          if name:find("agy") or name:find("antigravity") then
            vim.bo[ev.buf].buflisted = false
          end
        end,
      })
    end,

    keys = {
      { "<leader>ag", "<cmd>lua require('antigravity').toggle()<cr>", desc = "Toggle Antigravity Float" },
      { "<c-g>", "<cmd>lua require('antigravity').toggle()<cr>", mode = { "n", "t" }, desc = "Toggle Antigravity Terminal" },
      { "<leader>as", "<cmd>lua require('antigravity').ask_selection()<cr>", mode = { "n", "v" }, desc = "Send selection to Antigravity" },
    },




  },
}
