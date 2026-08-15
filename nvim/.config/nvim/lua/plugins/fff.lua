-- fff.nvim: Rust-based fuzzy finder (ported from the MacBook config).
-- The Rust binary is built/downloaded once at install time. The .dylib/.so
-- guard avoids rebuilding on every startup and works on both macOS and Linux.
return {
  {
    "dmtrKovalenko/fff.nvim",
    keys = {
      { "<leader>ff", function() require("fff").find_files() end, desc = "Find files" },
      { "<leader>fg", function() require("fff").live_grep() end, desc = "Live grep" },
    },
    config = function()
      require("fff").setup({})
    end,
    build = function()
      local plugin_dir = vim.fn.stdpath("data") .. "/lazy/fff.nvim"
      local ext = vim.fn.has("mac") == 1 and ".dylib" or ".so"
      local lib = plugin_dir .. "/target/release/libfff_nvim" .. ext
      if vim.fn.filereadable(lib) == 0 then
        require("fff.download").download_or_build_binary()
      end
    end,
  },
}
