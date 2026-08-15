-- Show dotfiles in the file explorer by default.
-- This repo stores its configs inside .config/ dirs, so hiding dotfiles
-- makes the tree look empty.
return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        filtered_items = {
          hide_dotfiles = false,
        },
      },
    },
  },
}
