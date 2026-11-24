-- Driver: nvim --clean -l verify.lua [--baseline]
local HOME = assert(vim.env.HOME)
local STATE = HOME .. "/.local/state/fde-ui"
local TOOLS = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
local STARTUP_LIMIT_MS = 15

-- Generated at runtime by plugins (per component / per notification / icon load order), not by the theme.
local VOLATILE_HL = { "^lualine_", "^Notify%u+%a*%d+$", "^DevIcon" }
-- One-shot autocmds that delete themselves on first trigger, so presence depends on timing.
local VOLATILE_AUGROUPS = { ["LSPFileOps.Integrations"] = true }

local function is_volatile_hl(name)
  for _, pat in ipairs(VOLATILE_HL) do
    if name:find(pat) then return true end
  end
  return false
end

local function without(t, pred)
  local res, skipped = {}, 0
  for k, v in pairs(t or {}) do
    if pred(k) then skipped = skipped + 1 else res[k] = v end
  end
  return res, skipped
end

local function normalize_autocmds(groups)
  local normalized = {}
  for name, entries in pairs(groups) do
    local stable_name = name:gsub("^nvim%.lsp%.b_%d+_save$", "nvim.lsp.b_<buffer>_save")
      :gsub("^nvim%.lsp%.semantic_tokens:%d+$", "nvim.lsp.semantic_tokens:<buffer>")
      :gsub("^nvim%.lsp%.document_color:%d+$", "nvim.lsp.document_color:<buffer>")
      :gsub("^nvim%-ts%-autotag%-%d+$", "nvim-ts-autotag-<buffer>")
    normalized[stable_name] = normalized[stable_name] or {}
    for _, entry in ipairs(entries) do
      normalized[stable_name][entry:gsub("<buffer=%d+>", "<buffer>")] = true
    end
  end
  for name, entries in pairs(normalized) do
    normalized[name] = vim.tbl_keys(entries)
    table.sort(normalized[name])
  end
  return normalized
end

local function read_json(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local data = vim.json.decode(f:read("*a"))
  f:close()
  return data
end

local function write_json(path, data)
  local f = assert(io.open(path, "w"))
  f:write(vim.json.encode(data))
  f:close()
end

local function take_snapshot(out)
  os.remove(out)
  local r = vim.system(
    { "nvim", "--headless", "-c", "luafile " .. TOOLS .. "/snapshot.lua" },
    { cwd = STATE .. "/samples", env = { FDE_SNAPSHOT_OUT = out }, text = true }
  ):wait(120000)
  local snap = read_json(out)
  if not snap then
    error("snapshot failed (code " .. tostring(r.code) .. "): " .. (r.stderr or ""))
  end
  return snap
end

local function measure_startup()
  local times = {}
  -- Run 0 is a discarded warm-up; 9 measured runs because 5 swing by up to 40 ms on this machine.
  for i = 0, 9 do
    local log = os.tmpname()
    os.remove(log)
    -- cwd $HOME is in auto-session's suppress list, so no session file is written.
    vim.system({ "nvim", "--headless", "--startuptime", log, "+qa!" }, { cwd = HOME }):wait(60000)
    local f = io.open(log, "r")
    if f then
      for line in f:lines() do
        local ms = line:match("^(%d+%.%d+)%s.-NVIM STARTED")
        if ms and i > 0 then table.insert(times, tonumber(ms)) end
      end
      f:close()
    end
    os.remove(log)
  end
  table.sort(times)
  return times[math.ceil(#times / 2)], times
end

local allow = read_json(STATE .. "/allowlist.json") or {}
local function allowed(list, key)
  for _, pat in ipairs(allow[list] or {}) do
    if key:find(pat, 1, true) == 1 then return true end
  end
  return false
end

local results, failed = {}, false
local function report(section, problems, summary)
  if #problems > 0 then failed = true end
  table.insert(results, string.format("%-10s %s  %s", section, #problems == 0 and "PASS" or "FAIL", summary or ""))
  for i, p in ipairs(problems) do
    if i > 25 then
      table.insert(results, "    ... " .. (#problems - 25) .. " more")
      break
    end
    table.insert(results, "    - " .. p)
  end
end

-- Existing keys must be identical; new keys need an allowlist entry (or a prefix rule).
local function diff_map(base, cur, label, allow_list, new_ok)
  local problems, changed, removed, added = {}, 0, 0, 0
  for k, v in pairs(base or {}) do
    if cur[k] == nil then
      removed = removed + 1
      table.insert(problems, label .. " removed: " .. k)
    elseif not vim.deep_equal(v, cur[k]) then
      changed = changed + 1
      table.insert(problems, label .. " changed: " .. k)
    end
  end
  for k in pairs(cur or {}) do
    if base[k] == nil then
      added = added + 1
      if not ((new_ok and new_ok(k)) or allowed(allow_list, k)) then
        table.insert(problems, label .. " unexpected new: " .. k)
      end
    end
  end
  return problems, string.format("%d changed, %d removed, %d new", changed, removed, added)
end

local function count(t)
  return vim.tbl_count(t or {})
end

local args = _G.arg or {}
local mode = args[1]

if mode == "--baseline" then
  local snap = take_snapshot(STATE .. "/baseline.json.tmp")
  snap.startup_ms, snap.startup_runs = measure_startup()
  write_json(STATE .. "/baseline.json", snap)
  os.remove(STATE .. "/baseline.json.tmp")
  if not read_json(STATE .. "/allowlist.json") then
    write_json(STATE .. "/allowlist.json", { keymaps = {}, commands = {}, plugins = {}, augroups = {}, hl_prefixes = {}, tmux = false })
  end
  print(string.format("baseline written: %d keymaps, %d commands, %d plugins, %d augroups, %d hl groups, colors=%s, startup=%.1f ms",
    count(snap.keymaps), count(snap.commands), count(snap.lazy_lock), count(snap.augroups),
    count(snap.theme.highlights), snap.theme.colors_name, snap.startup_ms or -1))
  os.exit(0)
end

local base = read_json(STATE .. "/baseline.json")
if not base then
  print("no baseline; run: fde-ui-verify --baseline")
  os.exit(2)
end
local cur = take_snapshot(STATE .. "/last.json")
cur.startup_ms, cur.startup_runs = measure_startup()
write_json(STATE .. "/last.json", cur)

do
  local p, s = diff_map(base.keymaps, cur.keymaps, "global", "keymaps")
  for name, bs in pairs(base.samples) do
    local cs = cur.samples[name] or {}
    local bp = diff_map(bs.keymaps, cs.keymaps or {}, name, "keymaps")
    vim.list_extend(p, bp)
  end
  report("keymaps", p, s .. " (global; buffer-local on samples checked too)")
end

do
  local p, s = diff_map(base.commands, cur.commands, "command", "commands")
  for name, bs in pairs(base.samples) do
    vim.list_extend(p, (diff_map(bs.commands, (cur.samples[name] or {}).commands or {}, name .. " command", "commands")))
  end
  report("commands", p, s)
end

do
  local p, s = diff_map(base.lazy_lock, cur.lazy_lock, "plugin", "plugins")
  report("plugins", p, s)
end

do
  local p = {}
  for name, bs in pairs(base.samples) do
    local cs = cur.samples[name] or {}
    for _, field in ipairs({ "filetype", "lsp", "formatters", "linters" }) do
      if not vim.deep_equal(bs[field], cs[field]) then
        table.insert(p, string.format("%s %s: %s -> %s", name, field, vim.inspect(bs[field]), vim.inspect(cs[field])))
      end
    end
  end
  report("lsp/fmt", p, "lsp, formatters, linters per sample")
end

do
  local p = {}
  for k, v in pairs(base.options) do
    if not vim.deep_equal(v, cur.options[k]) then
      table.insert(p, string.format("%s: %s -> %s", k, vim.inspect(v), vim.inspect(cur.options[k])))
    end
  end
  for name, bs in pairs(base.samples) do
    for k, v in pairs(bs.options) do
      local cv = ((cur.samples[name] or {}).options or {})[k]
      if not vim.deep_equal(v, cv) then
        table.insert(p, string.format("%s %s: %s -> %s", name, k, vim.inspect(v), vim.inspect(cv)))
      end
    end
  end
  report("options", p, count(base.options) .. " global + per-sample buffer options")
end

do
  local is_vol = function(k) return VOLATILE_AUGROUPS[k] end
  local ba = normalize_autocmds(without(base.augroups, is_vol))
  local ca = normalize_autocmds(without(cur.augroups, is_vol))
  local p, s = diff_map(ba, ca, "augroup", "augroups", function(k)
    return k:find("^FdeUi") ~= nil
  end)
  for g, entries in pairs(ba) do
    if ca[g] and not vim.deep_equal(entries, ca[g]) then
      local cs = {}
      for _, e in ipairs(ca[g]) do cs[e] = true end
      for _, e in ipairs(entries) do
        if not cs[e] then table.insert(p, "  " .. g .. " lost: " .. e) end
        cs[e] = nil
      end
      for e in pairs(cs) do table.insert(p, "  " .. g .. " gained: " .. e) end
    end
  end
  report("autocmds", p, s .. " (" .. vim.tbl_count(VOLATILE_AUGROUPS) .. " one-shot group ignored)")
end

do
  local p = {}
  if base.theme.colors_name ~= cur.theme.colors_name then
    table.insert(p, "colors_name: " .. base.theme.colors_name .. " -> " .. cur.theme.colors_name)
  end
  if base.theme.background ~= cur.theme.background then
    table.insert(p, "background: " .. base.theme.background .. " -> " .. cur.theme.background)
  end
  local bh, skipped = without(base.theme.highlights, is_volatile_hl)
  local ch = without(cur.theme.highlights, is_volatile_hl)
  local hp, hs = diff_map(bh, ch, "hl", "hl_prefixes", function(k)
    return k:find("^FdeUi") ~= nil
  end)
  vim.list_extend(p, hp)
  if not vim.deep_equal(base.theme.resolved, cur.theme.resolved) then
    table.insert(p, "resolved theme roles differ")
  end
  report("theme", p, string.format("%s/%s, %d groups: %s (%d plugin-generated ignored)",
    cur.theme.colors_name, cur.theme.background, vim.tbl_count(bh), hs, skipped))
end

do
  local p = {}
  if not allow.tmux and not vim.deep_equal(base.tmux, cur.tmux) then
    table.insert(p, "tmux theme options differ (see last.json .tmux)")
  end
  report("tmux", p, base.tmux and (#base.tmux .. " options") or "tmux not captured")
end

do
  local p = {}
  local delta = (cur.startup_ms or 0) - (base.startup_ms or 0)
  if delta > STARTUP_LIMIT_MS then
    table.insert(p, string.format("startup +%.1f ms exceeds +%d ms", delta, STARTUP_LIMIT_MS))
  end
  report("startup", p, string.format("baseline %.1f ms, now %.1f ms (%+.1f)", base.startup_ms or -1, cur.startup_ms or -1, delta))
end

print("fde-ui-verify (FDE_UI=" .. (vim.env.FDE_UI or "") .. ")")
print(table.concat(results, "\n"))
print(failed and "RESULT: FAIL" or "RESULT: PASS")
os.exit(failed and 1 or 0)
