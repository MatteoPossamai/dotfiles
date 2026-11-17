-- Invoke with -u debian-nvim-init.lua. Unlike :Lazy! restore, fail on task errors.
local snapshot = assert(_G.dotfiles_bootstrap_lock, "Use the Debian bootstrap init wrapper")
local expected = vim.json.decode(snapshot.contents)
local ok, err = xpcall(function()
  local lock = require("lazy.manage.lock")
  lock.lock, lock._loaded = vim.deepcopy(expected), true
  require("lazy").restore({ wait = true, show = false, concurrency = 1 })
  local config = require("lazy.core.config")
  for name, plugin in pairs(config.plugins) do
    assert(vim.fn.isdirectory(plugin.dir) == 1, "Missing plugin: " .. name)
    for _, task in ipairs(plugin._.tasks or {}) do
      assert(not task:has_errors(), "Plugin task failed: " .. name .. "/" .. task.name .. "\n" .. task:output())
    end
    if expected[name] and not plugin._.is_local then
      local result = vim.system({ "git", "-C", plugin.dir, "rev-parse", "HEAD" }, { text = true }):wait(30000)
      assert(result.code == 0, "Cannot inspect plugin commit: " .. name)
      assert(vim.trim(result.stdout) == expected[name].commit, "Plugin differs from lockfile: " .. name)
    end
  end
end, debug.traceback)

-- Lazy may rewrite the lock during first-start installation. Preserve the input.
local file = assert(io.open(snapshot.path, "wb"))
file:write(snapshot.contents)
file:close()
if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd("cquit 1")
else
  print("All plugins restored and verified against lazy-lock.json")
  vim.cmd("qa!")
end
