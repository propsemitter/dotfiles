local M = {}

--- Scan a line for i18n keys.
--- @param line string
--- @return table List of {key, col_start, col_end, key_start, key_end}
function M.scan_line(line)
  local matches = {}
  local start = 1
  while true do
    -- Capture groups:
    -- 1: prefix (t( or $t()
    -- 2: open quote
    -- 3: key
    -- 4: close quote
    -- 5: suffix ())
    local s, e, prefix, q1, key, q2, suffix = line:find("([%$]?t%s*%(%s*)(['\"])([%w%.%-_]+)(['\"])(%s*%))", start)
    if not s then break end

    local key_start = s + #prefix
    local key_end = key_start + #key + 2 -- +2 to include both quotes

    table.insert(matches, {
      key = key,
      col_start = s - 1,
      col_end = e,
      key_start = key_start - 1, -- 0-indexed, points to first quote
      key_end = key_end - 1     -- 0-indexed, points after last quote
    })
    start = e + 1
  end

  return matches
end

return M
