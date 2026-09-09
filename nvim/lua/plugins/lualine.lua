return {
  {
    "nvim-mini/mini.icons",
    opts = { style = "glyph" },
  },

  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      opts.options.theme = {
        normal = {
          a = { fg = "#101114", bg = "#89A9C9", gui = "bold" },
          b = { fg = "#C5CBD5", bg = "#252A33" },
          c = { fg = "#B4BFCE", bg = "#171A20" },
        },
        insert = {
          a = { fg = "#101114", bg = "#9ECB8B", gui = "bold" },
          b = { fg = "#C5CBD5", bg = "#252A33" },
          c = { fg = "#B4BFCE", bg = "#171A20" },
        },
        visual = {
          a = { fg = "#101114", bg = "#89A9C9", gui = "bold" },
          b = { fg = "#C5CBD5", bg = "#252A33" },
          c = { fg = "#B4BFCE", bg = "#171A20" },
        },
        replace = {
          a = { fg = "#101114", bg = "#E58A93", gui = "bold" },
          b = { fg = "#C5CBD5", bg = "#252A33" },
          c = { fg = "#B4BFCE", bg = "#171A20" },
        },
        command = {
          a = { fg = "#101114", bg = "#A9C4E4", gui = "bold" },
          b = { fg = "#C5CBD5", bg = "#252A33" },
          c = { fg = "#B4BFCE", bg = "#171A20" },
        },
        inactive = {
          a = { fg = "#8993A3", bg = "#171A20" },
          b = { fg = "#8993A3", bg = "#171A20" },
          c = { fg = "#697486", bg = "#111318" },
        },
      }
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
}
