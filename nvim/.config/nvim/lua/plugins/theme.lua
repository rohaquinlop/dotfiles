-- Noctalia's community neovim template writes two files into ~/.config/nvim/
-- (outside this repo): lua/matugen.lua, a base16 palette for the active desktop
-- palette, and lua/plugins/base16.lua, which pulls in base16-nvim. When
-- matugen.lua is there the editor follows the desktop palette; without it (a
-- clone with no Noctalia, or a disabled template) plain catppuccin mocha is used.
local has_noctalia = vim.uv.fs_stat(vim.fn.stdpath("config") .. "/lua/matugen.lua") ~= nil

return {
  -- Reads the palette Noctalia writes to lua/matugen.lua. lazy/priority are
  -- required so the colorscheme is installed before LazyVim switches to it
  -- during setup; enabled=false keeps a clone without Noctalia on catppuccin.
  {
    "RRethy/base16-nvim",
    lazy = false,
    priority = 1000,
    enabled = has_noctalia,
    config = function()
      local ok, matugen = pcall(require, "matugen")
      if ok then matugen.setup() end
    end,
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      -- base16-nvim applies its palette through require(...).setup(), not
      -- through a colors/base16.vim file, so LazyVim gets a function instead of
      -- a :colorscheme name. It is a startup plugin, so it is on the runtime
      -- path by the time LazyVim runs this.
      colorscheme = has_noctalia and function()
        require("matugen").setup()
      end or "catppuccin-nvim",
    },
  },
}
