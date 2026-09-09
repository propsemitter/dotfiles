return {
  {
    "neovim/nvim-lspconfig",
    opts = function()
      local ns = vim.api.nvim_create_namespace("tailwind_syntax")

      local function setup_hl()
        local hls = {
          TailwindVariant = { fg = "#7dd3fc" }, -- Sky 300 (Soft Blue)
          TailwindBracket = { fg = "#94a3b8" }, -- Slate 400
          TailwindImportant = { fg = "#fda4af" }, -- Rose 300 (Soft Red)
          TailwindProperty = { fg = "#f9a8d4" }, -- Pink 300
          TailwindValue = { fg = "#fcd34d" }, -- Amber 300
          TailwindSelector = { fg = "#5eead4" }, -- Teal 300
          TailwindUtility = { fg = "#a5b4fc" }, -- Indigo 300 (Soft Purple/Blue)
          TailwindColorGroup = { fg = "#d8b4fe" }, -- Purple 300 (Soft Purple)
          TailwindSizeGroup = { fg = "#fef08a" }, -- Yellow 200 (Soft Yellow)
          TailwindLayoutGroup = { fg = "#86efac" }, -- Green 300 (Soft Green)
        }
        for name, opts in pairs(hls) do
          vim.api.nvim_set_hl(0, name, opts)
        end
      end

      -- Initialize highlights
      setup_hl()
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = setup_hl,
      })

      local function highlight_class(buf, row, abs_start, class)
        local i = 1
        local last_pos = 1
        local in_brackets = 0
        local in_parens = 0

        while i <= #class do
          local char = class:sub(i, i)

          if char == "[" then
            in_brackets = in_brackets + 1
            vim.api.nvim_buf_set_extmark(buf, ns, row, abs_start + i - 1, {
              end_col = abs_start + i, hl_group = "TailwindBracket", ephemeral = true, priority = 250,
            })
          elseif char == "]" then
            in_brackets = in_brackets - 1
            vim.api.nvim_buf_set_extmark(buf, ns, row, abs_start + i - 1, {
              end_col = abs_start + i, hl_group = "TailwindBracket", ephemeral = true, priority = 250,
            })
          elseif char == "(" then
            in_parens = in_parens + 1
          elseif char == ")" then
            in_parens = in_parens - 1
          elseif char == ":" and in_brackets == 0 and in_parens == 0 then
            vim.api.nvim_buf_set_extmark(buf, ns, row, abs_start + last_pos - 1, {
              end_col = abs_start + i, hl_group = "TailwindVariant", ephemeral = true, priority = 250,
            })
            last_pos = i + 1
          elseif char == "!" and in_brackets == 0 then
            vim.api.nvim_buf_set_extmark(buf, ns, row, abs_start + i - 1, {
              end_col = abs_start + i, hl_group = "TailwindImportant", ephemeral = true, priority = 260,
            })
          elseif in_brackets > 0 then
            local group = "TailwindValue"
            if class:sub(last_pos, last_pos) == "&" then group = "TailwindSelector" end
            local has_colon = class:find(":", last_pos, true)
            if has_colon and (abs_start + i - 1) < (abs_start + last_pos - 1 + has_colon - 1) then
              group = "TailwindProperty"
            end
            vim.api.nvim_buf_set_extmark(buf, ns, row, abs_start + i - 1, {
              end_col = abs_start + i, hl_group = group, ephemeral = true, priority = 250,
            })
          end
          i = i + 1
        end

        if last_pos <= #class then
          local base_util = class:sub(last_pos)
          if base_util:sub(-1) == "!" then base_util = base_util:sub(1, -2) end

          local hl_group = "TailwindUtility"

          local color_patterns = {"^bg%-", "^text%-", "^border", "^ring", "^fill", "^stroke", "^shadow", "^from%-", "^via%-", "^to%-", "^outline", "^decoration%-", "^accent%-", "^caret%-", "^divide%-"}
          local size_patterns = {"^w%-", "^h%-", "^p[xytrbl]?%-", "^m[xytrbl]?%-", "^gap%-", "^size%-", "^max%-", "^min%-", "^basis%-", "^tracking%-", "^leading%-", "^indent%-"}
          local layout_patterns = {"^flex", "^grid", "^col%-", "^row%-", "^items%-", "^justify%-", "^place%-", "^absolute", "^relative", "^fixed", "^sticky", "^block", "^inline", "^hidden", "^z%-", "^inset%-", "^top%-", "^bottom%-", "^left%-", "^right%-", "^order%-", "^float%-", "^clear%-", "^overflow%-", "^visible", "^invisible"}

          for _, p in ipairs(color_patterns) do if base_util:match(p) then hl_group = "TailwindColorGroup" break end end
          if hl_group == "TailwindUtility" then
            for _, p in ipairs(size_patterns) do if base_util:match(p) then hl_group = "TailwindSizeGroup" break end end
          end
          if hl_group == "TailwindUtility" then
            for _, p in ipairs(layout_patterns) do if base_util:match(p) then hl_group = "TailwindLayoutGroup" break end end
          end

          vim.api.nvim_buf_set_extmark(buf, ns, row, abs_start + last_pos - 1, {
            end_col = abs_start + #class, hl_group = hl_group, ephemeral = true, priority = 200,
          })
        end
      end

      local buf_cache = {}

      local function update_cache(buf)
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local content = table.concat(lines, "\n")
        local ranges = {}

        local function get_pos(idx)
          local curr = 1
          for r, line in ipairs(lines) do
            if curr + #line >= idx then return r - 1, idx - curr end
            curr = curr + #line + 1
          end
          return #lines - 1, #lines[#lines]
        end

        local patterns = {
          'class%s*=%s*(["\'])(.-)%1', 'className%s*=%s*(["\'])(.-)%1', 'class:list%s*=%s*{.-(["\'])(.-)%1.-}',
        }

        local ft = vim.bo[buf].filetype
        if ft == "css" or ft == "scss" then table.insert(patterns, "@apply%s+(.-);") end

        for _, p in ipairs(patterns) do
          local s = 1
          while true do
            local start_idx, end_idx, c1, c2 = content:find(p, s)
            if not start_idx then break end
            local inner_content = c2 or c1
            local content_start = content:find(inner_content, start_idx, true)
            local start_row, start_col = get_pos(content_start)
            local end_row, end_col = get_pos(content_start + #inner_content)
            table.insert(ranges, { start_row = start_row, start_col = start_col, end_row = end_row, end_col = end_col, content = inner_content })
            s = end_idx + 1
          end
        end

        local function find_function_blocks(text, func_name)
          local blocks = {}
          local s = 1
          while true do
            local start_idx = text:find("%f[%w_]" .. func_name .. "%s*%(", s)
            if not start_idx then break end

            local i = start_idx + #func_name
            while i <= #text and text:sub(i, i) ~= "(" do i = i + 1 end

            local p_depth = 0
            local in_string = false
            local string_char = nil
            local block_start = i
            local block_end = nil

            while i <= #text do
              local c = text:sub(i, i)
              local prev_c = i > 1 and text:sub(i-1, i-1) or ""

              if in_string then
                if c == string_char and prev_c ~= "\\" then in_string = false end
              else
                if c == '"' or c == "'" or c == "`" then
                  in_string = true
                  string_char = c
                elseif c == "(" then p_depth = p_depth + 1
                elseif c == ")" then
                  p_depth = p_depth - 1
                  if p_depth == 0 then block_end = i; break end
                end
              end
              i = i + 1
            end

            if block_end then
              table.insert(blocks, {start_idx = block_start, end_idx = block_end})
              s = block_end + 1
            else
              s = start_idx + #func_name
            end
          end
          return blocks
        end

        local func_names = {"cn", "cva", "tv", "clsx", "twMerge", "twJoin"}
        for _, fname in ipairs(func_names) do
          local blocks = find_function_blocks(content, fname)
          for _, block in ipairs(blocks) do
            local block_str = content:sub(block.start_idx, block.end_idx)
            local s = 1
            while true do
              local start_idx, end_idx, quote, inner = block_str:find('(["\'`])(.-)%1', s)
              if not start_idx then break end

              if #inner > 0 then
                 local content_start = block.start_idx + start_idx - 1 + #quote
                 local start_row, start_col = get_pos(content_start)
                 local end_row, end_col = get_pos(content_start + #inner)

                 table.insert(ranges, {
                   start_row = start_row, start_col = start_col, end_row = end_row, end_col = end_col, content = inner
                 })
              end
              s = end_idx + 1
            end
          end
        end

        buf_cache[buf] = ranges
      end

      vim.api.nvim_set_decoration_provider(ns, {
        on_win = function(_, _, buf, _)
          local ft = vim.bo[buf].filetype
          local supported = {
            html = true, javascriptreact = true, typescriptreact = true, javascript = true, typescript = true,
            vue = true, svelte = true, astro = true, php = true,
            css = true, scss = true, heex = true, elixir = true,
          }
          if supported[ft] then
            update_cache(buf)
            return true
          end
          return false
        end,
        on_line = function(_, _, buf, row)
          local ranges = buf_cache[buf]
          if not ranges then return end

          for _, range in ipairs(ranges) do
            if row >= range.start_row and row <= range.end_row then
              local line_content = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
              if not line_content then return end

              local col_start = (row == range.start_row) and range.start_col or 0
              local col_end = (row == range.end_row) and range.end_col or #line_content

              local text = line_content:sub(col_start + 1, col_end)

              local cs = 1
              while true do
                local c_start, c_end = text:find("[%S]+", cs)
                if not c_start then break end
                highlight_class(buf, row, col_start + c_start - 1, text:sub(c_start, c_end))
                cs = c_end + 1
              end
            end
          end
        end,
      })
    end,
  },
}
