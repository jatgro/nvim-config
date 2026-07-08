local tmux_target = nil

local function is_tmux()
  return vim.env.TMUX ~= nil
end

local function get_tmux_panes()
  if not is_tmux() then
    return {}
  end
  local handle = io.popen("tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index} #{pane_title} #{pane_current_command}'")
  if not handle then
    return {}
  end
  local result = handle:read("*a")
  handle:close()
  local panes = {}
  for line in result:gmatch("[^\n]+") do
    table.insert(panes, line)
  end
  return panes
end

local function find_chat_pane()
  local panes = get_tmux_panes()
  for _, pane in ipairs(panes) do
    local lower = pane:lower()
    if lower:match("chat") or lower:match("claude") or lower:match("cascade") or lower:match("agent") then
      return pane:match("^(%S+)")
    end
  end
  return nil
end

local function send_to_tmux(content)
  if not is_tmux() then
    vim.notify("Not running inside tmux", vim.log.levels.ERROR)
    return false
  end
  local target = tmux_target or find_chat_pane()
  if not target then
    vim.notify("No chat pane found. Use :CodeBridgeSetPane to select one", vim.log.levels.WARN)
    return false
  end
  local escaped = content:gsub("'", "'\\''")
  local cmd = string.format("tmux send-keys -t %s '%s'", target, escaped)
  local result = os.execute(cmd)
  return result == 0 or result == true
end

local function select_pane()
  local panes = get_tmux_panes()
  if #panes == 0 then
    vim.notify("No tmux panes found", vim.log.levels.WARN)
    return
  end
  vim.ui.select(panes, { prompt = "Select target pane:" }, function(choice)
    if choice then
      tmux_target = choice:match("^(%S+)")
      vim.notify("Target pane set to: " .. tmux_target, vim.log.levels.INFO)
    end
  end)
end

local function get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line = start_pos[2]
  local end_line = end_pos[2]
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  if #lines == 0 then
    return nil
  end
  local start_col = start_pos[3]
  local end_col = end_pos[3]
  if #lines == 1 then
    lines[1] = string.sub(lines[1], start_col, end_col)
  else
    lines[1] = string.sub(lines[1], start_col)
    lines[#lines] = string.sub(lines[#lines], 1, end_col)
  end
  return table.concat(lines, "\n"), start_line, end_line
end

local function get_buffer_diagnostics()
  local diagnostics = vim.diagnostic.get(0)
  if #diagnostics == 0 then
    return nil
  end
  local severity_map = {
    [vim.diagnostic.severity.ERROR] = "ERROR",
    [vim.diagnostic.severity.WARN] = "WARN",
    [vim.diagnostic.severity.INFO] = "INFO",
    [vim.diagnostic.severity.HINT] = "HINT",
  }
  local formatted = {}
  local filename = vim.fn.expand("%:t")
  table.insert(formatted, string.format("Diagnostics for %s:", filename))
  table.insert(formatted, string.rep("-", 40))
  for _, diag in ipairs(diagnostics) do
    local severity = severity_map[diag.severity] or "UNKNOWN"
    local line = diag.lnum + 1
    local msg = diag.message:gsub("\n", " ")
    local source = diag.source or "unknown"
    table.insert(formatted, string.format("[%s] Line %d (%s): %s", severity, line, source, msg))
  end
  return table.concat(formatted, "\n")
end

return {
  dir = vim.fn.stdpath("config") .. "/lua/jatgro/plugins",
  name = "code-bridge-local",
  event = "VeryLazy",
  config = function()
    vim.api.nvim_create_user_command("CodeBridgeSetPane", select_pane, {})

    vim.keymap.set("v", "<leader>cs", function()
      vim.cmd([[normal! `<v`>]])
      local selection = get_visual_selection()
      if not selection then
        vim.notify("No selection to send", vim.log.levels.WARN)
        return
      end
      local filetype = vim.bo.filetype
      local filename = vim.fn.expand("%:t")
      local content = string.format("```%s\n-- From: %s\n%s\n```", filetype, filename, selection)
      if send_to_tmux(content) then
        vim.notify("Selection sent to chat", vim.log.levels.INFO)
      end
    end, { desc = "Send selection to chat pane" })

    vim.keymap.set("v", "<leader>ci", function()
      vim.cmd([[normal! `<v`>]])
      local selection = get_visual_selection()
      if not selection then
        vim.notify("No selection to query", vim.log.levels.WARN)
        return
      end
      local filetype = vim.bo.filetype
      local filename = vim.fn.expand("%:t")
      vim.ui.input({ prompt = "Question about this code: " }, function(query)
        if not query or query == "" then
          vim.notify("Query cancelled", vim.log.levels.INFO)
          return
        end
        local content = string.format("%s\n\n```%s\n-- From: %s\n%s\n```", query, filetype, filename, selection)
        if send_to_tmux(content) then
          vim.notify("Query sent to chat", vim.log.levels.INFO)
        end
      end)
    end, { desc = "Interactive query about selection" })

    vim.keymap.set("n", "<leader>cf", function()
      local filepath = vim.fn.expand("%:p")
      local line = vim.fn.line(".")
      local filetype = vim.bo.filetype
      local content = string.format("File: `%s`\nLine: %d\nType: %s", filepath, line, filetype)
      if send_to_tmux(content) then
        vim.notify("File reference sent to chat", vim.log.levels.INFO)
      end
    end, { desc = "Send file path and line to chat" })

    vim.keymap.set("n", "<leader>cd", function()
      local diagnostics = get_buffer_diagnostics()
      if not diagnostics then
        vim.notify("No diagnostics in current buffer", vim.log.levels.INFO)
        return
      end
      local filepath = vim.fn.expand("%:p")
      local content = string.format("File: `%s`\n\n%s", filepath, diagnostics)
      if send_to_tmux(content) then
        vim.notify("Diagnostics sent to chat", vim.log.levels.INFO)
      end
    end, { desc = "Send buffer diagnostics to chat" })
  end,
}
