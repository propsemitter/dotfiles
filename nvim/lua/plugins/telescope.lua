local function browse_project_files()
  require("lazy").load({ plugins = { "telescope.nvim" } })

  local telescope = require("telescope")
  if not telescope.extensions.file_browser then
    telescope.load_extension("file_browser")
  end

  local root = LazyVim.root()
  local function search_project_files(prompt_bufnr)
    local picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
    local query = picker:_get_prompt()
    require("telescope.actions").close(prompt_bufnr)
    vim.schedule(function()
      require("telescope.builtin").find_files({
        cwd = root,
        default_text = query,
        previewer = false,
        layout_config = {
          height = 0.6,
        },
        attach_mappings = function(_, map)
          local function return_to_browser(bufnr)
            require("telescope.actions").close(bufnr)
            vim.schedule(function()
              browse_project_files()
            end)
          end

          map({ "i", "n" }, "<C-r>", return_to_browser, { desc = "Return to File Browser" })
          return true
        end,
      })
    end)
  end

  telescope.extensions.file_browser.file_browser({
    cwd = root,
    path = root,
    grouped = true,
    select_buffer = true,
    respect_gitignore = true,
    previewer = false,
    layout_config = {
      height = 0.6,
    },
    attach_mappings = function(_, map)
      map({ "i", "n" }, "<C-r>", search_project_files, { desc = "Search All Project Files" })
      return true
    end,
  })
end

return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-telescope/telescope-file-browser.nvim",
    },
    opts = function(_, opts)
      local actions = require("telescope.actions")
      opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, {
        mappings = {
          i = {
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
          },
        },
      })
    end,
  },
  {
    "folke/snacks.nvim",
    init = function()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
    end,
    opts = {
      explorer = {
        replace_netrw = false,
      },
    },
    keys = {
      {
        "<leader><space>",
        browse_project_files,
        desc = "Browse Project Files",
      },
    },
  },
}
