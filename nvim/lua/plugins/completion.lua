return {
  "saghen/blink.cmp",
  opts = {
    keymap = {
      preset = "default",

      ["<C-k>"] = { "select_prev", "fallback" },
      ["<C-j>"] = { "select_next", "fallback" },

      ["<CR>"] = { "accept", "fallback" },

      ["<Tab>"] = {
        function(cmp)
          -- Исправленные названия функций:
          if cmp.is_visible() then
            return cmp.accept()
          elseif cmp.snippet_active() then
            return cmp.snippet_forward()
          end
        end,
        "fallback",
      },

      ["<S-Tab>"] = { "select_prev", "fallback" },
    },

    -- Добавляем это, чтобы он не искал luasnip и не выдавал ошибку
    snippets = {
      preset = "default",
    },
  },
}
