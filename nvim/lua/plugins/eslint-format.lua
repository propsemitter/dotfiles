return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.eslint = vim.tbl_deep_extend("force", opts.servers.eslint or {}, {
        settings = {
          workingDirectories = { mode = "auto" },
          format = true,
        },
      })

      opts.setup = opts.setup or {}
      opts.setup.eslint = function()
        LazyVim.format.register(LazyVim.lsp.formatter({
          name = "eslint: lsp",
          primary = true,
          priority = 300,
          filter = "eslint",
        }))
      end
    end,
  },
}
