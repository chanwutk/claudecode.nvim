---Auto-loader for cursorcode.nvim plugin
---Runs once when Neovim starts (if plugin is in runtimepath)

-- Prevent double-loading
if vim.g.loaded_cursorcode then
  return
end

-- Require Neovim >= 0.8.0
if vim.fn.has("nvim-0.8.0") ~= 1 then
  vim.api.nvim_err_writeln("cursorcode.nvim requires Neovim >= 0.8.0")
  return
end

vim.g.loaded_cursorcode = 1

-- Auto-setup: Either with user config or defaults
-- This ensures commands are always available
vim.defer_fn(function()
  local ok, cursorcode = pcall(require, "cursorcode")
  if ok then
    -- Use user config if provided, otherwise use defaults
    local config = vim.g.cursorcode_user_config or vim.g.cursorcode_auto_setup or {}
    cursorcode.setup(config)
  else
    vim.api.nvim_err_writeln("cursorcode.nvim: failed to load module: " .. tostring(cursorcode))
  end
end, 0)
