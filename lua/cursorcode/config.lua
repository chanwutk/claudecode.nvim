---@brief [[
--- Manages configuration for the Cursor Code Neovim integration.
--- Provides default settings, validation, and application of user-defined configurations.
---@brief ]]
---@module 'cursorcode.config'

local M = {}

---@type table
M.defaults = {
  terminal_cmd = nil, -- Will default to "cursor" if not set
  env = {}, -- Custom environment variables for Cursor terminal
  log_level = "info",
  track_selection = true,
  -- When true, focus Cursor terminal after a successful send
  focus_after_send = false,
  visual_demotion_delay_ms = 50, -- Milliseconds to wait before demoting a visual selection
  terminal = nil, -- Will be lazy-loaded to avoid circular dependency
}

---Validates the provided configuration table.
---Throws an error if any validation fails.
---@param config table The configuration table to validate.
---@return boolean true if the configuration is valid.
function M.validate(config)
  assert(config.terminal_cmd == nil or type(config.terminal_cmd) == "string", "terminal_cmd must be nil or a string")

  -- Validate terminal config
  assert(type(config.terminal) == "table", "terminal must be a table")

  -- Validate provider_opts if present
  if config.terminal.provider_opts then
    assert(type(config.terminal.provider_opts) == "table", "terminal.provider_opts must be a table")

    -- Validate external_terminal_cmd in provider_opts
    if config.terminal.provider_opts.external_terminal_cmd then
      local cmd_type = type(config.terminal.provider_opts.external_terminal_cmd)
      assert(
        cmd_type == "string" or cmd_type == "function",
        "terminal.provider_opts.external_terminal_cmd must be a string or function"
      )
      -- Only validate %s placeholder for strings
      if cmd_type == "string" and config.terminal.provider_opts.external_terminal_cmd ~= "" then
        assert(
          config.terminal.provider_opts.external_terminal_cmd:find("%%s"),
          "terminal.provider_opts.external_terminal_cmd must contain '%s' placeholder for the Cursor command"
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

  return true
end

---Applies user configuration on top of default settings and validates the result.
---@param user_config table|nil The user-provided configuration table.
---@return table config The final, validated configuration table.
function M.apply(user_config)
  local config = vim.deepcopy(M.defaults)

  -- Lazy-load terminal defaults to avoid circular dependency
  if config.terminal == nil then
    local terminal_ok, terminal_module = pcall(require, "cursorcode.terminal")
    if terminal_ok and terminal_module.defaults then
      config.terminal = terminal_module.defaults
    end
  end

  if user_config then
    -- Use vim.tbl_deep_extend if available, otherwise simple merge
    if vim.tbl_deep_extend then
      config = vim.tbl_deep_extend("force", config, user_config)
    else
      -- Simple fallback for testing environment
      for k, v in pairs(user_config) do
        config[k] = v
      end
    end
  end

  M.validate(config)

  return config
end

return M
