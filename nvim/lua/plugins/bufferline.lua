return {
  {
    "akinsho/bufferline.nvim",
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.custom_filter = function(buf_number)
        local ft = vim.bo[buf_number].filetype
        local name = vim.api.nvim_buf_get_name(buf_number)
        if ft == "antigravity" or name:find("term://") or name:find("agy") then
          return false
        end
        return true
      end
    end,
  },
}
