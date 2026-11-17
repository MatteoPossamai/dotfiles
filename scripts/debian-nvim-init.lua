-- Bootstrap-only init: serialize work without changing the normal editor config.
-- Clone lazy.nvim into this directory before invoking Neovim with -u this file.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
assert(vim.fn.isdirectory(lazypath) == 1, "Clone lazy.nvim before running the Debian bootstrap")
vim.opt.rtp:prepend(lazypath)
local lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json"
local file = assert(io.open(lockfile, "rb"))
_G.dotfiles_bootstrap_lock = { path = lockfile, contents = file:read("*a") }
file:close()

local lazy = require("lazy")
local setup = lazy.setup
lazy.setup = function(spec, options)
  local config
  if type(spec) == "table" and spec.spec then
    config = spec
  else
    config = options or {}
    config.spec = spec
  end
  config.concurrency = 1
  config.checker = { enabled = false }
  -- Mason can also be loaded by plugin build hooks during Lazy restore.
  config.spec[#config.spec + 1] = {
    "mason-org/mason.nvim",
    opts = { max_concurrent_installers = 1 },
  }
  -- The pinned Treesitter defaults to 100 simultaneous parser jobs. The tools
  -- helper installs these explicitly with max_jobs=1 after plugin restoration.
  config.spec[#config.spec + 1] = {
    "nvim-treesitter/nvim-treesitter",
    build = false,
    config = function(_, opts)
      require("nvim-treesitter").setup(opts)
    end,
  }
  return setup(config)
end

dofile(vim.fn.stdpath("config") .. "/init.lua")
