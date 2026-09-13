-- Noctalia's community neovim template writes two files into ~/.config/nvim/
-- (outside this repo): lua/matugen.lua, a base16 palette for the active desktop
-- palette, and lua/plugins/base16.lua, which pulls in base16-nvim. When
-- matugen.lua is there the editor follows the desktop palette; without it (a
-- clone with no Noctalia, or a disabled template) the catppuccin overrides below
-- keep the Akane look.
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
    opts = {
      flavour = "mocha",
      -- Akane palette (https://github.com/Grenish/omarchy-akane-theme) mapped
      -- onto catppuccin's names, so LazyVim keeps its structure but wears the
      -- theme. Same mapping as the starship "akane" palette.
      color_overrides = {
        mocha = {
          rosewater = "#f7e0cc",
          flamingo = "#e07a94",
          pink = "#c45c78",
          mauve = "#e15a48",
          red = "#d6453d",
          maroon = "#6b3a2a",
          peach = "#e87a42",
          yellow = "#f0b45a",
          green = "#7e9a6a",
          teal = "#4a9bb0",
          sky = "#7ec4d2",
          sapphire = "#7a9cc4",
          blue = "#5b7fa8",
          lavender = "#f3d0b8",
          text = "#f0c4a8",
          subtext1 = "#f3d0b8",
          subtext0 = "#8a6e6c",
          overlay2 = "#8a6e6c",
          overlay1 = "#8a6e6c",
          overlay0 = "#6d5a68",
          surface2 = "#2c2438",
          surface1 = "#2c2438",
          surface0 = "#221c2c",
          base = "#12101c",
          mantle = "#0c0a14",
          crust = "#08070e",
        },
      },
    },
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
