-- Rust LSP: rust-analyzer. Ported from the Zed config:
--   language_servers = ["rust-analyzer"]
--   formatter = rust-analyzer (rustfmt via LSP, LazyVim format-on-save fallback)

return {
  -- treesitter for Rust and Cargo.toml (LazyVim does not include them by default)
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "rust", "ron" } },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        rust_analyzer = {
          -- use the rustup binary on PATH, not the mason copy
          mason = false,
          settings = {
            ["rust-analyzer"] = {
              -- keep check builds out of the main target dir (Zed: analyzerTargetDir)
              rust = {
                analyzerTargetDir = "target/rust-analyzer",
              },
            },
          },
        },
      },
    },
  },
}
