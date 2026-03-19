---@brief [[
--- Manages configuration for the Codex Neovim integration.
--- Provides default settings, validation, and application of user-defined configurations.
---@brief ]]
---@module 'codex.config'

local M = {}

M.defaults = {
  terminal_cmd = nil, -- Defaults to "codex" when unset
  env = {},
  log_level = "info",
  track_selection = false,
  focus_after_send = true,
  visual_demotion_delay_ms = 50,
  terminal = nil, -- Lazy-loaded to avoid circular dependency
}

---Validate the provided configuration table.
---@param config table
---@return boolean
function M.validate(config)
  assert(config.terminal_cmd == nil or type(config.terminal_cmd) == "string", "terminal_cmd must be nil or a string")

  assert(type(config.terminal) == "table", "terminal must be a table")

  if config.terminal.provider_opts then
    assert(type(config.terminal.provider_opts) == "table", "terminal.provider_opts must be a table")

    if config.terminal.provider_opts.external_terminal_cmd then
      local cmd_type = type(config.terminal.provider_opts.external_terminal_cmd)
      assert(
        cmd_type == "string" or cmd_type == "function",
        "terminal.provider_opts.external_terminal_cmd must be a string or function"
      )

      if cmd_type == "string" and config.terminal.provider_opts.external_terminal_cmd ~= "" then
        assert(
          config.terminal.provider_opts.external_terminal_cmd:find("%%s"),
          "terminal.provider_opts.external_terminal_cmd must contain '%s' placeholder for the Codex command"
        )
      end
    end
  end

  local valid_log_levels = { "trace", "debug", "info", "warn", "error" }
  local is_valid_log_level = false
  for _, level in ipairs(valid_log_levels) do
    if config.log_level == level then
      is_valid_log_level = true
      break
    end
  end
  assert(is_valid_log_level, "log_level must be one of: " .. table.concat(valid_log_levels, ", "))

  assert(type(config.track_selection) == "boolean", "track_selection must be a boolean")
  if config.focus_after_send ~= nil then
    assert(type(config.focus_after_send) == "boolean", "focus_after_send must be a boolean")
  end

  assert(
    type(config.visual_demotion_delay_ms) == "number" and config.visual_demotion_delay_ms >= 0,
    "visual_demotion_delay_ms must be a non-negative number"
  )

  assert(type(config.env) == "table", "env must be a table")
  for key, value in pairs(config.env) do
    assert(type(key) == "string", "env keys must be strings")
    assert(type(value) == "string", "env values must be strings")
  end

  return true
end

---Apply user configuration on top of default settings and validate the result.
---@param user_config table|nil
---@return table
function M.apply(user_config)
  local config = vim.deepcopy(M.defaults)

  if config.terminal == nil then
    local terminal_ok, terminal_module = pcall(require, "codex.terminal")
    if terminal_ok and terminal_module.defaults then
      config.terminal = terminal_module.defaults
    end
  end

  if user_config then
    if vim.tbl_deep_extend then
      config = vim.tbl_deep_extend("force", config, user_config)
    else
      for k, v in pairs(user_config) do
        config[k] = v
      end
    end
  end

  M.validate(config)

  return config
end

return M
