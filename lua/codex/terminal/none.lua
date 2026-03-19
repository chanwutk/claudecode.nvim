--- No-op terminal provider for Codex.
--- Performs zero UI actions and never manages terminals inside Neovim.
---@module 'codex.terminal.none'

local M = {}

---@param term_config table
function M.setup(term_config)
  -- intentionally no-op
end

---@param cmd_string string
---@param env_table table
---@param effective_config table
---@param focus boolean|nil
function M.open(cmd_string, env_table, effective_config, focus)
  -- intentionally no-op
end

function M.close()
  -- intentionally no-op
end

---@param cmd_string string
---@param env_table table
---@param effective_config table
function M.simple_toggle(cmd_string, env_table, effective_config)
  -- intentionally no-op
end

---@param cmd_string string
---@param env_table table
---@param effective_config table
function M.focus_toggle(cmd_string, env_table, effective_config)
  -- intentionally no-op
end

---@param cmd_string string
---@param env_table table
---@param effective_config table
function M.toggle(cmd_string, env_table, effective_config)
  -- intentionally no-op
end

function M.ensure_visible() end

---@return number|nil
function M.get_active_bufnr()
  return nil
end

---@return boolean
function M.is_available()
  return true
end

---@return table|nil
function M._get_terminal_for_test()
  return nil
end

return M
