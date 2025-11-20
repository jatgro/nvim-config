-- Colorscheme picker utility
local M = {}

-- Available colorschemes with their variants
M.colorschemes = {
  { name = "catppuccin-latte", display = "Catppuccin Latte (Light)" },
  { name = "catppuccin-frappe", display = "Catppuccin Frappe (Dark)" },
  { name = "catppuccin-macchiato", display = "Catppuccin Macchiato (Dark)" },
  { name = "catppuccin-mocha", display = "Catppuccin Mocha (Dark)" },
  { name = "tokyonight", display = "Tokyo Night" },
  { name = "tokyonight-night", display = "Tokyo Night - Night" },
  { name = "tokyonight-storm", display = "Tokyo Night - Storm" },
  { name = "tokyonight-day", display = "Tokyo Night - Day" },
  { name = "tokyonight-moon", display = "Tokyo Night - Moon" },
  { name = "nord", display = "Nord" },
  { name = "nightfox", display = "Nightfox" },
  { name = "duskfox", display = "Duskfox" },
  { name = "nordfox", display = "Nordfox" },
  { name = "terafox", display = "Terafox" },
  { name = "carbonfox", display = "Carbonfox" },
  { name = "onedark", display = "One Dark" },
  { name = "onedark_vivid", display = "One Dark Vivid" },
  { name = "onedark_dark", display = "One Dark Dark" },
  { name = "cyberdream", display = "Cyberdream" },
}

-- Path to store the current theme
M.theme_file = vim.fn.stdpath("config") .. "/lua/current-theme.lua"

-- Apply a colorscheme
function M.apply_colorscheme(colorscheme_name)
  local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme_name)
  if not status_ok then
    vim.notify("Colorscheme " .. colorscheme_name .. " not found!", vim.log.levels.ERROR)
    return false
  end
  return true
end

-- Save the current colorscheme to file
function M.save_colorscheme(colorscheme_name)
  local file = io.open(M.theme_file, "w")
  if file then
    file:write('vim.cmd("colorscheme ' .. colorscheme_name .. '")\n')
    file:close()
    vim.notify("Colorscheme saved: " .. colorscheme_name, vim.log.levels.INFO)
  else
    vim.notify("Failed to save colorscheme", vim.log.levels.ERROR)
  end
end

-- Set and save a colorscheme
function M.set_colorscheme(colorscheme_name)
  if M.apply_colorscheme(colorscheme_name) then
    M.save_colorscheme(colorscheme_name)
  end
end

-- Interactive colorscheme picker using vim.ui.select
function M.pick_colorscheme()
  vim.ui.select(M.colorschemes, {
    prompt = "Select a colorscheme:",
    format_item = function(item)
      return item.display
    end,
  }, function(choice)
    if choice then
      M.set_colorscheme(choice.name)
    end
  end)
end

-- Cycle through colorschemes
function M.cycle_colorscheme(direction)
  direction = direction or 1
  local current = vim.g.colors_name
  local current_index = 1

  -- Find current colorscheme index
  for i, scheme in ipairs(M.colorschemes) do
    if scheme.name == current then
      current_index = i
      break
    end
  end

  -- Calculate next index
  local next_index = current_index + direction
  if next_index > #M.colorschemes then
    next_index = 1
  elseif next_index < 1 then
    next_index = #M.colorschemes
  end

  -- Apply next colorscheme
  M.set_colorscheme(M.colorschemes[next_index].name)
end

-- Setup function to create commands and keymaps
function M.setup()
  -- Create user commands
  vim.api.nvim_create_user_command("ColorschemeSelect", function()
    M.pick_colorscheme()
  end, { desc = "Select a colorscheme" })

  vim.api.nvim_create_user_command("ColorschemeNext", function()
    M.cycle_colorscheme(1)
  end, { desc = "Next colorscheme" })

  vim.api.nvim_create_user_command("ColorschemePrev", function()
    M.cycle_colorscheme(-1)
  end, { desc = "Previous colorscheme" })

  -- Keymaps
  vim.keymap.set("n", "<leader>tc", M.pick_colorscheme, { desc = "Choose colorscheme" })
  vim.keymap.set("n", "<leader>tn", function() M.cycle_colorscheme(1) end, { desc = "Next colorscheme" })
  vim.keymap.set("n", "<leader>tp", function() M.cycle_colorscheme(-1) end, { desc = "Previous colorscheme" })
end

return M
