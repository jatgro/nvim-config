local M = {}

function M.enabled()
  return vim.g.fde_ui ~= false and vim.env.FDE_UI ~= "0"
end

if not M.enabled() then
  return M
end

require("fde_ui.palette").setup()
require("fde_ui.chrome").setup()

return M
