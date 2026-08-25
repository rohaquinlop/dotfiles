-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Helix "color-modes": cursor color per mode (catppuccin mocha palette)
local function set_cursor_hl()
  local base = "#1e1e2e"
  vim.api.nvim_set_hl(0, "HelixCursorNormal", { bg = "#cba6f7", fg = base }) -- mauve
  vim.api.nvim_set_hl(0, "HelixCursorInsert", { bg = "#a6e3a1", fg = base }) -- green
  vim.api.nvim_set_hl(0, "HelixCursorSelect", { bg = "#f9e2af", fg = base }) -- yellow
end
set_cursor_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_cursor_hl })

-- Opening a directory (e.g. `nvim .`) skips the dashboard and hands the
-- main window an empty, unnamed, listed buffer instead (neo-tree takes the
-- sidebar). Wipe leftover empty buffers once a real file buffer is entered.
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function(args)
    local bufs = vim.fn.getbufinfo({ buflisted = 1 })
    if #bufs <= 1 then
      return
    end
    for _, buf in ipairs(bufs) do
      if buf.bufnr ~= args.buf and buf.name == "" and buf.changed == 0 then
        pcall(vim.api.nvim_buf_delete, buf.bufnr, {})
      end
    end
  end,
})
