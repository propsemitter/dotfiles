local parser = require("i18n-preview.parser")
local scanner = require("i18n-preview.scanner")
local viewer = require("i18n-preview.viewer")
local finder = require("i18n-preview.finder")

local M = {}

M.config = {
  locale_path = "i18n/locales/ru.json",
  locale_dir = "i18n/locales",
  enabled = true,
}

M.locales = {}

-- Helper to check if cursor is on i18n key and jump
local function try_i18n_jump()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local matches = scanner.scan_line(line)
  for _, m in ipairs(matches) do
    if col >= m.col_start and col <= m.col_end then
      M.go_to_definition()
      return true
    end
  end
  return false
end

--- Setup the plugin with user options.
--- @param opts table?
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Load locales
  M.refresh_locales()

  -- Autocommands to refresh buffer previews
  local group = vim.api.nvim_create_augroup("i18n_preview", { clear = true })

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave", "TextChanged", "CursorMoved" }, {
    group = group,
    pattern = { "*.vue", "*.js", "*.ts" },
    callback = function(args)
      if M.config.enabled then
        M.refresh_buffer(args.buf)
      end
    end,
  })

  -- Ensure conceallevel is set for the buffer
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = { "vue", "javascript", "typescript" },
    callback = function()
      if vim.wo.conceallevel < 2 then
        vim.wo.conceallevel = 2
      end
    end,
  })

  -- Patch Snacks immediately
  local ok_snacks, snacks = pcall(require, "snacks")
  if ok_snacks and snacks.picker then
    local original_snacks_def = snacks.picker.lsp_definitions
    snacks.picker.lsp_definitions = function(...)
      if not try_i18n_jump() then
        return original_snacks_def(...)
      end
    end
  end

  -- Patch standard vim.lsp.buf.definition
  local original_lsp_def = vim.lsp.buf.definition
  vim.lsp.buf.definition = function(...)
    if not try_i18n_jump() then
      return original_lsp_def(...)
    end
  end

  -- Create user commands
  vim.api.nvim_create_user_command("I18nPreviewToggle", function()
    M.toggle()
  end, {})

  vim.api.nvim_create_user_command("I18nPreviewRefresh", function()
    M.refresh_locales()
    M.refresh_buffer()
  end, {})

  vim.api.nvim_create_user_command("I18nPreviewLanguage", function(cargs)
    local lang = cargs.args
    if lang == "ru" then
      M.config.locale_path = "i18n/locales/ru.json"
    elseif lang == "en" then
      M.config.locale_path = "i18n/locales/en.json"
    else
      print("i18n-preview: Unsupported language: " .. lang)
      return
    end
    M.refresh_locales()
    M.refresh_buffer()
    print("i18n-preview: Switched to " .. lang)
  end, {
    nargs = 1,
    complete = function() return { "en", "ru" } end
  })

  vim.api.nvim_create_user_command("I18nPreviewDefinition", function()
    M.go_to_definition()
  end, {})
end

--- Tagfunc for integration with standard gd and CTRL-]
function M.tagfunc(pattern, flags)
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local matches = scanner.scan_line(line)
  local found_key = nil

  for _, m in ipairs(matches) do
    if col >= m.col_start and col <= m.col_end then
      found_key = m.key
      break
    end
  end

  if not found_key then
    return vim.NIL -- Let LSP handle it
  end

  local root = vim.fn.getcwd()
  local locale_dir = root .. "/" .. M.config.locale_dir
  local defs = finder.get_definitions(found_key, locale_dir)

  local tags = {}
  for _, def in ipairs(defs) do
    table.insert(tags, {
      name = found_key,
      filename = def.filename,
      cmd = tostring(def.lnum), -- Line number to jump to
      kind = "v" -- Variable/Value
    })
  end

  return tags
end

--- Go to the definition of the i18n key under the cursor.
function M.go_to_definition()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local matches = scanner.scan_line(line)
  local found_key = nil

  for _, m in ipairs(matches) do
    if col >= m.col_start and col <= m.col_end then
      found_key = m.key
      break
    end
  end

  if not found_key then
    print("i18n-preview: No key under cursor")
    return
  end

  local root = vim.fn.getcwd()
  local locale_dir = root .. "/" .. M.config.locale_dir
  local defs = finder.get_definitions(found_key, locale_dir)

  if #defs == 0 then
    print("i18n-preview: Key not found in locale files")
  else
    -- Use Snacks.picker if available for a nice UI with preview
    local ok_snacks, snacks = pcall(require, "snacks")
    if ok_snacks and snacks.picker then
      local items = {}
      for _, def in ipairs(defs) do
        table.insert(items, {
          file = def.filename,
          pos = { def.lnum, 0 },
          text = def.text,
        })
      end

      snacks.picker.pick({
        source = "i18n_definitions",
        items = items,
        layout = "default", -- Horizontal layout with preview on the right
        format = "file",
        title = "i18n Definitions: " .. found_key,
        confirm = function(picker, item)
          picker:close()
          vim.api.nvim_command("edit " .. item.file)
          vim.api.nvim_win_set_cursor(0, item.pos)
        end,
      })
    else
      -- Fallback to standard ui.select or edit directly if one
      if #defs == 1 then
        vim.api.nvim_command("edit " .. defs[1].filename)
        vim.api.nvim_win_set_cursor(0, { defs[1].lnum, 0 })
      else
        vim.ui.select(defs, {
          prompt = "Select locale file:",
          format_item = function(item)
            return item.text
          end,
        }, function(choice)
          if choice then
            vim.api.nvim_command("edit " .. choice.filename)
            vim.api.nvim_win_set_cursor(0, { choice.lnum, 0 })
          end
        end)
      end
    end
  end
end

--- Reload the locales from the JSON file.
function M.refresh_locales()
  local root = vim.fn.getcwd()
  -- Skip if already loaded for this root
  if next(M.locales) ~= nil and M.last_root == root then
    return
  end

  local full_path = root .. "/" .. M.config.locale_path
  local data = parser.load_locales(full_path)
  if data then
    M.locales = data
    M.last_root = root
  end
end

--- Update previews in a specific buffer.
--- @param bufnr number?
function M.refresh_buffer(bufnr)
  bufnr = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
  if not vim.api.nvim_buf_is_valid(bufnr) then return end

  M.refresh_locales()
  viewer.clear(bufnr)

  if not M.config.enabled then return end

  local cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, line in ipairs(lines) do
    -- Skip the current line where the cursor is (to reveal the key while editing)
    if i - 1 ~= cursor_line then
      local matches = scanner.scan_line(line)
      for _, match in ipairs(matches) do
        local translation = M.locales[match.key]
        if translation then
          viewer.render(bufnr, i - 1, match.key_start, match.key_end, translation)
        end
      end
    end
  end
end

--- Toggle the preview visibility.
function M.toggle()
  M.config.enabled = not M.config.enabled
  if M.config.enabled then
    M.refresh_buffer()
    print("i18n-preview: Enabled")
  else
    viewer.clear(0)
    print("i18n-preview: Disabled")
  end
end

return M
