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
