return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ruff_lsp = false,
        ruff = false,
        pyright = {},
        postgres_lsp = {
          cmd = { "postgres_lsp" },
          filetypes = { "sql", "postgres" },
        }
      },
    },
  },
}

