local plugin_manager = require('utils.plugin_manager')

local plugins = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
}

plugin_manager.setup(plugins)