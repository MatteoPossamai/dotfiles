-- Run after Lazy! restore: nvim --headless '+luafile /path/to/this/file'
-- Runtime overrides only: keep normal startup from launching parallel installers.
local plugins = require("lazy.core.config").plugins
local plugin_opts = require("lazy.core.plugin").values
local function opts(name)
  return plugins[name] and plugin_opts(plugins[name], "opts", false) or {}
end

local mason_opts = vim.deepcopy(opts("mason.nvim"))
local lsp_opts = vim.deepcopy(opts("nvim-lspconfig"))
local extra_servers = vim.deepcopy(opts("mason-lspconfig.nvim").ensure_installed or {})
local ts_opts = vim.deepcopy(opts("nvim-treesitter"))
local tools = vim.deepcopy(mason_opts.ensure_installed or {})
local languages = vim.deepcopy(ts_opts.ensure_installed or {})
-- Rustaceanvim owns this server, so lspconfig correctly marks it disabled.
if plugins["rustaceanvim"] then tools[#tools + 1] = "rust-analyzer" end

plugins["mason.nvim"].config = function()
  mason_opts.ensure_installed = nil
  mason_opts.max_concurrent_installers = 1
  require("mason").setup(mason_opts)
end
for _, name in ipairs({ "nvim-lspconfig", "mason-lspconfig.nvim" }) do
  if plugins[name] then
    plugins[name].config = function() end
  end
end
plugins["nvim-treesitter"].config = function()
  ts_opts.ensure_installed = nil
  require("nvim-treesitter").setup(ts_opts)
end

local timeout = 5 * 60 * 1000
local function wait_for(description, predicate)
  assert(vim.wait(timeout, predicate, 100), "Timed out: " .. description)
end

local function remove_stale_lock(name)
  local location = require("mason-core.installer.InstallLocation").global()
  local path = location:lockfile(name)
  local file = io.open(path, "rb")
  if not file then return end
  local contents = file:read("*a")
  file:close()
  local pid = tonumber(vim.trim(contents))
  assert(pid and pid > 0 and pid % 1 == 0, "Invalid Mason lock; inspect manually: " .. path)
  local alive, kill_error, kill_code = vim.uv.kill(pid, 0)
  assert(alive == nil, "Mason install is owned by running process " .. pid .. ": " .. name)
  assert(kill_code == "ESRCH" or tostring(kill_error):find("ESRCH", 1, true),
    "Cannot determine Mason lock owner status: " .. tostring(kill_error))
  -- Do not remove a lock that changed while its owner was being checked.
  file = assert(io.open(path, "rb"))
  local current = file:read("*a")
  file:close()
  assert(current == contents, "Mason lock changed while checking: " .. path)
  assert(vim.uv.fs_unlink(path))
  print("Removed stale Mason lock: " .. name .. " (dead pid " .. pid .. ")")
end

vim.schedule(function()
  local ok, err = xpcall(function()
    require("lazy").load({ plugins = { "mason.nvim", "nvim-treesitter", "nvim-lspconfig" } })
    local registry = require("mason-registry")
    local refreshed, refresh_ok = false, false
    registry.refresh(function(success)
      refresh_ok, refreshed = success, true
    end)
    wait_for("Mason registry refresh", function() return refreshed end)
    assert(refresh_ok, "Mason registry refresh failed")

    local server_packages = {}
    for _, spec in ipairs(registry.get_all_package_specs()) do
      local server = vim.tbl_get(spec, "neovim", "lspconfig")
      if server then server_packages[server] = spec.name end
    end
    local servers = {}
    for server, config in pairs(lsp_opts.servers or {}) do
      if server ~= "*" and config and (type(config) ~= "table" or config.enabled ~= false) then
        servers[server] = type(config) == "table" and config or {}
        if servers[server].mason ~= false and server_packages[server] then
          tools[#tools + 1] = server_packages[server]
        end
      end
    end
    for _, server in ipairs(extra_servers) do
      assert(server_packages[server], "No Mason package for LSP server: " .. server)
      tools[#tools + 1] = server_packages[server]
    end
    tools = vim.fn.uniq(vim.fn.sort(tools))
    for _, name in ipairs(tools) do
      local package = registry.get_package(name)
      if package:is_installing() then
        wait_for("existing Mason install: " .. name, function() return not package:is_installing() end)
      end
      remove_stale_lock(name)
      if not package:is_installed() or vim.fn.filereadable(package:get_receipt_path()) ~= 1 then
        print("Installing Mason package: " .. name)
        local finished, succeeded, install_err = false, false, nil
        package:install({ force = package:is_installed() }, function(success, failure)
          succeeded, install_err, finished = success, failure, true
        end)
        wait_for("Mason install: " .. name, function() return finished end)
        assert(succeeded and package:is_installed(), "Mason install failed: " .. name .. ": " .. tostring(install_err))
      end
      assert(vim.fn.filereadable(package:get_receipt_path()) == 1, "Missing Mason receipt: " .. name)
      for executable in pairs(package.spec.bin or {}) do
        local path = vim.fn.stdpath("data") .. "/mason/bin/" .. executable
        assert(vim.fn.executable(path) == 1, "Missing Mason executable: " .. path)
      end
    end

    -- Registry mappings can change. Also check commands, including custom and
    -- externally managed servers, rather than silently skipping unmapped LSPs.
    for server, config in pairs(servers) do
      local defaults = vim.lsp.config[server] or {}
      local command = config.cmd or defaults.cmd
      local executable = type(command) == "table" and command[1] or command
      if type(command) == "function" then
        -- Modern configs may construct an RPC client instead of supplying argv.
        -- Mapped Mason packages have already had their receipt/binaries checked.
        if config.mason == false or not server_packages[server] or config.cmd then
          print("LSP command is a function; runtime connection not checked: " .. server)
        end
      else
        assert(type(executable) == "string", "Cannot verify LSP command for " .. server)
        assert(vim.fn.executable(executable) == 1, "Missing LSP executable for " .. server .. ": " .. executable)
      end
    end

    local treesitter = require("nvim-treesitter")
    for _, language in ipairs(languages) do
      print("Preparing Treesitter parser: " .. language)
      assert(treesitter.install({ language }, { max_jobs = 1 }):wait(timeout), "Treesitter install failed: " .. language)
    end
    print("Neovim tools and parsers ready")
  end, debug.traceback)
  if not ok then
    vim.api.nvim_err_writeln(err)
    vim.cmd("cquit 1")
  else
    vim.cmd("qa!")
  end
end)
