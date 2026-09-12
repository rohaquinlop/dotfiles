return {
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
      colorscheme = "catppuccin-nvim",
    },
  },
}
