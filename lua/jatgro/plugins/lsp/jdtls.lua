return {
  "mfussenegger/nvim-jdtls",
  ft = { "java" },
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function()
    local jdtls = require("jdtls")
    local cmp_nvim_lsp = require("cmp_nvim_lsp")

    local capabilities = cmp_nvim_lsp.default_capabilities()

    -- 📌 Keymap outside on_attach (Runs Java program)
    vim.api.nvim_set_keymap(
      "n",
      "<leader>rj",
      ":lua open_floating_term('javac ' .. vim.fn.expand('%') .. ' && java ' .. vim.fn.expand('%:r'))<CR>",
      { noremap = true, silent = true }
    )

    function _G.open_floating_term(command)
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = math.floor(vim.o.columns * 0.7),
        height = math.floor(vim.o.lines * 0.7),
        row = math.floor((vim.o.lines - vim.o.lines * 0.7) / 2),
        col = math.floor((vim.o.columns - vim.o.columns * 0.7) / 2),
        style = "minimal",
        border = "rounded",
      })

      vim.fn.termopen(command, {
        on_exit = function(_, code)
          if code == 0 then
            vim.notify("✅ Program completed successfully.", vim.log.levels.INFO)
          else
            vim.notify("❌ Program encountered errors. Press <Esc> to close.", vim.log.levels.ERROR)
          end
        end,
      })

      vim.cmd("startinsert") -- Start in insert mode to allow input
      vim.api.nvim_buf_set_keymap(buf, "t", "<Esc>", "<C-\\><C-n>:q<CR>", { noremap = true, silent = true })
    end

    jdtls.start_or_attach({
      cmd = {
        "java",
        "-javaagent:" .. vim.fn.stdpath("data") .. "/mason/packages/jdtls/lombok.jar",
        "-Xmx2g",
        "-jar",
        vim.fn.glob(vim.fn.stdpath("data") .. "/mason/packages/jdtls/plugins/org.eclipse.equinox.launcher_*.jar"),
        "-configuration",
        vim.fn.stdpath("data") .. "/mason/packages/jdtls/config_linux",
        "-data",
        vim.fn.stdpath("data") .. "/site/java/workspace-root/" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t"),
      },
      root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew", "build.gradle", "pom.xml" }),
      capabilities = capabilities,
      settings = {
        java = {
          configuration = {
            runtimes = {
              { name = "JavaSE-23", path = "/Library/Java/JavaVirtualMachines/openjdk-23.jdk/Contents/Home" },
            },
          },
        },
      },
      init_options = {
        extendedClientCapabilities = jdtls.extendedClientCapabilities,
      },
    })
  end,
}
