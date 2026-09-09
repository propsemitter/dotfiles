return {
  {
    "neovim/nvim-lspconfig",
    init = function()
      require("config.vue-hover").setup()
    end,
  },
}
