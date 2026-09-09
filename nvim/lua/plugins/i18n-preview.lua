return {
  {
    "i18n-preview",
    dir = vim.fn.expand("~/.config/nvim/local_plugins/i18n-preview.nvim"),
    opts = {
      locale_path = "i18n/locales/ru.json",
    },
    config = function(_, opts)
      require("i18n-preview").setup(opts)
    end,
    ft = { "vue", "javascript", "typescript" },
  },
}
