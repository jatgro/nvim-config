local M = {}

function M.setup()
  require("oasis").setup({
    style = "moonlight",
    transparent = require("jatgro.core.theme").transparent,
    terminal_colors = true,
    integrations = {
      default_enabled = true,
      plugins = {
        gitsigns = true,
        lazy = true,
        render_markdown = true,
        which_key = true,
      },
    },
  })
end

return M
