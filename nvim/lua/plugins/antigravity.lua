return {
  {
    "NakLast/antigravity-cli.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    event = "VeryLazy",
    opts = {
      command = "agy",
    },
    keys = {
      { "<leader>ag", "<cmd>AntigravityToggle<cr>", desc = "Toggle Antigravity" },
      { "<leader>ac", "<cmd>AntigravityConnect<cr>", desc = "Antigravity Connect" },
    },


  },
}
