-- AniMotion.nvim: Helix/Kakoune-style selection-first editing.
-- Cursor is a selection: w/e/b select as you move, then c/d/y/s/r act on it.
-- Works in normal mode; keys outside the selection flow behave normally.
return {
  {
    "luiscassih/AniMotion.nvim",
    event = "VeryLazy",
    config = function()
      require("AniMotion").setup({
        mode = "helix", -- Helix word-motion semantics for w/e/b/W/E/B
        color = "Visual", -- use the theme's Visual highlight for selections
      })
    end,
  },
}
