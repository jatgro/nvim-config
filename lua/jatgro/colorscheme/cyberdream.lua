local M = {}

function M.setup()
  require("cyberdream").setup({
    transparent = true,
    italic_comments = true,
    hide_fillchars = true,
    borderless_telescope = true,
  })
  -- vim.cmd("colorscheme cyberdream")
end

return M
