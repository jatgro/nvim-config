return {
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    config = function()
      local bg = "#011628"
      local bg_dark = "#011423"
      local bg_highlight = "#143652"
      local bg_search = "#0A64AC"
      local bg_visual = "#275378"
      local fg = "#CBE0F0"
      local fg_dark = "#B4D0E9"
      local fg_gutter = "#627E97"
      local border = "#547998"

      require("tokyonight").setup({
        style = "night",
        on_colors = function(colors)
          colors.bg = bg
          colors.bg_dark = bg_dark
          colors.bg_highlight = bg_highlight
          colors.bg_search = bg_search
          colors.bg_visual = bg_visual
          colors.fg = fg
          colors.fg_dark = fg_dark
          colors.fg_gutter = fg_gutter
          colors.border = border
        end,
      })

      --[[      vim.cmd("colorscheme tokyonight") ]]
    end,
  },
  {
    "shaunsingh/nord.nvim",
    lazy = false, -- Ensures it loads immediately
    priority = 1000,
    config = function()
      -- Configure nord.nvim if needed
      vim.g.nord_contrast = true
      vim.g.nord_borders = true
      vim.g.nord_disable_background = false
      vim.g.nord_italic = true
      vim.g.nord_uniform_diff_background = true
      vim.g.nord_bold = true

      require("nord").set()
    end,
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
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
        -- ... (rest of your catppuccin config) ...
      })

      -- Set italic for default text (not covered by syntax groups)
      vim.api.nvim_set_hl(0, "Normal", { italic = true })
      vim.api.nvim_set_hl(0, "NormalNC", { italic = true })

      vim.cmd.colorscheme("catppuccin")
    end,
  },
}
