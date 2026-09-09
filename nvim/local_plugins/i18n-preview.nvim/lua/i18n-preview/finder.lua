local M = {}

--- Find the line number of a nested key in a JSON file.
--- @param filepath string
--- @param key string (e.g., "index.hero.title")
--- @return number|nil
function M.find_line_in_json(filepath, key)
  local file = io.open(filepath, "r")
  if not file then return nil end

  local parts = vim.split(key, "%.")
  local current_part_idx = 1
  local line_num = 0

  -- This is a simple heuristic: it looks for the parts in order.
  -- It works for standard formatted JSON.
  for line in file:lines() do
    line_num = line_num + 1
    local part = parts[current_part_idx]

    -- Look for "part": pattern
    if line:find('"' .. part .. '"%s*:') then
      if current_part_idx == #parts then
        file:close()
        return line_num
      end
      current_part_idx = current_part_idx + 1
    end
  end

  file:close()
  return nil
end

--- Get all definition locations for a key.
--- @param key string
--- @param locale_dir string
--- @return table List of {filename, lnum, col, text}
function M.get_definitions(key, locale_dir)
  local results = {}
  local files = vim.fn.glob(locale_dir .. "/*.json", false, true)

  for _, file in ipairs(files) do
    local lnum = M.find_line_in_json(file, key)
    if lnum then
      table.insert(results, {
        filename = file,
        lnum = lnum,
        col = 1,
        text = vim.fn.fnamemodify(file, ":t") .. " [" .. key .. "]"
      })
    end
  end

  return results
end

return M
