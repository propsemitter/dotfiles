return {
  "NeogitOrg/neogit",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  cmd = "Neogit",
  keys = {
    { "<leader>gn", "<cmd>Neogit<cr>", desc = "Neogit: Status" },
  },
  opts = {
    kind = "split",
    graph_style = "unicode",
    highlight = {
      italic = false,
    },
    integrations = {
      diffview = true,
    },
  },
}
