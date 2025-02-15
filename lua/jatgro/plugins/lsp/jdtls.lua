return {
  "mfussenegger/nvim-jdtls", -- Plugin for Java LSP (JDTLS)
  ft = { "java" }, -- Activate only for Java files
  dependencies = { -- Dependencies required
    "williamboman/mason.nvim", -- Manages LSP installations
    "williamboman/mason-lspconfig.nvim",
    "hrsh7th/cmp-nvim-lsp", -- Completion support for LSP
  },
  config = function()
    local jdtls = require("jdtls")
    local cmp_nvim_lsp = require("cmp_nvim_lsp")

    local capabilities = cmp_nvim_lsp.default_capabilities()
    local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
    local workspace_dir = vim.fn.stdpath("data") .. "/site/java/workspace-root/" .. project_name
    local jdtls_path = vim.fn.stdpath("data") .. "/mason/packages/jdtls"
    local lombok_path = jdtls_path .. "/lombok.jar"
    local jar_path = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")

    local cmd = {
      "java",
      "-javaagent:" .. lombok_path,
      "-Xmx2g",
      "-jar",
      jar_path,
      "-configuration",
      jdtls_path .. "/config_linux",
      "-data",
      workspace_dir,
    }

    jdtls.start_or_attach({
      cmd = cmd,
      root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew", "build.gradle", "pom.xml" }),
      capabilities = capabilities,
      on_attach = function(_, bufnr)
        local opts = { buffer = bufnr, silent = true }
        -- vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
        -- vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        -- vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
        vim.api.nvim_set_keymap("n", "<leader>rj", ":!javac % && java %:r<CR>", { noremap = true, silent = true })
      end,
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
