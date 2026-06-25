return {
  "meanderingprogrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you use standalone mini plugins, replace with "echasnovski/mini.nvim"
  keys = {
    { "<leader>tm", "<cmd>RenderMarkdown toggle<CR>", desc = "Toggle Markdown Render" },
  },
  opts = {},
}
