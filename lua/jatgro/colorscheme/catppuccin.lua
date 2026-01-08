local M = {}

function M.setup()
  require("catppuccin").setup({
    flavour = "auto", -- Let Catppuccin auto-detect or set manually
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
    integrations = {
      telescope = {
        enabled = true,
      },
      alpha = true,
      gitsigns = true,
      nvimtree = true,
      treesitter = true,
      notify = true,
      mini = {
        enabled = true,
      },
    },
  })

  -- Set italic for default text
  vim.api.nvim_set_hl(0, "Normal", { italic = true })
  vim.api.nvim_set_hl(0, "NormalNC", { italic = true })
end

return M