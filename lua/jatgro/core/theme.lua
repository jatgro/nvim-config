local M = {}

M.transparent = vim.g.jatgro_transparent_background ~= false

local transparent_groups = {
  "Normal",
  "NormalNC",
  "NormalFloat",
  "FloatBorder",
  "SignColumn",
  "LineNr",
  "CursorLineNr",
  "FoldColumn",
  "EndOfBuffer",
  "StatusLine",
  "StatusLineNC",
  "TabLine",
  "TabLineFill",
  "WinSeparator",
  "NvimTreeNormal",
  "NvimTreeNormalNC",
  "NvimTreeEndOfBuffer",
  "TelescopeNormal",
  "TelescopeBorder",
  "WhichKeyFloat",
  "NoiceCmdlinePopup",
  "NoiceCmdlinePopupBorder",
  "NotifyBackground",
}

local function clear_background(group)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
  if not ok then
    return
  end

  hl.bg = "NONE"
  hl.ctermbg = "NONE"
  vim.api.nvim_set_hl(0, group, hl)
end

function M.apply_transparency()
  if not M.transparent then
    return
  end

  for _, group in ipairs(transparent_groups) do
    clear_background(group)
  end
end

function M.set_transparency(enabled)
  M.transparent = enabled
  vim.g.jatgro_transparent_background = enabled
  vim.cmd.colorscheme(vim.g.colors_name or "catppuccin-mocha")
  M.apply_transparency()
end

function M.setup()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("JatgroThemeTransparency", { clear = true }),
    callback = function()
      vim.schedule(M.apply_transparency)
    end,
  })

  vim.api.nvim_create_user_command("ThemeTransparencyEnable", function()
    M.set_transparency(true)
  end, { desc = "Enable transparent theme backgrounds" })

  vim.api.nvim_create_user_command("ThemeTransparencyDisable", function()
    M.set_transparency(false)
  end, { desc = "Disable transparent theme backgrounds" })

  vim.api.nvim_create_user_command("ThemeTransparencyToggle", function()
    M.set_transparency(not M.transparent)
  end, { desc = "Toggle transparent theme backgrounds" })
end

return M
