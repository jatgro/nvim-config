local M = {}

local sources = {
  fg = { "Normal", "Pmenu", "Comment", "FloatTitle" },
  border = { "WinSeparator", "VertSplit", "FloatBorder" },
  muted = { "Comment", "LineNr" },
  accent = { "FloatTitle", "Function", "Title", "Directory" },
  error = { "DiagnosticError" },
  warn = { "DiagnosticWarn" },
  info = { "DiagnosticInfo" },
  ok = { "DiagnosticOk", "DiagnosticHint", "String" },
  git_add = { "GitSignsAdd", "DiffAdd" },
  git_change = { "GitSignsChange", "DiffChange" },
  git_delete = { "GitSignsDelete", "DiffDelete" },
}

local order = {
  "bg", "fg", "sidebar_bg", "panel_bg", "border", "muted", "accent",
  "selection", "error", "warn", "info", "ok", "git_add", "git_change", "git_delete",
}

local function first(groups, attribute)
  for _, name in ipairs(groups) do
    local ok, highlight = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    if ok and type(highlight[attribute]) == "number" then
      return { value = highlight[attribute], source = name .. "." .. attribute }
    end
  end
end

local function blend(from, to, ratio)
  local result = 0
  for shift = 0, 16, 8 do
    local start = math.floor(from / 2 ^ shift) % 256
    local finish = math.floor(to / 2 ^ shift) % 256
    result = result + math.floor(start + (finish - start) * ratio + 0.5) * 2 ^ shift
  end
  return result
end

local function derived(value, source)
  return { value = value, source = source }
end

function M.resolve()
  local theme_background = first({ "Normal" }, "bg")
  local roles = {
    bg = theme_background or derived(nil, "Normal.bg (transparent)"),
    fg = first(sources.fg, "fg"),
  }
  local background = roles.bg.value
    or (first({ "NormalFloat", "Pmenu", "Visual" }, "bg") or {}).value
    or (roles.fg and roles.fg.value)
  local foreground = roles.fg and roles.fg.value
  if not background or not foreground then
    error("fde_ui: theme must provide a foreground and a background or fallback highlight")
  end

  local toward = vim.o.background == "light" and 255 or 0
  local edge = toward * (1 + 256 + 65536)
  roles.sidebar_bg = first({ "NormalFloat", "Pmenu" }, "bg")
    or derived(blend(background, edge, 0.06), "bg blended 6%")
  roles.panel_bg = first({ "NormalFloat" }, "bg") or derived(roles.sidebar_bg.value, "sidebar_bg")
  roles.selection = first({ "Visual", "CursorLine" }, "bg")
    or derived(blend(background, foreground, 0.25), "bg + fg blend")

  for role, groups in pairs(sources) do
    roles[role] = first(groups, "fg") or derived(blend(background, foreground, 0.65), "bg + fg blend")
  end

  local config = vim.g.fde_ui_palette or {}
  if config.source and config.source ~= "auto" and config.source ~= "manual" then
    local preset = config.source:match("^preset:([%w_]+)$")
    if not preset then error("fde_ui: invalid palette source " .. tostring(config.source)) end
    local values = require("fde_ui.presets." .. preset)
    for role, value in pairs(values) do
      if roles[role] then
        roles[role] = derived(tonumber(value:sub(2), 16), config.source)
      end
    end
  end

  local defaults = (config.source == nil or config.source == "auto")
    and { accent = "@Function" } or {}
  local overrides = vim.tbl_extend("force", defaults, config.overrides or {})
  for role, value in pairs(overrides) do
    if not roles[role] then error("fde_ui: unknown palette role " .. tostring(role)) end
    if type(value) ~= "string" then error("fde_ui: invalid override for " .. role) end
    local group = value:match("^@(.+)$")
    local color = group and first({ group }, "fg")
      or (value:match("^#%x%x%x%x%x%x$") and derived(tonumber(value:sub(2), 16), value))
    if not color then error("fde_ui: invalid override for " .. role .. ": " .. value) end
    roles[role] = color
  end

  return roles, theme_background == nil and not (config.source or ""):match("^preset:")
end

function M.apply()
  local roles, transparent = M.resolve()
  local function set(name, foreground, background, extra)
    local highlight = extra or {}
    highlight.fg = roles[foreground].value
    if background and not transparent then highlight.bg = roles[background].value end
    vim.api.nvim_set_hl(0, "FdeUi" .. name, highlight)
  end

  set("Normal", "fg", "bg")
  set("Sidebar", "fg", "sidebar_bg")
  set("Panel", "fg", "panel_bg")
  set("Border", "border")
  set("Muted", "muted")
  set("Accent", "accent", nil, { bold = true })
  set("Selection", "fg", "selection")
  for _, role in ipairs({ "error", "warn", "info", "ok", "git_add", "git_change", "git_delete" }) do
    local name = role:gsub("^%l", string.upper):gsub("_(%l)", string.upper)
    set(name, role)
  end
  for _, role in ipairs(order) do
    local name = role:gsub("^%l", string.upper):gsub("_(%l)", string.upper)
    vim.api.nvim_set_hl(0, "FdeUiSwatch" .. name, { fg = roles[role].value or roles.fg.value })
  end

  return roles
end

local function display(role)
  return role.value and string.format("#%06X", role.value) or "transparent"
end

local function lines_for(roles)
  local lines = {}
  for _, name in ipairs(order) do
    table.insert(lines, string.format(" ##  %-12s %-11s %s", name, display(roles[name]), roles[name].source))
  end
  return lines
end

function M.show()
  local roles = M.apply()
  local lines = lines_for(roles)
  local width = 0
  for _, line in ipairs(lines) do width = math.max(width, vim.fn.strdisplaywidth(line)) end
  width = math.min(width + 2, vim.o.columns - 4)
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  local namespace = vim.api.nvim_create_namespace("FdeUiPalette")
  for index, name in ipairs(order) do
    local highlight = name:gsub("^%l", string.upper):gsub("_(%l)", string.upper)
    vim.api.nvim_buf_add_highlight(buffer, namespace, "FdeUiSwatch" .. highlight, index - 1, 1, 3)
  end
  local window = vim.api.nvim_open_win(buffer, true, {
    relative = "editor", row = math.max(0, math.floor((vim.o.lines - #lines - 2) / 2)),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
    width = width, height = #lines, style = "minimal", border = "rounded",
  })
  vim.keymap.set("n", "q", function() vim.api.nvim_win_close(window, true) end,
    { buffer = buffer, silent = true, desc = "Close palette" })
end

function M.setup()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("FdeUiTheme", { clear = true }),
    callback = function() vim.schedule(M.apply) end,
  })
  vim.api.nvim_create_user_command("FDEPalette", function(opts)
    if opts.args == "reload" then
      M.apply()
    elseif opts.args == "dump" then
      print(table.concat(lines_for(M.resolve()), "\n"))
    elseif opts.args == "" then
      M.show()
    else
      error("FDEPalette: expected reload or dump")
    end
  end, { nargs = "?", complete = function() return { "reload", "dump" } end })
  vim.schedule(M.apply)
end

return M