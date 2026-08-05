return {
  "ThePrimeagen/git-worktree.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  keys = {
    {
      "<leader>gwl",
      function()
        require("telescope").extensions.git_worktree.git_worktrees()
      end,
      desc = "List git worktrees",
    },
    {
      "<leader>gwc",
      function()
        require("telescope").extensions.git_worktree.create_git_worktree()
      end,
      desc = "Create git worktree",
    },
  },
  config = function()
    local auto_session = require("auto-session")
    local worktree = require("git-worktree")

    local function notify_session_restore(op, metadata)
      local restored = auto_session.restore_session(nil, { show_message = false })
      local worktree_name = metadata and metadata.path and vim.fn.fnamemodify(metadata.path, ":t") or vim.fn.getcwd()

      if restored then
        vim.notify("Restored session for worktree: " .. worktree_name, vim.log.levels.INFO)
      else
        vim.notify("No saved session found for worktree: " .. worktree_name, vim.log.levels.WARN)
      end

      if op == worktree.Operations.Create then
        vim.notify("Created worktree: " .. worktree_name, vim.log.levels.INFO)
      elseif op == worktree.Operations.Switch then
        vim.notify("Switched worktree: " .. worktree_name, vim.log.levels.INFO)
      end
    end

    worktree.setup({
      -- Must be global "cd" (not "tcd"): lazygit/gitsigns/telescope resolve the
      -- repo from the global cwd, which tab-local "tcd" never changes.
      change_directory_command = "cd",
      update_on_change = true,
      update_on_change_command = "e .",
      clearjumps_on_change = true,
      autopush = false,
    })

    require("telescope").load_extension("git_worktree")

    worktree.on_tree_change(function(op, metadata)
      if op == worktree.Operations.Switch or op == worktree.Operations.Create then
        vim.schedule(function()
          notify_session_restore(op, metadata)
          pcall(vim.cmd, "silent! checktime") -- reload buffers changed on disk
          pcall(vim.cmd, "silent! NvimTreeRefresh")
          pcall(function()
            require("gitsigns").refresh()
          end)
        end)
      end
    end)
  end,
}