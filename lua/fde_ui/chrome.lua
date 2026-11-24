local M = {}
local symbols = {}

local function contains(range, line, column)
  if not range then return false end
  local start, finish = range.start, range["end"]
  return start and finish
    and (line > start.line or (line == start.line and column >= start.character))
    and (line < finish.line or (line == finish.line and column < finish.character))
end

local function symbol_path(items, line, column)
  for _, item in ipairs(items or {}) do
    local range = item.range or (item.location and item.location.range)
    if contains(range, line, column) then
      local nested = symbol_path(item.children, line, column)
      return item.name .. (nested ~= "" and " > " .. nested or "")
    end
  end
  return ""
end

local function refresh_symbols(buffer)
  if not vim.api.nvim_buf_is_valid(buffer) or vim.bo[buffer].buftype ~= "" then return end
  local clients = vim.lsp.get_clients({ bufnr = buffer, method = "textDocument/documentSymbol" })
  if #clients == 0 then return end
  local params = { textDocument = { uri = vim.uri_from_bufnr(buffer) } }
  clients[1]:request("textDocument/documentSymbol", params, function(err, result)
    if err or not vim.api.nvim_buf_is_valid(buffer) then return end
    symbols[buffer] = result or {}
    vim.cmd.redrawstatus()
  end, buffer)
end

local function file_label(buffer)
  if vim.bo[buffer].buftype == "terminal" then return "TERMINAL" end
  if vim.bo[buffer].filetype == "NvimTree" then return "EXPLORER" end
  local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buffer), ":t")
  if filename == "" then return "" end
  local icon = require("nvim-web-devicons").get_icon(filename, nil, { default = true })
  return (icon and icon .. "  " or "") .. filename
end

function M.winbar()
  local window = vim.g.statusline_winid or vim.api.nvim_get_current_win()
  local buffer = vim.api.nvim_win_get_buf(window)
  local label = file_label(buffer):gsub("%%", "%%%%")
  if label == "" then return "" end
  local cursor = vim.api.nvim_win_get_cursor(window)
  local breadcrumb = symbol_path(symbols[buffer], cursor[1] - 1, cursor[2]):gsub("%%", "%%%%")
  return "%#FdeUiAccent# " .. label .. " %*"
    .. (breadcrumb ~= "" and ("%#FdeUiMuted#  " .. breadcrumb .. " %*") or "")
end

function M.setup()
  vim.o.winbar = "%!v:lua.require'fde_ui.chrome'.winbar()"
  vim.opt.fillchars:append({ vert = "│" })
  local lualine = require("lualine")
  local status = lualine.get_config()
  status.options.section_separators = { left = "", right = "" }
  status.sections.lualine_b = { "branch", "diff" }
  status.sections.lualine_c = { "filename", "diagnostics" }
  lualine.setup(status)

  local tabs = require("bufferline.config").get()
  tabs.options.separator_style = "thin"
  require("bufferline").setup(tabs)

  vim.api.nvim_create_autocmd({ "LspAttach", "BufEnter", "BufWritePost" }, {
    group = vim.api.nvim_create_augroup("FdeUiBreadcrumbs", { clear = true }),
    callback = function(event) refresh_symbols(event.buf) end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = "FdeUiBreadcrumbs",
    callback = function(event) symbols[event.buf] = nil end,
  })
end

return M