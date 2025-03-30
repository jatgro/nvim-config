local M = {}

function M.setup()
  require("catppuccin").setup({
    flavour = "mocha",
    styles = {
      comments = { "italic" },
      conditionals = { "italic" },
      loops = { "italic" },
      functions = { "italic" },
      keywords = { "italic" },
      strings = { "italic" },
      variables = { "italic" },
      numbers = { "italic" },
      booleans = { "italic" },
      properties = { "italic" },
      types = { "italic" },
      operators = { "italic" },
    },
  })

  -- Set italic for default text
  vim.api.nvim_set_hl(0, "Normal", { italic = true })
  vim.api.nvim_set_hl(0, "NormalNC", { italic = true })

  vim.cmd.colorscheme("catppuccin")
end

return M
