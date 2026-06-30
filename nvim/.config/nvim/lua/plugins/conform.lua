return {
  "stevearc/conform.nvim",
  opts = function(_, opts)
    -- Extend formatter mappings
    opts.formatters_by_ft = vim.tbl_deep_extend("force", opts.formatters_by_ft or {}, {
      python = { "ruff_format" },
      yaml = { "prettier" },
      markdown = { "prettier" },
      javascript = { "prettier" },
      typescript = { "prettier" },
      sql = { "sql-formatter" },
      toml = { "pyproject-fmt" },
    })

    opts.formatters = vim.tbl_deep_extend("force", opts.formatters or {}, {
      black = {
        command = "black",
        args = {
          "--line-length", "79",
          "--target-version", "py313",
          "-",
        },
        stdin = true,
      },

      isort = {
        command = "isort",
        args = {
          "--profile", "black",
          "--stdout",
          "--filename", "$FILENAME",
          "-",
        },
        stdin = true,
      },
    })

    -- Disable autoformat on save
    opts.format_on_save = nil
  end,
}
