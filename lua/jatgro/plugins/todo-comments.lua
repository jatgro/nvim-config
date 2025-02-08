return {
  "folke/todo-comments.nvim",
  event = {"BufReadPre", "BufNewFile"}, 
  dependencies ={
    "nvim-lua/plenary.nvim"
  },
  config = function()
    local todo_comments = require("todo-comments")
    
    -- set keymaps
    local keymap = vim.keymap -- for conciseness

    keymap.set("n", "]t",function()
      todo_comments.jump_next() 
    end, {desc ="Next Todo comments "})

    keymap.set("n", "[t",function()
      todo_comments.jump_prev() 
    end, {desc ="Previous Todo comments "})

    todo_comments.setup()
  end
}

-- some of the todo comments strings are - 
--
-- TODO 
-- HACK 
-- WARN 
-- PERF
-- NOTE 
-- TEST 
