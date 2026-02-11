---@brief [[
--- Cursor Code Neovim Integration
--- This plugin integrates Cursor CLI with Neovim, enabling
--- seamless AI-assisted coding directly in Neovim.
--- Works alongside the claudecode.nvim plugin.
---@brief ]]

---@module 'cursorcode'
local M = {}

local logger = require("cursorcode.logger")

--- Current plugin version
---@type table
M.version = {
  major = 1,
  minor = 0,
  patch = 0,
  prerelease = nil,
  string = function(self)
    local version = string.format("%d.%d.%d", self.major, self.minor, self.patch)
    if self.prerelease then
      version = version .. "-" .. self.prerelease
    end
    return version
  end,
}

-- Module state
---@type table
M.state = {
  config = require("cursorcode.config").defaults,
  initialized = false,
}

---Format a file path for @ mention in cursor
---@param file_path string The absolute file path
---@return string formatted_path The formatted relative path
---@return boolean is_directory Whether the path is a directory
function M._format_path_for_at_mention(file_path)
  if not file_path or file_path == "" then
    error("File path cannot be empty")
  end

  -- Expand the path to get absolute path
  local expanded_path = vim.fn.expand(file_path)
  if expanded_path == "" then
    error("Failed to expand file path: " .. file_path)
  end

  -- Check if file or directory exists
  local is_file = vim.fn.filereadable(expanded_path) == 1
  local is_dir = vim.fn.isdirectory(expanded_path) == 1

  if not is_file and not is_dir then
    error("File or directory does not exist: " .. expanded_path)
  end

  local is_directory = is_dir
  local formatted_path = expanded_path

  -- Try to make path relative to cwd
  if is_directory then
    -- Ensure trailing slash for directories
    if not string.match(formatted_path, "/$") then
      formatted_path = formatted_path .. "/"
    end
  else
    local cwd = vim.fn.getcwd()
    if string.find(file_path, cwd, 1, true) == 1 then
      local relative_path = string.sub(file_path, #cwd + 2)
      if relative_path ~= "" then
        formatted_path = relative_path
      end
    end
  end

  return formatted_path, is_directory
end

---Send @ mention to Cursor CLI
---@param file_path string The file path to send
---@param start_line number|nil Start line (0-indexed internally, will be converted to 1-indexed)
---@param end_line number|nil End line (0-indexed internally, will be converted to 1-indexed)
---@return boolean success Whether the operation was successful
---@return string|nil error Error message if failed
function M._send_at_mention(file_path, start_line, end_line)
  -- Format the path
  local formatted_path, is_directory
  local format_success, format_result, is_dir_result = pcall(M._format_path_for_at_mention, file_path)
  if not format_success then
    return false, format_result
  end
  formatted_path, is_directory = format_result, is_dir_result

  if is_directory and (start_line or end_line) then
    logger.debug("command", "Line numbers ignored for directory: " .. formatted_path)
    start_line = nil
    end_line = nil
  end

  -- Format the @mention text for cursor-cli
  local mention_text
  if start_line and end_line then
    -- Convert from 0-indexed (internal) to 1-indexed (display)
    local display_start = start_line + 1
    local display_end = end_line + 1
    mention_text = string.format("@%s:%d-%d", formatted_path, display_start, display_end)
  else
    mention_text = string.format("@%s", formatted_path)
  end

  -- Send the text directly to the cursor terminal
  local terminal = require("cursorcode.terminal")
  local send_success = terminal.send_keys(mention_text .. " ")

  if send_success then
    logger.debug("command", "Sent @mention to cursor: " .. mention_text)
    return true, nil
  else
    local error_msg = "Failed to send @mention to cursor terminal: " .. mention_text
    logger.error("command", error_msg)
    return false, error_msg
  end
end

---Send @ mention to Cursor CLI, handling terminal state automatically
---@param file_path string The file path to send
---@param start_line number|nil Start line (0-indexed internally)
---@param end_line number|nil End line (0-indexed internally)
---@param context string|nil Context for logging
---@return boolean success Whether the operation was successful
---@return string|nil error Error message if failed
function M.send_at_mention(file_path, start_line, end_line, context)
  context = context or "command"

  local terminal = require("cursorcode.terminal")

  -- Check if terminal is active
  local bufnr = terminal.get_active_terminal_bufnr()

  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    -- Terminal exists, send the @mention directly
    local success, error_msg = M._send_at_mention(file_path, start_line, end_line)
    if success then
      if M.state.config and M.state.config.focus_after_send then
        terminal.open()
      else
        terminal.ensure_visible()
      end
    end
    return success, error_msg
  else
    -- Terminal doesn't exist, open it first then send
    terminal.open()

    -- Wait a moment for terminal to be ready, then send the @mention
    vim.defer_fn(function()
      local success, error_msg = M._send_at_mention(file_path, start_line, end_line)
      if not success then
        logger.error(context, "Failed to send @mention after opening terminal: " .. (error_msg or "unknown error"))
      end
    end, 500) -- 500ms delay to let terminal initialize

    logger.debug(context, "Opened Cursor terminal and queued @mention: " .. file_path)
    return true, nil
  end
end

---Set up the plugin with user configuration
---@param opts table|nil Optional configuration table to override defaults
---@return table module The plugin module
function M.setup(opts)
  opts = opts or {}

  local config = require("cursorcode.config")
  M.state.config = config.apply(opts)

  logger.setup(M.state.config)

  -- Setup terminal module
  do
    local t = opts.terminal or {}
    local had_alias = false
    if opts.git_repo_cwd ~= nil then
      t.git_repo_cwd = opts.git_repo_cwd
      had_alias = true
    end
    if opts.cwd ~= nil then
      t.cwd = opts.cwd
      had_alias = true
    end
    if opts.cwd_provider ~= nil then
      t.cwd_provider = opts.cwd_provider
      had_alias = true
    end
    if had_alias then
      opts.terminal = t
    end
  end

  local terminal_setup_ok, terminal_module = pcall(require, "cursorcode.terminal")
  if terminal_setup_ok then
    if type(terminal_module.setup) == "function" then
      terminal_module.setup(opts.terminal, M.state.config.terminal_cmd, M.state.config.env)
    end
  end

  -- Setup selection tracking if enabled
  if M.state.config.track_selection then
    local selection_ok, selection_module = pcall(require, "cursorcode.selection")
    if selection_ok and type(selection_module.setup) == "function" then
      selection_module.setup(M.state.config)
    end
  end

  -- Create commands
  M._create_commands()

  M.state.initialized = true
  return M
end

---Create user commands for the plugin
function M._create_commands()
  -- Toggle cursor terminal
  vim.api.nvim_create_user_command("CursorCode", function(opts)
    local terminal = require("cursorcode.terminal")
    local cmd_args = opts.args ~= "" and opts.args or nil
    terminal.focus_toggle(nil, cmd_args)
  end, {
    desc = "Toggle Cursor Code terminal",
    nargs = "?",
  })

  -- Open cursor terminal
  vim.api.nvim_create_user_command("CursorCodeOpen", function(opts)
    local terminal = require("cursorcode.terminal")
    local cmd_args = opts.args ~= "" and opts.args or nil
    terminal.open(nil, cmd_args)
  end, {
    desc = "Open Cursor Code terminal",
    nargs = "?",
  })

  -- Close cursor terminal
  vim.api.nvim_create_user_command("CursorCodeClose", function()
    local terminal = require("cursorcode.terminal")
    terminal.close()
  end, {
    desc = "Close Cursor Code terminal",
  })

  -- Focus cursor terminal
  vim.api.nvim_create_user_command("CursorCodeFocus", function(opts)
    local terminal = require("cursorcode.terminal")
    local cmd_args = opts.args ~= "" and opts.args or nil
    terminal.focus_toggle(nil, cmd_args)
  end, {
    desc = "Focus/toggle Cursor Code terminal",
    nargs = "?",
  })

  -- Add file to cursor context
  vim.api.nvim_create_user_command("CursorCodeAdd", function(opts)
    local args = vim.split(opts.args, "%s+")
    local file_path = args[1]

    if not file_path or file_path == "" then
      logger.warn("command", "CursorCodeAdd: No file path provided")
      return
    end

    -- Parse optional line range
    local start_line = args[2] and tonumber(args[2]) or nil
    local end_line = args[3] and tonumber(args[3]) or nil

    file_path = vim.fn.expand(file_path)
    if vim.fn.filereadable(file_path) == 0 and vim.fn.isdirectory(file_path) == 0 then
      logger.error("command", "CursorCodeAdd: File or directory does not exist: " .. file_path)
      return
    end

    -- Convert to 0-indexed for internal use
    local cursor_start_line = start_line and (start_line - 1) or nil
    local cursor_end_line = end_line and (end_line - 1) or nil

    local success, error_msg = M.send_at_mention(file_path, cursor_start_line, cursor_end_line, "CursorCodeAdd")
    if not success then
      logger.error("command", "CursorCodeAdd: " .. (error_msg or "Failed to add file"))
    else
      local message = "CursorCodeAdd: Successfully added " .. file_path
      if start_line or end_line then
        if start_line and end_line then
          message = message .. " (lines " .. start_line .. "-" .. end_line .. ")"
        elseif start_line then
          message = message .. " (from line " .. start_line .. ")"
        end
      end
      logger.info("command", message)
    end
  end, {
    desc = "Add file to Cursor context (@file or @file:lines)",
    nargs = "+",
    complete = "file",
  })

  -- Send visual selection
  vim.api.nvim_create_user_command("CursorCodeSend", function(opts)
    local selection_module_ok, selection_module = pcall(require, "cursorcode.selection")
    if selection_module_ok then
      local line1, line2 = nil, nil
      if opts and opts.range and opts.range > 0 then
        line1, line2 = opts.line1, opts.line2
      end
      selection_module.send_at_mention_for_visual_selection(line1, line2)
    else
      logger.error("command", "Selection module not available")
    end
  end, {
    desc = "Send current visual selection to Cursor",
    range = true,
  })

  -- Add from file tree
  vim.api.nvim_create_user_command("CursorCodeTreeAdd", function()
    local integrations_ok, integrations = pcall(require, "cursorcode.integrations")
    if not integrations_ok then
      logger.warn("command", "Integrations module not available")
      return
    end

    local files = integrations.get_selected_files()
    if not files or #files == 0 then
      logger.warn("command", "CursorCodeTreeAdd: No files selected")
      return
    end

    for _, file_path in ipairs(files) do
      local success, error_msg = M.send_at_mention(file_path, nil, nil, "CursorCodeTreeAdd")
      if not success then
        logger.error("command", "CursorCodeTreeAdd: Failed to add file: " .. file_path .. " - " .. (error_msg or "unknown error"))
      end
    end

    local message = #files == 1 and "Added 1 file to Cursor context" or string.format("Added %d files to Cursor context", #files)
    logger.info("command", message)
  end, {
    desc = "Add selected file from tree explorer to Cursor",
  })
end

return M
