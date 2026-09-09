return {
  "sindrets/diffview.nvim",
  cmd = {
    "DiffviewOpen",
    "DiffviewClose",
    "DiffviewToggleFiles",
    "DiffviewFocusFiles",
    "DiffviewFileHistory",
  },
  opts = {
    enhanced_diff_hl = true,
    use_icons = true,
    signs = {
      fold_closed = "",
      fold_open = "",
      done = "✓",
    },
    view = {
      default = {
        layout = "diff2_horizontal",
        winbar_info = true,
      },
      file_history = {
        layout = "diff2_horizontal",
        winbar_info = true,
      },
    },
    file_panel = {
      -- Древовидная структура с иерархией папок
      listing_style = "tree",
      tree_options = {
        flatten_dirs = true,
        folder_statuses = "only_folded",
      },
      win_config = {
        position = "left",
        width = 34,
        win_opts = {
          number = false,
          relativenumber = false,
          cursorline = true,
          signcolumn = "yes",
          winfixwidth = true,
        },
      },
    },
    hooks = {
      diff_buf_win_enter = function(_, winid, _)
        vim.wo[winid].relativenumber = false
        vim.wo[winid].cursorline = true
        vim.wo[winid].wrap = false
        vim.wo[winid].foldenable = false
        vim.wo[winid].signcolumn = "yes"
      end,
    },
  },
}
