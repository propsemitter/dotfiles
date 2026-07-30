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
    keys = {
      { "<leader>ag", "<cmd>lua require('antigravity').toggle()<cr>", desc = "Toggle Antigravity Float" },
      { "<leader>as", "<cmd>lua require('antigravity').ask_selection()<cr>", mode = { "n", "v" }, desc = "Send selection to Antigravity" },
    },



  },
}
