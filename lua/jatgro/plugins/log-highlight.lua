return {
  {
    "fei6409/log-highlight.nvim",
    lazy = false,
    opts = {
      extension = { "log", "out", "err" },
      filename = {
        "syslog",
      },
      pattern = {
        "log.*%.txt",
        "logcat.*",
        ".*%.log%..*",
      },
    },
  },
}
