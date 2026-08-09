-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- ══════════════════════════════════════════════════════════════════
-- Helix-style bindings (from ~/.config/helix/config.toml + Zed keymap)
-- ══════════════════════════════════════════════════════════════════

local map = vim.keymap.set

-- C-d: select current word, then extend to next occurrence (Helix C-d on macOS / Zed Cmd-d)
-- Uses `normal!` so it keeps working even though `gn` is remapped below.
map({ "n", "x" }, "<C-d>", function()
  pcall(vim.cmd, "normal! *")
  pcall(vim.cmd, "normal! gn")
end, { desc = "Helix: select next occurrence" })

-- C-j / C-k: scroll the view (Helix scroll_down / scroll_up)
map({ "n", "x" }, "<C-j>", "<C-e>", { desc = "Helix: scroll down" })
map({ "n", "x" }, "<C-k>", "<C-y>", { desc = "Helix: scroll up" })

-- A-j / A-k: move line / selection down / up (Helix A-j / A-k)
map("n", "<A-j>", "<cmd>m+1<CR>", { desc = "Helix: move line down" })
map("n", "<A-k>", "<cmd>m-2<CR>", { desc = "Helix: move line up" })
map("n", "<A-C-j>", "<cmd>m+1<CR>", { desc = "Helix: move line down" })
map("n", "<A-C-k>", "<cmd>m-2<CR>", { desc = "Helix: move line up" })
map("x", "<A-j>", ":m'>+1<CR>gv", { desc = "Helix: move selection down" })
map("x", "<A-k>", ":m-2<CR>gv", { desc = "Helix: move selection up" })

-- Helix-style file / buffer navigation (from the Zed config)
map("n", "<space>f", LazyVim.pick("files"), { desc = "Helix: find files" })
map("n", "<space>b", function()
  require("snacks").picker.buffers()
end, { desc = "Helix: buffers" })
map("n", "gn", "<cmd>bnext<CR>", { desc = "Helix: next buffer" })
map("n", "gp", "<cmd>bprev<CR>", { desc = "Helix: prev buffer" })
map("n", "gb", "<C-^>", { desc = "Helix: last buffer" })

-- LSP reference navigation (Helix/Zed ]l and [h; [h keeps LazyVim's hunk nav, so [l = prev reference)
local function goto_reference(dir)
  return function()
    if vim.fn.getloclist(0).winid == 0 then
      vim.lsp.buf.references()
      return
    end
    pcall(dir < 0 and vim.cmd.lprev or vim.cmd.lnext)
  end
end
map("n", "]l", goto_reference(1), { desc = "Helix: next reference" })
map("n", "[l", goto_reference(-1), { desc = "Helix: prev reference" })
