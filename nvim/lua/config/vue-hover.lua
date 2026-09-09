local M = {}

local COMPONENT_HOVER_FOCUS_ID = "vue-component-hover"
local COMPONENT_TAGS = {
  ["component"] = true,
  ["keep-alive"] = true,
  ["slot"] = true,
  ["suspense"] = true,
  ["teleport"] = true,
  ["template"] = true,
  ["transition"] = true,
  ["transition-group"] = true,
}

local function trim(value)
  return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function clean_signature(value)
  value = trim(value):gsub("\n%s*", " "):gsub("%s+", " ")
  return trim(value:gsub(";$", ""))
end

local function node_text(node, source)
  return vim.treesitter.get_node_text(node, source)
end

local function first_named_child(node)
  for child in node:iter_children() do
    if child:named() then
      return child
    end
  end
end
local function child_of_type(node, type)
  for child in node:iter_children() do
    if child:named() and child:type() == type then
      return child
    end
  end
end


local function field_node(node, field)
  local nodes = node:field(field)
  return nodes and nodes[1]
end

local function walk(node, callback)
  if callback(node) then
    return true
  end

  for child in node:iter_children() do
    if child:named() and walk(child, callback) then
      return true
    end
  end

  return false
end


local function script_from_vue_buffer(bufnr)
  local parser = vim.treesitter.get_parser(bufnr, "vue")
  local root = parser:parse()[1]:root()
  local scripts = {}

  for child in root:iter_children() do
    if child:named() and child:type() == "script_element" then
      local start_tag = child_of_type(child, "start_tag")
      local content = child_of_type(child, "raw_text")

      if content then
        local start_row, start_col = content:range()
        scripts[#scripts + 1] = {
          is_setup = start_tag and node_text(start_tag, bufnr):find("%f[%w]setup%f[%W]") ~= nil or false,
          text = node_text(content, bufnr),
          start_row = start_row,
          start_col = start_col,
        }
      end
    end
  end

  table.sort(scripts, function(a, b)
    return a.is_setup and not b.is_setup
  end)

  return scripts[1]
end

local function source_position(script, row, col)
  if row == 0 then
    return { line = script.start_row, character = script.start_col + col }
  end

  return { line = script.start_row + row, character = col }
end

local function type_node_from_arguments(type_arguments)
  return type_arguments and first_named_child(type_arguments)
end

local function find_macros(root, source)
  local macros = {}

  walk(root, function(node)
    if node:type() ~= "call_expression" then
      return false
    end

    local fn = field_node(node, "function")
    if not fn or fn:type() ~= "identifier" then
      return false
    end

    local name = node_text(fn, source)
    if name ~= "defineProps" and name ~= "defineEmits" and name ~= "defineExpose" then
      return false
    end

    macros[name] = macros[name]
      or {
        call = node,
        type_node = type_node_from_arguments(field_node(node, "type_arguments")),
        arguments = field_node(node, "arguments"),
      }

    return false
  end)

  return macros
end

local function declaration_name(node, source)
  local name = field_node(node, "name")
  return name and node_text(name, source) or nil
end

local function find_type_declaration(root, source, name)
  local declaration
  walk(root, function(node)
    local type = node:type()
    if (type == "interface_declaration" or type == "type_alias_declaration")
      and declaration_name(node, source) == name
    then
      declaration = node
      return true
    end
    return false
  end)
  return declaration
end

local function declaration_type_node(declaration)
  if not declaration then
    return nil
  end

  if declaration:type() == "interface_declaration" then
    return field_node(declaration, "body") or first_named_child(declaration)
  end

  local value = field_node(declaration, "value")
  if value then
    return value
  end

  local children = {}
  for child in declaration:iter_children() do
    if child:named() then
      children[#children + 1] = child
    end
  end
  return children[#children]
end

local function member_lines(type_node, source)
  if not type_node then
    return {}
  end

  local kind = type_node:type()
  if kind == "interface_body" or kind == "object_type" then
    local lines = {}
    for child in type_node:iter_children() do
      if child:named() then
        local child_kind = child:type()
        if child_kind == "property_signature"
          or child_kind == "method_signature"
          or child_kind == "call_signature"
          or child_kind == "construct_signature"
          or child_kind == "index_signature"
        then
          lines[#lines + 1] = clean_signature(node_text(child, source))
        end
      end
    end
    return lines
  end

  if kind == "intersection_type" or kind == "union_type" then
    local lines = {}
    for child in type_node:iter_children() do
      if child:named() then
        vim.list_extend(lines, member_lines(child, source))
      end
    end
    return lines
  end

  return {}
end
local function member_key(member)
  return member:match("^([%w_$:-]+)%??%s*[:(]")
end

local function declaration_member_lines(root, source, declaration, seen)
  if not declaration then
    return {}
  end

  seen = seen or {}
  local name = declaration_name(declaration, source)
  if name and seen[name] then
    return {}
  end
  if name then
    seen[name] = true
  end

  local lines = {}
  local keys = {}
  local function add_lines(new_lines)
    for _, line in ipairs(new_lines) do
      local key = member_key(line)
      if not key or not keys[key] then
        lines[#lines + 1] = line
        if key then
          keys[key] = true
        end
      end
    end
  end

  add_lines(member_lines(declaration_type_node(declaration), source))
  for child in declaration:iter_children() do
    if child:named() and child:type() == "extends_type_clause" then
      walk(child, function(base)
        if base:type() ~= "type_identifier" then
          return false
        end

        local base_declaration = find_type_declaration(root, source, node_text(base, source))
        if base_declaration then
          add_lines(declaration_member_lines(root, source, base_declaration, seen))
        end
        return false
      end)
    end
  end

  return lines
end


local function type_info_from_tree(root, source, type_node)
  if not type_node then
    return nil
  end

  local kind = type_node:type()
  if kind == "type_identifier" or kind == "nested_type_identifier" then
    local name = node_text(type_node, source)
    local declaration = find_type_declaration(root, source, name)
    if declaration then
      local declaration_type = declaration_type_node(declaration)
      return {
        name = name,
        text = clean_signature(node_text(declaration_type or type_node, source)),
        members = declaration_member_lines(root, source, declaration),
      }
    end

    return { name = name, text = name, members = {} }
  end

  return {
    text = clean_signature(node_text(type_node, source)),
    members = member_lines(type_node, source),
  }
end

local function ts_client(bufnr)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if client.name == "vtsls" and client:supports_method("textDocument/definition") then
      return client
    end
  end
end

local function location_target(location)
  if location.targetUri then
    return location.targetUri, location.targetSelectionRange or location.targetRange
  end
  return location.uri, location.range
end

local function get_definition(client, source_path, position, bufnr, callback)
  if not client or source_path == "" then
    callback()
    return
  end

  local finished = false
  local function finish(...)
    if finished then
      return
    end
    finished = true
    callback(...)
  end

  vim.defer_fn(function()
    finish()
  end, 1500)

  client:request(
    "textDocument/definition",
    {
      textDocument = { uri = vim.uri_from_fname(source_path) },
      position = position,
    },
    function(err, result)
      if err or not result then
        finish()
        return
      end

      local location = result[1] or result
      if type(location) ~= "table" then
        finish()
        return
      end

      local uri, range = location_target(location)
      if not uri then
        finish()
        return
      end

      finish(vim.uri_to_fname(uri), range)
    end,
    bufnr
  )
end

local function parse_type_source(bufnr, kind_hint)
  local filetype = vim.bo[bufnr].filetype
  local is_vue = filetype == "vue" or kind_hint == "vue"

  if is_vue then
    local script = script_from_vue_buffer(bufnr)
    if not script then
      return
    end

    local parser = vim.treesitter.get_string_parser(script.text, "typescript")
    local root = parser:parse()[1]:root()
    return {
      root = root,
      source = script.text,
      script = script,
      path = vim.api.nvim_buf_get_name(bufnr),
    }
  end

  local language = filetype == "typescriptreact" and "tsx" or "typescript"
  local parser = vim.treesitter.get_parser(bufnr, language)
  return {
    root = parser:parse()[1]:root(),
    source = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n"),
    path = vim.api.nvim_buf_get_name(bufnr),
  }
end

local function type_info_from_target(target_path, name, range, current_bufnr, callback)
  local target_bufnr = vim.fn.bufadd(target_path)
  vim.fn.bufload(target_bufnr)
  if target_path:match("%.vue$") then
    vim.bo[target_bufnr].filetype = "vue"
  elseif target_path:match("%.tsx?$") then
    vim.bo[target_bufnr].filetype = target_path:match("%.tsx$") and "typescriptreact" or "typescript"
  end

  local parsed = parse_type_source(target_bufnr, target_path:match("%.vue$") and "vue")
  if not parsed then
    callback()
    return
  end

  local declaration = find_type_declaration(parsed.root, parsed.source, name)
  if not declaration and range then
    local row = range.start.line
    local col = range.start.character
    local node = parsed.root:named_descendant_for_range(row, col, row, col)
    while node and node:type() ~= "interface_declaration" and node:type() ~= "type_alias_declaration" do
      node = node:parent()
    end
    declaration = node
  end

  if declaration then
    local type = declaration_type_node(declaration)
    callback({
      name = name,
      text = clean_signature(node_text(type or declaration, parsed.source)),
      members = declaration_member_lines(parsed.root, parsed.source, declaration),
    })
  else
    callback({ name = name, text = name, members = {} })
  end
end
local function parse_source_path(path, filetype)
  if vim.fn.filereadable(path) ~= 1 then
    return
  end
  local source = table.concat(vim.fn.readfile(path), "\n")
  local language = filetype or (path:match("%.tsx$") and "tsx" or "typescript")
  local parser = vim.treesitter.get_string_parser(source, language)
  return {
    root = parser:parse()[1]:root(),
    source = source,
    path = path,
  }
end

local function project_root(client, bufnr)
  return client.config.root_dir
    or vim.fs.root(bufnr, { "package.json", "components.d.ts" })
    or vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":h")
end

local function global_components_path(root)
  for _, path in ipairs({
    root .. "/components.d.ts",
    root .. "/.nuxt/components.d.ts",
  }) do
    if vim.fn.filereadable(path) == 1 then
      return path
    end
  end
end

local function quoted_value(value)
  value = trim(value)
  return value:sub(2, -2)
end

local function global_component_import(map_path, component_name)
  local parsed = parse_source_path(map_path, "typescript")
  if not parsed then
    return
  end

  local global_components = find_type_declaration(parsed.root, parsed.source, "GlobalComponents")
  local body = declaration_type_node(global_components)
  if not body then
    return
  end

  for child in body:iter_children() do
    if child:named() and child:type() == "property_signature" then
      local name = field_node(child, "name") or first_named_child(child)
      if name and node_text(name, parsed.source) == component_name then
        local strings = {}
        walk(child, function(node)
          if node:type() == "string" then
            strings[#strings + 1] = quoted_value(node_text(node, parsed.source))
          end
          return false
        end)
        if strings[1] and strings[2] then
          return strings[1], strings[2]
        end
      end
    end
  end
end

local function package_entry(root, module_name)
  local dir = root
  while dir and dir ~= "" do
    local package_json = dir .. "/node_modules/" .. module_name .. "/package.json"
    if vim.fn.filereadable(package_json) == 1 then
      local ok, package = pcall(vim.json.decode, table.concat(vim.fn.readfile(package_json), "\n"))
      if not ok or type(package) ~= "table" then
        return
      end

      local entry = package.types or package.typings
      local exports = package.exports and package.exports["."]
      if not entry and type(exports) == "table" then
        entry = exports.types
      end
      entry = entry or "index.d.ts"
      entry = entry:gsub("^%./", "")
      return vim.fn.fnamemodify(package_json, ":h") .. "/" .. entry
    end

    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end
end

local function variable_type(root, source, name)
  local result
  walk(root, function(node)
    if node:type() ~= "variable_declarator" then
      return false
    end
    local identifier = field_node(node, "name") or first_named_child(node)
    local annotation = field_node(node, "type")
    if identifier and annotation and node_text(identifier, source) == name then
      result = first_named_child(annotation)
      return true
    end
    return false
  end)
  return result
end

local function generic_arguments(node)
  local type_arguments = field_node(node, "type_arguments")
  if not type_arguments then
    return {}
  end

  local result = {}
  for child in type_arguments:iter_children() do
    if child:named() then
      result[#result + 1] = child
    end
  end
  return result
end

local function component_type(root, source, type_node, seen)
  if not type_node then
    return
  end

  seen = seen or {}
  local key = tostring(type_node:id())
  if seen[key] then
    return
  end
  seen[key] = true

  local found
  walk(type_node, function(node)
    if node:type() == "generic_type" then
      local name = first_named_child(node)
      if name and node_text(name, source) == "DefineComponent" then
        found = node
        return true
      end
    end
    return false
  end)
  if found then
    return found
  end

  local type_query
  walk(type_node, function(node)
    if node:type() == "type_query" then
      type_query = node
      return true
    end
    return false
  end)
  if type_query then
    local name = first_named_child(type_query)
    if name then
      return component_type(root, source, variable_type(root, source, node_text(name, source)), seen)
    end
  end
end

local function type_reference(root, source, type_node)
  local candidates = {}
  walk(type_node, function(node)
    if node:type() ~= "type_identifier" then
      return false
    end

    local info = type_info_from_tree(root, source, node)
    if info and #info.members > 0 then
      candidates[#candidates + 1] = info
    end
    return false
  end)

  for _, info in ipairs(candidates) do
    if info.name and info.name:match("Props$") then
      return info
    end
  end

  return candidates[1]
end

local function component_props_type(type_node, source)
  local result
  walk(type_node, function(node)
    if node:type() ~= "property_signature" then
      return false
    end

    local name = field_node(node, "name") or first_named_child(node)
    local annotation = field_node(node, "type") or child_of_type(node, "type_annotation")
    if name and annotation and node_text(name, source) == "props" then
      result = first_named_child(annotation)
      return true
    end
    return false
  end)
  return result
end

local function event_name(name)
  name = name:gsub("^[\"']", ""):gsub("[\"']$", "")
  if name:sub(1, 2) ~= "on" then
    return
  end

  local value = name:sub(3)
  return value:sub(1, 1):lower() .. value:sub(2)
end

local function component_event_lines(type_node, source)
  local result = {}
  walk(type_node, function(node)
    if node:type() ~= "property_signature" then
      return false
    end

    local name_node = field_node(node, "name") or first_named_child(node)
    local annotation = field_node(node, "type") or child_of_type(node, "type_annotation")
    local name = name_node and event_name(node_text(name_node, source))
    if not name or not annotation then
      return false
    end

    local function_type
    walk(annotation, function(child)
      if child:type() == "function_type" then
        function_type = child
        return true
      end
      return false
    end)

    local signature = function_type and clean_signature(node_text(function_type, source))
      or clean_signature(node_text(annotation, source))
    result[#result + 1] = name .. ": " .. signature:gsub("^:%s*", "")
    return false
  end)
  return result
end

local function library_component_info(parsed, export_name)
  local exported_type = variable_type(parsed.root, parsed.source, export_name)
  if not exported_type then
    return
  end

  local props
  local emits
  local define_component = component_type(parsed.root, parsed.source, exported_type)
  if define_component then
    local args = generic_arguments(define_component)
    local props_node = args[1]
    local emits_node = args[8]
    props = props_node and type_info_from_tree(parsed.root, parsed.source, props_node)
    emits = emits_node and type_info_from_tree(parsed.root, parsed.source, emits_node)
  else
    local props_type = component_props_type(exported_type, parsed.source)
    if props_type then
      props = type_reference(parsed.root, parsed.source, props_type)
        or type_info_from_tree(parsed.root, parsed.source, props_type)

      local events = component_event_lines(props_type, parsed.source)
      if #events > 0 then
        emits = { text = "library component events", members = events }
      end
    end
  end

  if emits and emits.text == "{}" and #emits.members == 0 then
    emits = nil
  end

  if not props and not emits then
    return
  end

  return { props = props, emits = emits }
end
local function global_library_component(client, bufnr, component_name)
  local root = project_root(client, bufnr)
  local map_path = global_components_path(root)
  if not map_path then
    return
  end

  local ok, module_name, export_name = pcall(global_component_import, map_path, component_name)
  if not ok or not module_name or not export_name then
    return
  end

  local entry_path = package_entry(root, module_name)
  if not entry_path or vim.fn.filereadable(entry_path) ~= 1 then
    return
  end

  local parsed_ok, parsed = pcall(parse_source_path, entry_path, "typescript")
  if not parsed_ok or not parsed then
    return
  end

  local info_ok, info = pcall(library_component_info, parsed, export_name)
  if not info_ok then
    return
  end

  return info, entry_path
end

local function resolve_type_info(parsed, type_node, client, current_bufnr, callback)
  local info = type_info_from_tree(parsed.root, parsed.source, type_node)
  if not info or not type_node or (info.members and #info.members > 0) or type_node:type() ~= "type_identifier" then
    callback(info)
    return
  end

  local position = source_position(parsed.script, select(1, type_node:range()), select(2, type_node:range()))
  get_definition(client, parsed.path, position, current_bufnr, function(target_path, range)
    if not target_path then
      callback(info)
      return
    end

    type_info_from_target(target_path, info.name, range, current_bufnr, function(target_info)
      callback(target_info or info)
    end)
  end)
end

local function component_at_cursor(bufnr)
  local parser = vim.treesitter.get_parser(bufnr, "vue")
  local root = parser:parse()[1]:root()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]
  local node = root:named_descendant_for_range(row, col, row, col)

  while node do
    if node:type() == "element" then
      local tag = child_of_type(node, "start_tag") or child_of_type(node, "self_closing_tag")
      local tag_name = tag and child_of_type(tag, "tag_name")
      if tag_name then
        local name = node_text(tag_name, bufnr)
        if not COMPONENT_TAGS[name:lower()] then
          return name, tag_name
        end
      end
    end
    node = node:parent()
  end
end

local function show_native_hover()
  vim.lsp.buf.hover()
end
local function render_component_hover(result)
  local lines = { "# " .. result.name, "" }
  if result.props then
    lines[#lines + 1] = "## Props"
    if #result.props.members > 0 then
      for _, member in ipairs(result.props.members) do
        lines[#lines + 1] = "- `" .. member .. "`"
      end
    else
      lines[#lines + 1] = "- `" .. result.props.text .. "`"
    end
    lines[#lines + 1] = ""
  end

  if result.emits then
    lines[#lines + 1] = "## Emits"
    if #result.emits.members > 0 then
      for _, member in ipairs(result.emits.members) do
        lines[#lines + 1] = "- `" .. member .. "`"
      end
    else
      lines[#lines + 1] = "- `" .. result.emits.text .. "`"
    end
    lines[#lines + 1] = ""
  end

  if result.exposed then
    lines[#lines + 1] = "## Exposed"
    for _, member in ipairs(result.exposed.members) do
      lines[#lines + 1] = "- `" .. member .. "`"
    end
  end

  vim.lsp.util.open_floating_preview(lines, "markdown", {
    border = "rounded",
    focus_id = COMPONENT_HOVER_FOCUS_ID,
    focusable = true,
    close_events = { "CursorMoved", "BufHidden", "InsertCharPre" },
  })
end

local function show_component_hover(current_bufnr, component_name, parsed, definition_path)
  local macros = find_macros(parsed.root, parsed.source)
  local props = macros.defineProps
  local emits = macros.defineEmits
  local exposed = macros.defineExpose

  if not props and not emits and not exposed then
    show_native_hover()
    return
  end

  local client = ts_client(current_bufnr)
  local result = {
    name = component_name,
    path = definition_path,
    props = nil,
    emits = nil,
    exposed = nil,
  }
  local type_jobs = {}

  if props and props.type_node then
    type_jobs[#type_jobs + 1] = {
      key = "props",
      node = props.type_node,
    }
  end

  if emits and emits.type_node then
    type_jobs[#type_jobs + 1] = {
      key = "emits",
      node = emits.type_node,
    }
  end

  if exposed and exposed.arguments then
    local object = first_named_child(exposed.arguments)
    if object then
      local members = {}
      for child in object:iter_children() do
        if child:named() and child:type() == "pair" then
          local key = field_node(child, "key")
          if key then
            members[#members + 1] = clean_signature(node_text(key, parsed.source))
          end
        elseif child:named() and child:type():find("shorthand", 1, true) then
          members[#members + 1] = clean_signature(node_text(child, parsed.source))
        end
      end
      result.exposed = { members = members }
    end
  end

  local pending = #type_jobs

  local function finish()
    pending = pending - 1
    if pending > 0 then
      return
    end

    if not result.props and not result.emits and not result.exposed then
      show_native_hover()
      return
    end

    render_component_hover(result)
  end

  if pending == 0 then
    finish()
    return
  end

  for _, job in ipairs(type_jobs) do
    resolve_type_info(parsed, job.node, client, current_bufnr, function(info)
      result[job.key] = info
      finish()
    end)
  end
end

function M.hover(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local component_name, tag_name = component_at_cursor(bufnr)
  if not component_name or not tag_name then
    show_native_hover()
    return
  end

  local client = ts_client(bufnr)
  if not client then
    show_native_hover()
    return
  end

  local row, col = tag_name:range()
  local source_path = vim.api.nvim_buf_get_name(bufnr)
  get_definition(client, source_path, { line = row, character = col }, bufnr, function(target_path)
    if target_path and target_path:match("%.vue$") then
      local target_bufnr = vim.fn.bufadd(target_path)
      vim.fn.bufload(target_bufnr)
      vim.bo[target_bufnr].filetype = "vue"
      local parsed = parse_type_source(target_bufnr, "vue")
      if parsed then
        show_component_hover(bufnr, component_name, parsed, target_path)
        return
      end
    end

    if target_path and target_path:match("%.d%.ts$") then
      local parsed_ok, parsed = pcall(parse_source_path, target_path, "typescript")
      if parsed_ok and parsed then
        local info_ok, info = pcall(library_component_info, parsed, component_name)
        if info_ok and info then
          render_component_hover({
            name = component_name,
            props = info.props,
            emits = info.emits,
          })
          return
        end
      end
    end

    local info = global_library_component(client, bufnr, component_name)
    if info then
      render_component_hover({
        name = component_name,
        props = info.props,
        emits = info.emits,
      })
      return
    end

    show_native_hover()
  end)

end

function M.setup()
  if M._setup then
    return
  end
  M._setup = true

  local function set_keymap(bufnr)
    if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == "vue" then
      vim.keymap.set("n", "K", function()
        M.hover(bufnr)
      end, { buffer = bufnr, desc = "Vue component hover" })
    end
  end

  vim.api.nvim_create_autocmd({ "FileType", "LspAttach" }, {
    callback = function(args)
      vim.defer_fn(function()
        set_keymap(args.buf)
      end, 0)
    end,
  })
end

return M
