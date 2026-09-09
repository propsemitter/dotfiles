return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      tailwindcss = {
        settings = {
          tailwindCSS = {
            classAttributes = {
              "class",
              "className",
              "class:list",
              "classList",
              "ngClass",
            },
            experimental = {
              classRegex = {
                { "tv\\(([^)]*)\\)",      "[\"'`]([^\"'`]*).*?[\"'`]" },
                { "cva\\(([^)]*)\\)",     "[\"'`]([^\"'`]*).*?[\"'`]" },
                { "cn\\(([^)]*)\\)",      "[\"'`]([^\"'`]*).*?[\"'`]" },
                { "clsx\\(([^)]*)\\)",    "[\"'`]([^\"'`]*).*?[\"'`]" },
                { "twMerge\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
                { "twJoin\\(([^)]*)\\)",  "[\"'`]([^\"'`]*).*?[\"'`]" },
              },
            },
          },
        },
      },
    },
  },
}
