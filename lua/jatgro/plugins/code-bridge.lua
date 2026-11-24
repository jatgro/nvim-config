local providers = {
  codex = {
    label = "Codex",
    option = "@code_bridge_codex_pane",
    patterns = { "codex" },
  },
  claude = {
    label = "Claude",
    option = "@code_bridge_claude_pane",
    patterns = { "claude" },
  },
}

local limits = {
  diagnostics = 20,
  selection_chars = 12000,
  selection_lines = 200,
}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Code Bridge" })
end

local function run(command, options)
  options = options or {}
  local result = vim.system(command, {
    stdin = options.stdin,
    text = true,
  }):wait()
  return result.code == 0, vim.trim(result.stdout or ""), vim.trim(result.stderr or "")
end

local function tmux_window_id()
  if not vim.env.TMUX or not vim.env.TMUX_PANE then
    return nil, "Neovim is not running inside tmux"
  end

  local ok, window_id, err = run({
    "tmux",
    "display-message",
    "-p",
    "-t",
    vim.env.TMUX_PANE,
    "#{window_id}",
  })
  if not ok or window_id == "" then
    return nil, err ~= "" and err or "Unable to determine the current tmux window"
  end
  return window_id
end

local function list_window_panes(window_id)
  local format = table.concat({
    "#{pane_id}",
    "#{pane_index}",
    "#{pane_current_command}",
    "#{pane_title}",
    "#{pane_start_command}",
  }, "\t")
  local ok, output, err = run({ "tmux", "list-panes", "-t", window_id, "-F", format })
  if not ok then
    return nil, err ~= "" and err or "Unable to list tmux panes"
  end

  local panes = {}
  for line in output:gmatch("[^\r\n]+") do
    local fields = vim.split(line, "\t", { plain = true })
    table.insert(panes, {
      id = fields[1],
      index = tonumber(fields[2]) or math.huge,
      command = fields[3] or "",
      title = fields[4] or "",
      start_command = fields[5] or "",
    })
  end
  table.sort(panes, function(left, right)
    return left.index < right.index
  end)
  return panes
end

local function pane_matches_provider(pane, provider)
  local searchable = table.concat({ pane.command, pane.title, pane.start_command }, " "):lower()
  for _, pattern in ipairs(providers[provider].patterns) do
    if searchable:find(pattern, 1, true) then
      return true
    end
  end
  return false
end

local function get_window_option(window_id, option)
  local ok, value = run({ "tmux", "show-options", "-wqv", "-t", window_id, option })
  if ok and value ~= "" then
    return value
  end
  return nil
end

local function set_window_option(window_id, option, value)
  return run({ "tmux", "set-option", "-wq", "-t", window_id, option, value })
end

local function unset_window_option(window_id, option)
  run({ "tmux", "set-option", "-wqu", "-t", window_id, option })
end

local function resolve_pane(provider)
  local window_id, window_err = tmux_window_id()
  if not window_id then
    return nil, window_err
  end

  local panes, panes_err = list_window_panes(window_id)
  if not panes then
    return nil, panes_err
  end

  local pane_by_id = {}
  for _, pane in ipairs(panes) do
    pane_by_id[pane.id] = pane
  end

  local definition = providers[provider]
  local remembered = get_window_option(window_id, definition.option)
  if remembered and pane_by_id[remembered] then
    return pane_by_id[remembered]
  end

  for _, pane in ipairs(panes) do
    if pane.id ~= vim.env.TMUX_PANE and pane_matches_provider(pane, provider) then
      set_window_option(window_id, definition.option, pane.id)
      return pane
    end
  end

  return nil, string.format(
    "No %s pane found in this tmux window. Start `%s` in a pane and retry.",
    definition.label,
    provider
  )
end

local function paste_to_pane(pane_id, content)
  local buffer_name = string.format("code-bridge-%s", tostring(vim.uv.hrtime()))
  local loaded, _, load_err = run({ "tmux", "load-buffer", "-b", buffer_name, "-" }, { stdin = content })
  if not loaded then
    return false, load_err ~= "" and load_err or "Unable to load the tmux paste buffer"
  end

  local pasted, _, paste_err = run({
    "tmux",
    "paste-buffer",
    "-p",
    "-d",
    "-b",
    buffer_name,
    "-t",
    pane_id,
  })
  if not pasted then
    run({ "tmux", "delete-buffer", "-b", buffer_name })
    return false, paste_err ~= "" and paste_err or "Unable to paste into the tmux pane"
  end
  return true
end

local function project_paths(absolute_path)
  local cwd = vim.fn.getcwd()
  local root = vim.fs.root(absolute_path, { ".git" }) or cwd
  local relative = vim.fs.relpath(root, absolute_path) or absolute_path
  return root, relative
end

local function ordered_positions(first, second)
  if first[2] > second[2] or (first[2] == second[2] and first[3] > second[3]) then
    return second, first
  end
  return first, second
end

local function visual_selection()
  local mode = vim.fn.mode()
  local first, last = ordered_positions(vim.fn.getpos("v"), vim.fn.getpos("."))
  local lines = vim.fn.getregion(first, last, { type = mode })
  if not lines or #lines == 0 then
    return nil, "No visual selection found"
  end

  local original_line_count = #lines
  local truncated = false
  if #lines > limits.selection_lines then
    lines = vim.list_slice(lines, 1, limits.selection_lines)
    truncated = true
  end

  local text = table.concat(lines, "\n")
  local character_count = vim.fn.strchars(text)
  if character_count > limits.selection_chars then
    text = vim.fn.strcharpart(text, 0, limits.selection_chars)
    truncated = true
  end

  return {
    text = text,
    start_line = first[2],
    end_line = last[2],
    start_col = math.max(first[3] - 1, 0),
    original_line_count = original_line_count,
    truncated = truncated,
  }
end

local function current_line_context()
  local cursor = vim.api.nvim_win_get_cursor(0)
  return {
    text = vim.api.nvim_get_current_line(),
    start_line = cursor[1],
    end_line = cursor[1],
    start_col = cursor[2],
    original_line_count = 1,
    truncated = false,
  }
end

local function is_symbol_node(node_type)
  if node_type:find("call", 1, true) then
    return false
  end
  for _, fragment in ipairs({ "function", "method", "class", "struct", "interface", "module", "namespace" }) do
    if node_type:find(fragment, 1, true) then
      return true
    end
  end
  return node_type == "impl_item"
end

local function enclosing_symbol(line, column)
  local ok, node = pcall(vim.treesitter.get_node, {
    bufnr = 0,
    pos = { math.max(line - 1, 0), math.max(column, 0) },
  })
  if not ok or not node then
    return nil
  end

  while node and not is_symbol_node(node:type()) do
    node = node:parent()
  end
  if not node then
    return nil
  end

  local name = nil
  local name_nodes = node:field("name")
  if name_nodes and name_nodes[1] then
    local name_ok, text = pcall(vim.treesitter.get_node_text, name_nodes[1], 0)
    if name_ok then
      name = vim.trim(text):gsub("%s+", " ")
    end
  end

  local start_row, _, end_row, end_column = node:range()
  local end_line = end_row + 1
  if end_column == 0 and end_row > start_row then
    end_line = end_row
  end
  return {
    type = node:type(),
    name = name,
    start_line = start_row + 1,
    end_line = end_line,
  }
end

local function relevant_diagnostics(start_line, end_line)
  local severity_names = {
    [vim.diagnostic.severity.ERROR] = "ERROR",
    [vim.diagnostic.severity.WARN] = "WARN",
    [vim.diagnostic.severity.INFO] = "INFO",
    [vim.diagnostic.severity.HINT] = "HINT",
  }
  local diagnostics = vim.diagnostic.get(0)
  table.sort(diagnostics, function(left, right)
    if left.lnum == right.lnum then
      return left.col < right.col
    end
    return left.lnum < right.lnum
  end)

  local relevant = {}
  for _, diagnostic in ipairs(diagnostics) do
    local diagnostic_start = diagnostic.lnum + 1
    local diagnostic_end = (diagnostic.end_lnum or diagnostic.lnum) + 1
    if diagnostic_end >= start_line and diagnostic_start <= end_line then
      local message = diagnostic.message:gsub("%s+", " ")
      if vim.fn.strchars(message) > 240 then
        message = vim.fn.strcharpart(message, 0, 240) .. "…"
      end
      table.insert(relevant, string.format(
        "- [%s] %d:%d (%s): %s",
        severity_names[diagnostic.severity] or "UNKNOWN",
        diagnostic_start,
        diagnostic.col + 1,
        diagnostic.source or "unknown",
        message
      ))
      if #relevant == limits.diagnostics then
        break
      end
    end
  end
  return relevant
end

local function markdown_fence(text)
  local longest = 0
  for run in text:gmatch("`+") do
    longest = math.max(longest, #run)
  end
  return string.rep("`", math.max(3, longest + 1))
end

local function build_context(use_visual_selection)
  local absolute_path = vim.api.nvim_buf_get_name(0)
  if absolute_path == "" then
    return nil, "The current buffer does not have a file path"
  end

  local selection, selection_err
  if use_visual_selection then
    selection, selection_err = visual_selection()
  else
    selection = current_line_context()
  end
  if not selection then
    return nil, selection_err
  end

  local root, relative_path = project_paths(absolute_path)
  local symbol = enclosing_symbol(selection.start_line, selection.start_col)
  local diagnostics = relevant_diagnostics(selection.start_line, selection.end_line)
  local filetype = vim.bo.filetype ~= "" and vim.bo.filetype or "text"
  local safe_filetype = filetype:gsub("[^%w_+%-]", "")
  local fence = markdown_fence(selection.text)
  local lines = {
    "Use this editor context as the starting point. Inspect related definitions, callers, imports, and tests in the repository when relevant; do not assume the selected code is the complete context.",
    "",
    "Editor context:",
    "- Project root: " .. root,
    "- File: " .. relative_path,
    "- Absolute path: " .. absolute_path,
    string.format("- Lines: %d-%d", selection.start_line, selection.end_line),
    "- Filetype: " .. filetype,
  }

  if symbol then
    local symbol_name = symbol.name and (" `" .. symbol.name .. "`") or ""
    table.insert(lines, string.format(
      "- Enclosing symbol: %s%s (lines %d-%d)",
      symbol.type,
      symbol_name,
      symbol.start_line,
      symbol.end_line
    ))
  end

  if #diagnostics > 0 then
    table.insert(lines, "")
    table.insert(lines, "Diagnostics in this range:")
    vim.list_extend(lines, diagnostics)
  end

  table.insert(lines, "")
  table.insert(lines, use_visual_selection and "Selected code:" or "Current line:")
  table.insert(lines, fence .. safe_filetype)
  table.insert(lines, selection.text)
  table.insert(lines, fence)
  if selection.truncated then
    table.insert(lines, string.format(
      "[Selection truncated from %d lines; read the referenced file for the complete context.]",
      selection.original_line_count
    ))
  end

  return table.concat(lines, "\n")
end

local function deliver(provider, content)
  local requested = provider == "both" and { "codex", "claude" } or { provider }
  local delivered = {}
  local failures = {}

  for _, name in ipairs(requested) do
    local pane, resolve_err = resolve_pane(name)
    if not pane then
      table.insert(failures, resolve_err)
    else
      local ok, paste_err = paste_to_pane(pane.id, content)
      if ok then
        table.insert(delivered, providers[name].label)
      else
        table.insert(failures, string.format("%s: %s", providers[name].label, paste_err))
      end
    end
  end

  if #delivered > 0 then
    notify("Context pasted to " .. table.concat(delivered, " and ") .. "; review it and press Enter to submit")
  end
  if #failures > 0 then
    notify(table.concat(failures, "\n"), vim.log.levels.WARN)
  end
end

local function ask(provider, use_visual_selection)
  local context, context_err = build_context(use_visual_selection)
  if not context then
    notify(context_err, vim.log.levels.WARN)
    return
  end

  local label = provider == "both" and "Codex + Claude" or providers[provider].label
  vim.ui.input({ prompt = "Ask " .. label .. ": " }, function(question)
    if not question or vim.trim(question) == "" then
      return
    end
    local content = "Request: " .. vim.trim(question) .. "\n\n" .. context
    deliver(provider, content)
  end)
end

local function bridge_status()
  local statuses = {}
  for _, name in ipairs({ "codex", "claude" }) do
    local pane, err = resolve_pane(name)
    if pane then
      table.insert(statuses, string.format("%s: %s (pane %s)", providers[name].label, pane.title, pane.id))
    else
      table.insert(statuses, string.format("%s: %s", providers[name].label, err))
    end
  end
  notify(table.concat(statuses, "\n"))
end

local function refresh_targets()
  local window_id, err = tmux_window_id()
  if not window_id then
    notify(err, vim.log.levels.ERROR)
    return
  end
  for _, provider in pairs(providers) do
    unset_window_option(window_id, provider.option)
  end
  bridge_status()
end

local function replace_command(name, callback)
  pcall(vim.api.nvim_del_user_command, name)
  vim.api.nvim_create_user_command(name, callback, {})
end

return {
  dir = vim.fn.stdpath("config") .. "/lua/jatgro/plugins",
  name = "code-bridge-local",
  event = "VeryLazy",
  config = function()
    replace_command("CodeBridgeStatus", bridge_status)
    replace_command("CodeBridgeRefresh", refresh_targets)
    replace_command("CodeBridgeAskCodex", function()
      ask("codex", false)
    end)
    replace_command("CodeBridgeAskClaude", function()
      ask("claude", false)
    end)
    replace_command("CodeBridgeAskBoth", function()
      ask("both", false)
    end)

    vim.keymap.set("n", "<leader>ao", function()
      ask("codex", false)
    end, { desc = "Ask Codex about cursor context" })
    vim.keymap.set("x", "<leader>ao", function()
      ask("codex", true)
    end, { desc = "Ask Codex about selection" })

    vim.keymap.set("n", "<leader>aa", function()
      ask("claude", false)
    end, { desc = "Ask Claude about cursor context" })
    vim.keymap.set("x", "<leader>aa", function()
      ask("claude", true)
    end, { desc = "Ask Claude about selection" })

    vim.keymap.set("n", "<leader>ab", function()
      ask("both", false)
    end, { desc = "Ask both AIs about cursor context" })
    vim.keymap.set("x", "<leader>ab", function()
      ask("both", true)
    end, { desc = "Ask both AIs about selection" })
  end,
}
