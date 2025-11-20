return {
  "benlubas/molten-nvim",
  version = "^1.0.0",
  dependencies = { "nvim-lua/plenary.nvim" },
  lazy = false, -- Load immediately to ensure commands are available
  build = ":UpdateRemotePlugins",
  init = function()
    -- Molten configuration (set before plugin loads)
    vim.g.molten_auto_open_output = false
    vim.g.molten_image_provider = "none" -- Use "image.nvim" if you have it installed
    vim.g.molten_output_win_max_height = 20
    vim.g.molten_virt_text_output = true
    vim.g.molten_virt_lines_off_by_1 = true
  end,
  config = function()
    -- Set keymaps
    local keymap = vim.keymap

    -- Initialize the kernel for the current buffer
    keymap.set("n", "<leader>mi", ":MoltenInit<CR>", { desc = "Molten - Initialize Kernel", silent = true })

    -- Evaluate operator (like running a motion)
    keymap.set("n", "<leader>me", ":MoltenEvaluateOperator<CR>", { desc = "Molten - Evaluate Operator", silent = true })

    -- Run the current line
    keymap.set("n", "<leader>ml", ":MoltenEvaluateLine<CR>", { desc = "Molten - Run Line", silent = true })

    -- Re-evaluate the current cell
    keymap.set("n", "<leader>mr", ":MoltenReevaluateCell<CR>", { desc = "Molten - Re-run Cell", silent = true })

    -- Run the current visual selection
    keymap.set("v", "<leader>mr", ":<C-u>MoltenEvaluateVisual<CR>gv", { desc = "Molten - Run Selection", silent = true })

    -- Delete the current cell output
    keymap.set("n", "<leader>md", ":MoltenDelete<CR>", { desc = "Molten - Delete Cell", silent = true })

    -- Show/Hide output
    keymap.set("n", "<leader>mo", ":noautocmd MoltenEnterOutput<CR>", { desc = "Molten - Show Output", silent = true })

    -- Hide output window
    keymap.set("n", "<leader>mh", ":MoltenHideOutput<CR>", { desc = "Molten - Hide Output", silent = true })

    -- Interrupt the kernel
    keymap.set("n", "<leader>mx", ":MoltenInterrupt<CR>", { desc = "Molten - Interrupt Kernel", silent = true })
  end,
}