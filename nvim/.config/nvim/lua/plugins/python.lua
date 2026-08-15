-- Python LSP: ruff + pyright (with venv detection) + efm (ruff formatter).
-- Ported from the MacBook config; shared by both machines via dotfiles.

-- venv detection: point ruff/pyright at the active virtualenv
local augroup = vim.api.nvim_create_augroup("python-lsp", { clear = true })

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
    if vim.bo.filetype == "python" then
      detect_venv(ev.buf)
    end
  end,
})

-- Organize imports (isort) then format with efm (ruff)
vim.api.nvim_create_autocmd("LspAttach", {
  group = augroup,
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client or vim.bo[ev.buf].filetype ~= "python" then
      return
    end
    if client:supports_method("textDocument/codeAction", ev.buf) then
      vim.keymap.set("n", "<leader>oi", function()
        vim.lsp.buf.code_action({
          context = { only = { "source.organizeImports" }, diagnostics = {} },
          apply = true,
          bufnr = ev.buf,
        })
        vim.defer_fn(function()
          vim.lsp.buf.format({
            bufnr = ev.buf,
            filter = function(c)
              return c.name == "efm"
            end,
          })
        end, 50)
      end, { buffer = ev.buf, desc = "Organize imports" })
    end
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

      -- ruff: line length 80, isort rules (I) included in lint
      opts.servers.ruff = {
        init_options = {
          settings = {
            lineLength = 80,
            lint = {
              extendSelect = { "I" },
            },
          },
        },
      }

      -- pyright: use the detected venv python, analysis disabled (ruff handles it)
      opts.servers.pyright = {
        before_init = function(params, config)
          local root = params.rootPath
          if not root or root == "" then
            return
          end
          for _, venv_name in ipairs({ ".venv", "venv" }) do
            local venv_path = root .. "/" .. venv_name
            if vim.fn.isdirectory(venv_path) == 1 then
              local python_bin = venv_path .. "/bin/python"
              if vim.fn.executable(python_bin) == 1 then
                config.settings = config.settings or {}
                config.settings.python = config.settings.python or {}
                config.settings.python.pythonPath = python_bin
                return
              end
            end
          end
        end,
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "off",
              diagnosticMode = "off",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
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
