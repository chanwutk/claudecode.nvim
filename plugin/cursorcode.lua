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

-- Auto-setup if requested
if vim.g.cursorcode_auto_setup then
  local ok, cursorcode = pcall(require, "cursorcode")
  if ok then
    cursorcode.setup(vim.g.cursorcode_user_config or {})
  else
    vim.api.nvim_err_writeln("cursorcode.nvim: failed to load module: " .. tostring(cursorcode))
  end
end
