local function chat()
  return require("CopilotChat")
end

return {
  {
    "github/copilot.vim",
    cmd = "Copilot",
    event = "InsertEnter",
    keys = {
      { "<leader>cs", "<cmd>Copilot status<cr>", desc = "Copilot: Status" },
      { "<leader>ce", "<cmd>Copilot enable<cr>", desc = "Copilot: Enable" },
      { "<leader>cd", "<cmd>Copilot disable<cr>", desc = "Copilot: Disable" },
    },
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = function()
      local username = vim.env.USER or "User"
      username = username:sub(1, 1):upper() .. username:sub(2)

      return {
        auto_insert_mode = true,
        trusted_tools = nil,
        headers = {
          user = " " .. username .. " ",
          assistant = " Copilot ",
          tool = "󰽢 Tool ",
        },
        window = {
          layout = "vertical",
          width = 0.4,
        },
      }
    end,
    keys = {
      {
        "<leader>cc",
        function()
          chat().toggle()
        end,
        desc = "Copilot Chat: Toggle",
        mode = { "n", "x" },
      },
      {
        "<leader>cq",
        function()
          vim.ui.input({ prompt = "Ask Copilot: " }, function(input)
            if input and input ~= "" then
              chat().ask(input)
            end
          end)
        end,
        desc = "Copilot Chat: Quick Ask",
      },
      {
        "<leader>cp",
        function()
          chat().select_prompt()
        end,
        desc = "Copilot Chat: Prompt Actions",
        mode = { "n", "x" },
      },
      {
        "<leader>cm",
        function()
          chat().select_model()
        end,
        desc = "Copilot Chat: Select Model",
      },
      {
        "<leader>cr",
        function()
          chat().reset()
        end,
        desc = "Copilot Chat: Reset",
      },
    },
    config = function(_, opts)
      local group = vim.api.nvim_create_augroup("CopilotChatUI", { clear = true })

      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "copilot-chat",
        callback = function()
          vim.opt_local.number = false
          vim.opt_local.relativenumber = false
        end,
      })

      chat().setup(opts)
    end,
  },
}
