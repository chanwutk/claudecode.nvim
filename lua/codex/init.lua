---@brief [[
--- Codex Neovim Integration
--- This plugin integrates the Codex CLI with Neovim through a managed terminal workflow.
---@brief ]]

---@module 'codex'
local M = {}

local logger = require("codex.logger")

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

M.state = {
  config = nil,
  initialized = false,
  commands_created = false,
}

---@param file_path string
---@return string, boolean
function M._format_path_for_reference(file_path)
  if not file_path or file_path == "" then
    error("File path cannot be empty")
  end

  local expanded_path = vim.fn.expand(file_path)
  if expanded_path == "" then
    error("Failed to expand file path: " .. file_path)
  end

  local is_file = vim.fn.filereadable(expanded_path) == 1
  local is_dir = vim.fn.isdirectory(expanded_path) == 1
  if not is_file and not is_dir then
    error("File or directory does not exist: " .. expanded_path)
  end

  local formatted_path = expanded_path
  local cwd = vim.fn.getcwd()
  if string.find(expanded_path, cwd, 1, true) == 1 then
    local relative_path = string.sub(expanded_path, #cwd + 2)
    if relative_path ~= "" then
      formatted_path = relative_path
    elseif is_dir then
      formatted_path = "./"
    end
  end

  if is_dir and not string.match(formatted_path, "/$") then
    formatted_path = formatted_path .. "/"
  end

  return formatted_path, is_dir
end

---@param formatted_path string
---@param start_line number|nil
---@param end_line number|nil
---@return string
function M._build_reference_text(formatted_path, start_line, end_line)
  if start_line == nil and end_line == nil then
    return string.format("@%s", formatted_path)
  end

  local display_start = start_line and (start_line + 1) or nil
  local display_end = end_line and (end_line + 1) or display_start

  if display_start and display_end and display_start == display_end then
    return string.format("In @%s, focus on line %d.", formatted_path, display_start)
  elseif display_start and display_end then
    return string.format("In @%s, focus on lines %d-%d.", formatted_path, display_start, display_end)
  elseif display_start then
    return string.format("In @%s, focus on line %d onward.", formatted_path, display_start)
  elseif display_end then
    return string.format("In @%s, focus up to line %d.", formatted_path, display_end)
  end

  return string.format("@%s", formatted_path)
end

---@param file_path string
---@param start_line number|nil
---@param end_line number|nil
---@return boolean, string|nil
function M._send_context_reference(file_path, start_line, end_line)
  local formatted_path, is_directory
  local format_success, format_result, is_dir_result = pcall(M._format_path_for_reference, file_path)
  if not format_success then
    return false, format_result
  end
  formatted_path, is_directory = format_result, is_dir_result

  if is_directory and (start_line or end_line) then
    logger.debug("command", "Line numbers ignored for directory:", formatted_path)
    start_line = nil
    end_line = nil
  end

  local reference_text = M._build_reference_text(formatted_path, start_line, end_line)
  local terminal = require("codex.terminal")
  local send_success = terminal.send_keys(reference_text .. " ")

  if send_success then
    logger.debug("command", "Sent context reference to Codex:", reference_text)
    return true, nil
  end

  local error_msg = "Failed to send context reference to Codex terminal: " .. reference_text
  logger.error("command", error_msg)
  return false, error_msg
end

local function exit_visual_mode()
  pcall(function()
    if vim.api and vim.api.nvim_feedkeys then
      local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
      vim.api.nvim_feedkeys(esc, "i", true)
    end
  end)
end

---@param file_path string
---@param start_line number|nil
---@param end_line number|nil
---@param context string|nil
---@return boolean, string|nil
function M.send_context_reference(file_path, start_line, end_line, context)
  context = context or "command"

  local terminal = require("codex.terminal")
  local bufnr = terminal.get_active_terminal_bufnr()

  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    exit_visual_mode()

    local success, error_msg = M._send_context_reference(file_path, start_line, end_line)
    if success then
      if M.state.config and M.state.config.focus_after_send then
        terminal.open()
        vim.schedule(function()
          vim.cmd("startinsert")
        end)
      else
        terminal.ensure_visible()
      end
    end
    return success, error_msg
  end

  exit_visual_mode()
  terminal.open()

  vim.schedule(function()
    vim.cmd("startinsert")
  end)

  vim.defer_fn(function()
    local success, error_msg = M._send_context_reference(file_path, start_line, end_line)
    if not success then
      logger.error(context, "Failed to send context reference after opening terminal: " .. (error_msg or "unknown error"))
    end
  end, 500)

  logger.debug(context, "Opened Codex terminal and queued context reference:", file_path)
  return true, nil
end

---@param opts string
---@return string|nil, number|nil, number|nil
local function parse_add_args(opts)
  local args = vim.split(opts, "%s+")
  if not args or #args == 0 then
    return nil, nil, nil
  end

  local start_line, end_line
  local last = tonumber(args[#args])
  local second_last = #args > 1 and tonumber(args[#args - 1]) or nil

  if second_last and last then
    start_line = second_last
    end_line = last
    table.remove(args, #args)
    table.remove(args, #args)
  elseif last then
    start_line = last
    table.remove(args, #args)
  end

  local file_path = table.concat(args, " ")
  if file_path == "" then
    return nil, nil, nil
  end

  return file_path, start_line, end_line
end

---@param opts table|nil
---@return table
function M.setup(opts)
  opts = opts or {}

  local config = require("codex.config")
  M.state.config = config.apply(opts)
  logger.setup(M.state.config)

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

  local terminal_setup_ok, terminal_module = pcall(require, "codex.terminal")
  if terminal_setup_ok and type(terminal_module.setup) == "function" then
    terminal_module.setup(opts.terminal, M.state.config.terminal_cmd, M.state.config.env)
  end

  if M.state.config.track_selection then
    local selection = require("codex.selection")
    selection.enable(nil, M.state.config.visual_demotion_delay_ms)
  end

  M._create_commands()
  M.state.initialized = true
  return M
end

function M._create_commands()
  if M.state.commands_created then
    return
  end

  vim.api.nvim_create_user_command("Codex", function(opts)
    local terminal = require("codex.terminal")
    local cmd_args = opts.args ~= "" and opts.args or nil
    terminal.focus_toggle(nil, cmd_args)
  end, {
    desc = "Toggle/focus Codex terminal",
    nargs = "*",
  })

  vim.api.nvim_create_user_command("CodexOpen", function(opts)
    local terminal = require("codex.terminal")
    local cmd_args = opts.args ~= "" and opts.args or nil
    terminal.open(nil, cmd_args)
  end, {
    desc = "Open Codex terminal",
    nargs = "*",
  })

  vim.api.nvim_create_user_command("CodexClose", function()
    local terminal = require("codex.terminal")
    terminal.close()
  end, {
    desc = "Close Codex terminal",
  })

  vim.api.nvim_create_user_command("CodexFocus", function(opts)
    local terminal = require("codex.terminal")
    local cmd_args = opts.args ~= "" and opts.args or nil
    terminal.focus_toggle(nil, cmd_args)
  end, {
    desc = "Focus/toggle Codex terminal",
    nargs = "*",
  })

  vim.api.nvim_create_user_command("CodexAdd", function(opts)
    local file_path, start_line, end_line = parse_add_args(opts.args or "")
    if not file_path then
      logger.warn("command", "CodexAdd: No file path provided")
      return
    end

    file_path = vim.fn.expand(file_path)
    if vim.fn.filereadable(file_path) == 0 and vim.fn.isdirectory(file_path) == 0 then
      logger.error("command", "CodexAdd: File or directory does not exist: " .. file_path)
      return
    end

    if start_line and start_line < 1 then
      logger.error("command", "CodexAdd: Start line must be positive: " .. start_line)
      return
    end

    if end_line and end_line < 1 then
      logger.error("command", "CodexAdd: End line must be positive: " .. end_line)
      return
    end

    if start_line and end_line and start_line > end_line then
      logger.error("command", "CodexAdd: Start line (" .. start_line .. ") must be <= end line (" .. end_line .. ")")
      return
    end

    local codex_start_line = start_line and (start_line - 1) or nil
    local codex_end_line = end_line and (end_line - 1) or nil

    local success, error_msg = M.send_context_reference(file_path, codex_start_line, codex_end_line, "CodexAdd")
    if not success then
      logger.error("command", "CodexAdd: " .. (error_msg or "Failed to add file"))
    else
      local message = "CodexAdd: Successfully added " .. file_path
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
    desc = "Add file or directory to Codex context (@file or line reference)",
    nargs = "+",
    complete = "file",
  })

  vim.api.nvim_create_user_command("CodexSend", function(opts)
    local selection_module_ok, selection_module = pcall(require, "codex.selection")
    if selection_module_ok then
      local line1, line2 = nil, nil
      if opts and opts.range and opts.range > 0 then
        line1, line2 = opts.line1, opts.line2
      end
      selection_module.send_context_for_visual_selection(line1, line2)
    else
      logger.error("command", "Selection module not available")
    end
  end, {
    desc = "Send current visual selection to Codex",
    range = true,
  })

  vim.api.nvim_create_user_command("CodexTreeAdd", function()
    local integrations_ok, integrations = pcall(require, "codex.integrations")
    if not integrations_ok then
      logger.warn("command", "Integrations module not available")
      return
    end

    local files, error_msg = integrations.get_selected_files_from_tree()
    if error_msg then
      logger.warn("command", "CodexTreeAdd: " .. error_msg)
      return
    end

    if not files or #files == 0 then
      logger.warn("command", "CodexTreeAdd: No files selected")
      return
    end

    for _, file_path in ipairs(files) do
      local success, send_error = M.send_context_reference(file_path, nil, nil, "CodexTreeAdd")
      if not success then
        logger.error("command", "CodexTreeAdd: Failed to add file: " .. file_path .. " - " .. (send_error or "unknown error"))
      end
    end

    local message = #files == 1 and "Added 1 file to Codex context"
      or string.format("Added %d files to Codex context", #files)
    logger.info("command", message)
  end, {
    desc = "Add selected file from tree explorer to Codex",
  })

  M.state.commands_created = true
end

---@return table
function M.get_version()
  return {
    version = M.version:string(),
    major = M.version.major,
    minor = M.version.minor,
    patch = M.version.patch,
    prerelease = M.version.prerelease,
  }
end

return M
