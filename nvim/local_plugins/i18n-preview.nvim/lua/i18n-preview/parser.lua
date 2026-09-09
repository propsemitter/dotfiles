local M = {}

--- Flatten a nested table into a single-level table with dot-separated keys.
--- @param tbl table The nested table to flatten.
--- @param prefix string? Optional prefix for keys.
--- @param result table? The table to store results in.
--- @return table
function M.flatten(tbl, prefix, result)
  result = result or {}
  prefix = prefix or ""

  for k, v in pairs(tbl) do
    local key = prefix == "" and k or prefix .. "." .. k
    if type(v) == "table" then
      M.flatten(v, key, result)
    else
      result[key] = tostring(v)
    end
  end
  return result
end

--- Load and flatten a JSON file.
--- @param path string The path to the JSON file.
--- @return table|nil The flattened table or nil if loading failed.
function M.load_locales(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end

  local content = file:read("*a")
  file:close()

  local ok, data = pcall(vim.json.decode, content)
  if not ok then
    return nil
  end

  return M.flatten(data)
end

return M
