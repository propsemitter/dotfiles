return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      hidden = true,
      sources = {
        explorer = {
          hidden = true,
        },
        files = {
          hidden = true,
        },
      },
    },
  },
  keys = {
    { "<leader>gd", false },
    { "<leader>gD", false },
  },
}
