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
local function setup_cursorcode()
  local ok, cursorcode = pcall(require, "cursorcode")
  if ok then
    -- Use user config if provided, otherwise use defaults
    local config = vim.g.cursorcode_user_config or vim.g.cursorcode_auto_setup or {}
    local setup_ok, setup_err = pcall(cursorcode.setup, config)
    if not setup_ok then
      vim.api.nvim_err_writeln("cursorcode.nvim: setup failed: " .. tostring(setup_err))
    end
  else
    vim.api.nvim_err_writeln("cursorcode.nvim: failed to load module: " .. tostring(cursorcode))
  end
end

-- Schedule setup to run after VimEnter to ensure Neovim is fully initialized
if vim.v.vim_did_enter == 1 then
  -- Neovim already started, run setup immediately
  setup_cursorcode()
else
  -- Wait for VimEnter event
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      setup_cursorcode()
    end,
    once = true,
  })
end
