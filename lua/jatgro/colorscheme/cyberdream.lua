local M = {}

function M.setup()
  require("cyberdream").setup({
    transparent = require("jatgro.core.theme").transparent,
    italic_comments = true,
    hide_fillchars = true,
    borderless_telescope = true,
  })
  -- vim.cmd("colorscheme cyberdream")
end

return M
