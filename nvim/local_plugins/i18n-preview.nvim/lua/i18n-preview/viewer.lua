local M = {}

M.ns_id = vim.api.nvim_create_namespace("i18n_preview")

--- Clear all i18n previews in a buffer.
--- @param bufnr number
function M.clear(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, M.ns_id, 0, -1)
end

--- Render a preview for an i18n key.
--- @param bufnr number
--- @param line_idx number 0-indexed
--- @param start_col number 0-indexed
--- @param end_col number 0-indexed
--- @param text string The translation text
function M.render(bufnr, line_idx, start_col, end_col, text)
  -- Use UTF-8 safe truncation (vim.fn.strcharpart)
  -- Russian characters are 2 bytes, string.sub would break them.
  local max_chars = 200 -- Increased to show more text
  if vim.fn.strchars(text) > max_chars then
    text = vim.fn.strcharpart(text, 0, max_chars) .. "..."
  end

  -- Use virt_text_pos = "inline" with concealment of the original key
  -- Note: This requires conceallevel >= 2
  vim.api.nvim_buf_set_extmark(bufnr, M.ns_id, line_idx, start_col, {
    end_col = end_col,
    conceal = "", -- Hide the original key
    virt_text = { { text, "Comment" } },
    virt_text_pos = "inline",
  })
end

return M
