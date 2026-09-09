return {
  {
    "ChmaraX/herdr-nvim",
    tag = "v1.0.0",
    cmd = { "Herdr" },
    keys = {
      { "<leader>rc", "<CMD>Herdr comment<CR>", mode = { "n", "x" }, desc = "Review: comment" },
      { "<leader>rl", "<CMD>Herdr list<CR>", mode = "n", desc = "Review: list comments" },
      { "<leader>rs", "<CMD>Herdr submit<CR>", mode = "n", desc = "Review: submit to agent" },
    },
    opts = {
      keymaps = false,
      clear_after_send = true,
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>r", group = "review / agent threads", icon = "💬", mode = { "n", "x" } },
      },
    },
  },
}
