-- Run inside a full Neovim: nvim --headless -c "luafile snapshot.lua"; writes JSON to $FDE_SNAPSHOT_OUT.
local out_path = assert(vim.env.FDE_SNAPSHOT_OUT, "FDE_SNAPSHOT_OUT not set")
local samples_dir = vim.env.FDE_SAMPLES_DIR or (vim.env.HOME .. "/.local/state/fde-ui/samples")

local MODES = { "n", "v", "x", "s", "o", "i", "c", "t" }
local GLOBAL_OPTS = {
  "tabstop", "shiftwidth", "softtabstop", "expandtab", "autoindent", "smartindent",
  "clipboard", "undofile", "swapfile", "backup", "writebackup", "wrap", "number",
  "relativenumber", "ignorecase", "smartcase", "cursorline", "signcolumn", "splitright",
  "splitbelow", "backspace", "scrolloff", "mouse", "timeoutlen", "updatetime",
  "completeopt", "termguicolors", "background", "hlsearch", "incsearch", "textwidth",
}
local BUF_OPTS = { "tabstop", "shiftwidth", "softtabstop", "expandtab", "textwidth", "autoindent", "smartindent", "formatoptions", "commentstring" }
local THEME_GROUPS = {
  "Normal", "NormalFloat", "Pmenu", "WinSeparator", "VertSplit", "FloatBorder", "FloatTitle",
  "Comment", "LineNr", "Function", "Title", "Directory", "Visual", "CursorLine",
  "DiagnosticError", "DiagnosticWarn", "DiagnosticInfo", "DiagnosticOk", "DiagnosticHint",
  "String", "GitSignsAdd", "GitSignsChange", "GitSignsDelete", "DiffAdd", "DiffChange", "DiffDelete",
}

local function norm_map(m)
  return {
    rhs = (m.rhs and m.rhs ~= "") and m.rhs or (m.callback and "<lua>" or ""),
    desc = m.desc or "",
    noremap = m.noremap, silent = m.silent, expr = m.expr, nowait = m.nowait,
  }
end

local function lhs_key(mode, lhs)
  return mode .. "|" .. lhs:gsub(" ", "<Space>")
end

local function collect_maps(getter)
  local res = {}
  for _, mode in ipairs(MODES) do
    for _, m in ipairs(getter(mode)) do
      res[lhs_key(mode, m.lhs)] = norm_map(m)
    end
  end
  return res
end

local function collect_cmds(tbl)
  local res = {}
  for name, c in pairs(tbl) do
    res[name] = { nargs = c.nargs, definition = c.definition or "" }
  end
  return res
end

local function sorted(t)
  table.sort(t)
  return t
end

local function snapshot()
  local snap = { meta = { fde_ui_env = vim.env.FDE_UI or "", nvim = tostring(vim.version()) } }

  snap.options = {}
  for _, o in ipairs(GLOBAL_OPTS) do
    snap.options[o] = vim.go[o]
  end

  snap.keymaps = collect_maps(vim.api.nvim_get_keymap)
  snap.commands = collect_cmds(vim.api.nvim_get_commands({ builtin = false }))

  snap.samples = {}
  local names = { "sample.py", "sample.lua", "sample.md" }
  local bufs = {}
  for _, name in ipairs(names) do
    vim.cmd.edit(vim.fn.fnameescape(samples_dir .. "/" .. name))
    bufs[name] = vim.api.nvim_get_current_buf()
  end

  -- Wait until LSP attachments stop changing (min 6 s, settled for 4 s, max 25 s).
  local function attached()
    local n = 0
    for _, b in pairs(bufs) do
      n = n + #vim.lsp.get_clients({ bufnr = b })
    end
    return n
  end
  local start = vim.uv.now()
  local last, since = -1, start
  while vim.uv.now() - start < 25000 do
    vim.wait(250)
    local n, now = attached(), vim.uv.now()
    if n ~= last then
      last, since = n, now
    elseif now - start >= 6000 and now - since >= 4000 then
      break
    end
  end

  for _, name in ipairs(names) do
    local buf = bufs[name]
    local s = { filetype = vim.bo[buf].filetype }
    s.lsp = {}
    for _, c in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
      table.insert(s.lsp, c.name)
    end
    sorted(s.lsp)
    s.formatters = {}
    local ok_c, conform = pcall(require, "conform")
    if ok_c then
      if conform.list_formatters_for_buffer then
        s.formatters = vim.tbl_map(tostring, conform.list_formatters_for_buffer(buf))
      else
        s.formatters = vim.tbl_map(function(f) return f.name end, conform.list_formatters(buf))
      end
    end
    s.linters = {}
    local ok_l, lint = pcall(require, "lint")
    if ok_l then
      s.linters = vim.deepcopy(lint.linters_by_ft[s.filetype] or {})
    end
    s.options = {}
    for _, o in ipairs(BUF_OPTS) do
      s.options[o] = vim.bo[buf][o]
    end
    s.keymaps = collect_maps(function(mode)
      return vim.api.nvim_buf_get_keymap(buf, mode)
    end)
    s.commands = collect_cmds(vim.api.nvim_buf_get_commands(buf, {}))
    snap.samples[name] = s
  end

  local augroups = {}
  for _, a in ipairs(vim.api.nvim_get_autocmds({})) do
    local g = a.group_name or "<none>"
    augroups[g] = augroups[g] or {}
    local entry = table.concat({ a.event, a.pattern or "", a.desc or "", a.buflocal and "buf" or "" }, "|")
    augroups[g][entry] = true
  end
  snap.augroups = {}
  for g, set in pairs(augroups) do
    snap.augroups[g] = sorted(vim.tbl_keys(set))
  end

  local lock = io.open(vim.fn.stdpath("config") .. "/lazy-lock.json", "r")
  snap.lazy_lock = lock and vim.json.decode(lock:read("*a")) or {}
  if lock then lock:close() end

  snap.theme = {
    colors_name = vim.g.colors_name or "",
    background = vim.o.background,
    highlights = vim.api.nvim_get_hl(0, {}),
    resolved = {},
  }
  for _, g in ipairs(THEME_GROUPS) do
    snap.theme.resolved[g] = vim.api.nvim_get_hl(0, { name = g, link = false })
  end

  if vim.fn.executable("tmux") == 1 then
    local r = vim.system({ "tmux", "show", "-g" }, { text = true }):wait()
    if r.code == 0 then
      local lines = {}
      for line in r.stdout:gmatch("[^\n]+") do
        if line:match("^status") or line:match("^pane%-.*border") or line:match("^message")
          or line:match("^mode%-style") or line:match("^window%-status") then
          table.insert(lines, line)
        end
      end
      snap.tmux = sorted(lines)
    end
  end

  local f = assert(io.open(out_path, "w"))
  f:write(vim.json.encode(snap))
  f:close()
end

vim.schedule(function()
  -- Headless Neovim never fires UIEnter, so lazy.nvim's VeryLazy has to be triggered by hand.
  if not vim.g.did_very_lazy then
    vim.g.did_very_lazy = true
    vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy", modeline = false })
  end
  vim.defer_fn(function()
    local ok, err = pcall(snapshot)
    if not ok then
      io.stderr:write("snapshot failed: " .. tostring(err) .. "\n")
    end
    -- Keep auto-session (and others) from writing session files on exit.
    pcall(vim.api.nvim_clear_autocmds, { event = "VimLeavePre" })
    vim.cmd("qa!")
  end, 1500)
end)
