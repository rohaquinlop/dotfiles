-- Python LSP: ty (type checker) + ruff (lint/fix) + efm (ruff formatting).
-- Ported from the Zed config:
--   language_servers = ["ty", "ruff", "!basedpyright"]
--   formatter = fixAll + organizeImports code actions, then ruff format

local augroup = vim.api.nvim_create_augroup("python-lsp", { clear = true })

-- venv detection: point ruff at the active virtualenv (ty discovers .venv itself)
local function detect_venv(buf)
  local root = vim.fs.root(buf, { ".venv", "venv", "pyproject.toml", ".git" })
  if not root then
    return
  end
  for _, venv_name in ipairs({ ".venv", "venv" }) do
    local venv_path = root .. "/" .. venv_name
    if vim.fn.isdirectory(venv_path) == 1 then
      vim.env.VIRTUAL_ENV = venv_path
      return
    end
  end
end

vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
  group = augroup,
  pattern = "*.py",
  callback = function(ev)
    detect_venv(ev.buf)
  end,
})

vim.api.nvim_create_autocmd("DirChanged", {
  group = augroup,
  callback = function(ev)
    if vim.bo[ev.buf].filetype == "python" then
      detect_venv(ev.buf)
    end
  end,
})

-- Run ruff code actions synchronously (fixAll / organizeImports).
-- Mirrors the code-action steps of Zed's Python formatter chain.
-- ruff returns unresolved actions (data only); resolve them to get the edits.
local function ruff_code_actions(buf, only)
  local clients = vim.lsp.get_clients({ bufnr = buf, name = "ruff" })
  if #clients == 0 then
    return
  end
  local params = vim.lsp.util.make_range_params(nil, "utf-8")
  params.context = { only = only, diagnostics = {} }
  local result = vim.lsp.buf_request_sync(buf, "textDocument/codeAction", params, 1000)
  if not result then
    return
  end
  for _, res in pairs(result) do
    if res.result then
      for _, action in ipairs(res.result) do
        local resolved = action
        if not resolved.edit and not resolved.command and resolved.data then
          local r = vim.lsp.buf_request_sync(buf, "codeAction/resolve", resolved, 1000)
          if r then
            for _, rr in pairs(r) do
              resolved = rr.result or resolved
            end
          end
        end
        if resolved.edit then
          local client = vim.lsp.get_client_by_id(res.client_id)
          vim.lsp.util.apply_workspace_edit(resolved.edit, client and client.offset_encoding or "utf-8")
        elseif resolved.command then
          vim.lsp.buf.execute_command(buf, resolved.command)
        end
      end
    end
  end
end

-- On save: ruff fixAll + organizeImports, then LSP format (efm) via LazyVim
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  pattern = "*.py",
  callback = function(ev)
    ruff_code_actions(ev.buf, { "source.fixAll.ruff", "source.organizeImports.ruff" })
  end,
})

-- Manual organize imports + format
vim.api.nvim_create_autocmd("LspAttach", {
  group = augroup,
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
      return
    end
    if client.name == "ty" then
      -- ty's LSP always sends "unused binding" hints (severity Hint, tag
      -- Unnecessary, no code) to every editor. Zed renders them dimmed;
      -- hide them from nvim's display by setting a WARN floor on ty's
      -- diagnostic namespace (signs, underline, virtual text, floats).
      -- Real type errors (ERROR) still show.
      local ns = require("vim.lsp.diagnostic").get_namespace(client.id)
      local sev = { min = vim.diagnostic.severity.WARN }
      local ns_cfg = {}
      local global = vim.diagnostic.config()
      for _, handler in ipairs({ "signs", "underline", "virtual_text", "float" }) do
        local base = global[handler]
        if type(base) ~= "table" then
          base = {}
        end
        ns_cfg[handler] = vim.tbl_deep_extend("force", base, { severity = sev })
      end
      vim.diagnostic.config(ns_cfg, ns)
      return
    end
    if client.name ~= "ruff" then
      return
    end
    vim.keymap.set("n", "<leader>oi", function()
      ruff_code_actions(ev.buf, { "source.organizeImports" })
      vim.lsp.buf.format({
        bufnr = ev.buf,
        filter = function(c)
          return c.name == "efm"
        end,
      })
    end, { buffer = ev.buf, desc = "Organize imports" })
  end,
})

return {
  -- efmls-configs provides the ruff formatter recipe used by efm
  {
    "creativenull/efmls-configs-nvim",
    lazy = true,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}

      -- ty: Python type checker + language services (the LSP Zed uses)
      opts.servers.ty = {
        -- system package (/usr/bin/ty), not a mason install
        mason = false,
        settings = {
          ty = {
            -- Match Zed: ty's default is openFilesOnly (checks only open
            -- files), while workspace would analyze the whole project.
            diagnosticMode = "openFilesOnly",
          },
        },
      }

      -- pyright/basedpyright: disabled, ty replaces them (Zed: "!basedpyright")
      opts.servers.pyright = { enabled = false }
      opts.servers.basedpyright = { enabled = false }

      -- ruff: line length 80, isort rules (I), syntax errors (from Zed).
      -- `select` is pinned to ruff < 0.16 defaults (E4/E7/E9/F): ruff 0.16
      -- added UP/FA rule groups to the defaults, but Zed runs the project
      -- venv's older ruff (0.15.9) and does not show those diagnostics.
      opts.servers.ruff = {
        init_options = {
          settings = {
            lineLength = 80,
            showSyntaxErrors = true,
            lint = {
              select = { "E4", "E7", "E9", "F" },
              extendSelect = { "I" },
            },
          },
        },
      }

      -- efm: ruff as the python formatter (format-on-save via LazyVim defaults)
      opts.servers.efm = {
        filetypes = { "python" },
        init_options = { documentFormatting = true },
        settings = {
          languages = {
            python = { require("efmls-configs.formatters.ruff") },
          },
        },
      }

      return opts
    end,
  },
}
