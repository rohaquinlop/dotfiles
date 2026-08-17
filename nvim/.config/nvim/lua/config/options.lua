require("config.remote_clipboard").setup()
-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
-- Helix-style options (from ~/.config/helix/config.toml)
vim.opt.relativenumber = true -- line-number = "relative"
vim.opt.mouse = "" -- mouse = false (LazyVim default is "a")
vim.opt.cursorline = true -- cursorline = true
vim.opt.colorcolumn = "80" -- rulers = [80]
-- cursor-shape: underline in every mode + color-modes (colors via HelixCursor* groups)
vim.opt.guicursor = "n:hor10-HelixCursorNormal,i:hor10-HelixCursorInsert,v:hor10-HelixCursorSelect,ve:hor10-HelixCursorSelect,o:hor10-HelixCursorNormal,r:hor10-HelixCursorInsert,c:hor10-HelixCursorNormal"

-- Zed parity: tab_size = 4, soft_wrap = "editor_width" (LazyVim defaults: 2, off)
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.wrap = true
-- Zed "TSX": tab_size = 2
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "typescriptreact" },
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
  end,
})
