--       { "<leader>cc", "<cmd>CopilotChat<cr>", desc = "CopilotChat: Open" },
--       {
--         "<leader>ccq",
--         function()
--           local input = vim.fn.input("Quick Chat: ")
--           if input ~= "" then
--             require("CopilotChat").ask(input, { selection = require("CopilotChat.select").buffer })
--           end
--         end,
--         desc = "CopilotChat: Quick chat (buffer)",
--         mode = "n",
--       },
--     },
--   },
-- }
--
--
--
-- lua/plugins/copilot_chat_lazyvim_style.lua
return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = function()
      local user = (vim.env.USER or "User")
      user = user:sub(1, 1):upper() .. user:sub(2)
      return {
        auto_insert_mode = true,
        headers = {
          user = " " .. user .. " ",
          assistant = " Copilot ",
          tool = "󱍢 Tool ",
        },
        window = { width = 0.4 },
      }
    end,
    keys = {
      {
        "<leader>cc",
        function()
          require("CopilotChat").toggle()
        end,
        desc = "CopilotChat: Toggle",
        mode = { "n", "x" },
      },
      {
        "<leader>cx",
        function()
          require("CopilotChat").reset()
        end,
        desc = "CopilotChat: Clear",
        mode = { "n", "x" },
      },
      {
        "<leader>ccq",
        function()
          vim.ui.input({ prompt = "Quick Chat: " }, function(input)
            if input and input ~= "" then
              require("CopilotChat").ask(input)
            end
          end)
        end,
        desc = "CopilotChat: Quick Chat",
        mode = { "n", "x" },
      },
      {
        "<leader>cp",
        function()
          require("CopilotChat").select_prompt()
        end,
        desc = "CopilotChat: Prompt Actions",
        mode = { "n", "x" },
      },
    },
    config = function(_, opts)
      local chat = require("CopilotChat")
      -- Make chat buffer clean (no line numbers)
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "copilot-chat",
        callback = function()
          vim.opt_local.relativenumber = false
          vim.opt_local.number = false
        end,
      })
      chat.setup(opts)
    end,
  },
}
