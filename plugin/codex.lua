--- Auto-loader for codex.nvim
--- Runs once when Neovim starts (if plugin is in runtimepath)

if vim.g.loaded_codex then
  return
end

if vim.fn.has("nvim-0.8.0") ~= 1 then
  vim.api.nvim_err_writeln("codex.nvim requires Neovim >= 0.8.0")
  return
end

vim.g.loaded_codex = 1

local function setup_codex()
  local ok, codex = pcall(require, "codex")
  if ok then
    local config = vim.g.codex_user_config or vim.g.codex_auto_setup or {}
    local setup_ok, setup_err = pcall(codex.setup, config)
    if not setup_ok then
      vim.api.nvim_err_writeln("codex.nvim: setup failed: " .. tostring(setup_err))
    end
  else
    vim.api.nvim_err_writeln("codex.nvim: failed to load module: " .. tostring(codex))
  end
end

if vim.v.vim_did_enter == 1 then
  setup_codex()
else
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      setup_codex()
    end,
    once = true,
  })
end
