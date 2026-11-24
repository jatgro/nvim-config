-- Driver: nvim --clean -l undo.lua <Mx>
-- Manifest: { milestone, backup_dir, files = { { path, action = "modified"|"created", backup? } } }
-- Paths may start with "$HOME/".
local HOME = assert(vim.env.HOME)
local STATE = HOME .. "/.local/state/fde-ui"

local function expand(p)
  return (p:gsub("^%$HOME", HOME))
end

local function copy(src, dst)
  local i = assert(io.open(src, "rb"))
  local data = i:read("*a")
  i:close()
  vim.fn.mkdir(vim.fn.fnamemodify(dst, ":h"), "p")
  local o = assert(io.open(dst, "wb"))
  o:write(data)
  o:close()
end

local mx = (_G.arg or {})[1]
if not mx or mx == "" then
  print("usage: fde-ui-undo <Mx>")
  os.exit(2)
end

local manifest_path = STATE .. "/manifests/" .. mx .. ".json"
local f = io.open(manifest_path, "r")
if not f then
  print("no manifest: " .. manifest_path)
  os.exit(2)
end
local manifest = vim.json.decode(f:read("*a"))
f:close()

local stamp = os.date("%Y%m%d-%H%M%S")
local removed_dir = expand(manifest.backup_dir) .. "/removed-" .. stamp
local ok_all = true

-- Reverse order so files inside created dirs are handled before the dirs.
for i = #manifest.files, 1, -1 do
  local e = manifest.files[i]
  local path = expand(e.path)
  if e.action == "modified" then
    local ok, err = pcall(copy, expand(e.backup), path)
    print((ok and "restored  " or "FAILED    ") .. e.path .. (ok and "" or (" " .. tostring(err))))
    ok_all = ok_all and ok
  elseif e.action == "created" then
    if vim.uv.fs_stat(path) then
      local dst = removed_dir .. "/" .. path:gsub("^" .. vim.pesc(HOME) .. "/", ""):gsub("/", "%%")
      vim.fn.mkdir(removed_dir, "p")
      local ok, err = os.rename(path, dst)
      print((ok and "moved     " or "FAILED    ") .. e.path .. (ok and (" -> " .. dst) or (" " .. tostring(err))))
      ok_all = ok_all and ok ~= nil
    else
      print("absent    " .. e.path)
    end
  end
end

if ok_all then
  os.rename(manifest_path, STATE .. "/manifests/" .. mx .. ".undone-" .. stamp .. ".json")
  print("undo " .. mx .. ": OK")
  os.exit(0)
end
print("undo " .. mx .. ": INCOMPLETE")
os.exit(1)
