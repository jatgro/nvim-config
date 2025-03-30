return {
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    config = function()
      require("jatgro.colorscheme.tokyonight").setup()
    end,
  },
  {
    "shaunsingh/nord.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("jatgro.colorscheme.nord").setup()
    end,
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("jatgro.colorscheme.catppuccin").setup()
    end,
  },
}
