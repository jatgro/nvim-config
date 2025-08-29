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
  {
    "EdenEast/nightfox.nvim",
    priority = 1000,
    config = function()
      require("jatgro.colorscheme.nightfox").setup()
    end,
  },
  {
    "olimorris/onedarkpro.nvim",
    priority = 1000, -- Ensure it loads first
  },
  {
    "scottmckendry/cyberdream.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("jatgro.colorscheme.cyberdream").setup()
    end,
  },
}
