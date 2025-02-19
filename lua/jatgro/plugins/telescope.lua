return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-tree/nvim-web-devicons",
    "folke/todo-comments.nvim",
    "andrew-george/telescope-themes",
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    telescope.setup({
      defaults = {
        path_display = { "smart" },
        mappings = {
          i = {
            ["<C-k>"] = actions.move_selection_previous, -- move to previous result
            ["<C-j>"] = actions.move_selection_next, -- move to next result
            ["<C-q"] = actions.send_selected_to_qflist + actions.open_qflist,
          },
        },
      },
      extensions = {
        themes = {
          layout_config = {
            horizontal = { width = 0.8, height = 0.7 },
          },
          enable_previewer = true,
          enable_live_preview = true,
          ignore = { "default", "desert", "elflord", "habamax" },
          light_themes = { ignore = false, keywords = { "light", "day", "frappe" } },
          dark_themes = { ignore = false, keywords = { "dark", "night", "black" } },
          -- persist = {
          --   enabled = true,
          --   path = vim.fn.stdpath("config") .. "/lua/jatgro/plugins/colorscheme.lua",
          -- },
        },
      },
    })

    telescope.load_extension("fzf")
    telescope.load_extension("themes")

    -- set keymaps
    local keymap = vim.keymap

    keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "Fuzzy find files in cwd" })
    keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>", { desc = "Fuzzy find recent files " })
    keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<CR>", { desc = "Find string in cwd" })
    keymap.set(
      "n",
      "<leader>fc",
      "<cmd>Telescope grep_string<CR>",
      { desc = "Find string under the cursor in the cwd" }
    )
    keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<CR>", { desc = "Find Todos" })
    -- Keybinding for theme switcher
    keymap.set("n", "<leader>th", ":Telescope themes<CR>", { noremap = true, silent = true, desc = "Theme Switcher" })
  end,
}
