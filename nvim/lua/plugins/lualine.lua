return {
  -- 1. Тема Catppuccin
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = false,
      no_italic = true,
      color_overrides = {
        mocha = {
          base = "#111111",
          mantle = "#0D0D0D",
          crust = "#090909",
          surface0 = "#1A1A1A",
          surface1 = "#222222",
          overlay0 = "#666666",
          text = "#E8E8E8",
          subtext0 = "#B8B8B8",
          peach = "#FF9F43",
          yellow = "#FFB454",
        },
      },
      integrations = {
        lualine = true,
        snacks = true,
        mini_icons = true,
        native_lsp = { enabled = true },
        telescope = { enabled = true },
      },
      custom_highlights = function(colors)
        return {
          -- ОСТАВЛЯЕМ фон для подсказок и меню
          Pmenu = { bg = colors.crust },
          PmenuSel = { bg = colors.surface0, fg = colors.peach },
          NormalFloat = { bg = colors.crust },
          FloatBorder = { fg = colors.surface0, bg = colors.crust },
        }
      end,
    },
  },

  -- 2. Иконки
  {
    "nvim-mini/mini.icons",
    opts = { style = "glyph" },
  },

  -- 3. Статус-бар (Круглые пилюли)
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      opts.options.theme = "auto"
      opts.options.component_separators = ""
      opts.options.section_separators = ""

      local function bubble(component)
        component.separator = { left = "", right = "" }
        component.padding = { left = 0, right = 0 }
        return component
      end

      opts.sections = {
        lualine_a = { bubble({ "mode" }) },
        lualine_b = { bubble({ "filename", file_status = true, path = 1 }) },
        lualine_c = { bubble({ "branch", icon = "" }), { "diagnostics", padding = { left = 2, right = 1 } } },
        lualine_x = { { "diff", padding = { left = 1, right = 2 } } },
        lualine_y = { bubble({ "progress" }), bubble({ "location" }) },
        lualine_z = { bubble({ function() return os.date("%R") end, icon = " " }) },
      }
      return opts
    end,
  },

  -- 4. LazyVim Colorscheme
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "catppuccin" },
  },
}
