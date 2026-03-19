--- Native Neovim terminal provider for Codex.
---@module 'codex.terminal.native'

local M = {}

local logger = require("codex.logger")
local utils = require("codex.utils")

local bufnr = nil
local winid = nil
local jobid = nil
local tip_shown = false
local config = require("codex.terminal").defaults

local function cleanup_state()
  bufnr = nil
  winid = nil
  jobid = nil
end

local function is_valid()
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    cleanup_state()
    return false
  end

  if not winid or not vim.api.nvim_win_is_valid(winid) then
    local windows = vim.api.nvim_list_wins()
    for _, win in ipairs(windows) do
      if vim.api.nvim_win_get_buf(win) == bufnr then
        winid = win
        logger.debug("terminal", "Recovered terminal window ID:", win)
        return true
      end
    end

    return true
  end

  return true
end

local function open_terminal(cmd_string, env_table, effective_config, focus)
  focus = utils.normalize_focus(focus)

  if is_valid() then
    if focus then
      vim.api.nvim_set_current_win(winid)
      vim.cmd("startinsert")
    end
    return true
  end

  local original_win = vim.api.nvim_get_current_win()
  local width = math.floor(vim.o.columns * effective_config.split_width_percentage)
  local full_height = vim.o.lines
  local placement_modifier = effective_config.split_side == "left" and "topleft " or "botright "

  vim.cmd(placement_modifier .. width .. "vsplit")
  local new_winid = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_height(new_winid, full_height)

  vim.api.nvim_win_call(new_winid, function()
    vim.cmd("enew")
  end)

  local term_cmd_arg
  if cmd_string:find(" ", 1, true) then
    term_cmd_arg = vim.split(cmd_string, " ", { plain = true, trimempty = false })
  else
    term_cmd_arg = { cmd_string }
  end

  jobid = vim.fn.termopen(term_cmd_arg, {
    env = env_table,
    cwd = effective_config.cwd,
    on_exit = function(job_id, _, _)
      vim.schedule(function()
        if job_id == jobid then
          logger.debug("terminal", "Terminal process exited, cleaning up")

          local current_winid_for_job = winid
          local current_bufnr_for_job = bufnr

          cleanup_state()

          if not effective_config.auto_close then
            return
          end

          if current_winid_for_job and vim.api.nvim_win_is_valid(current_winid_for_job) then
            if current_bufnr_for_job and vim.api.nvim_buf_is_valid(current_bufnr_for_job) then
              if vim.api.nvim_win_get_buf(current_winid_for_job) == current_bufnr_for_job then
                vim.api.nvim_win_close(current_winid_for_job, true)
              end
            else
              vim.api.nvim_win_close(current_winid_for_job, true)
            end
          end
        end
      end)
    end,
  })

  if not jobid or jobid == 0 then
    vim.notify("Failed to open native terminal.", vim.log.levels.ERROR)
    vim.api.nvim_win_close(new_winid, true)
    vim.api.nvim_set_current_win(original_win)
    cleanup_state()
    return false
  end

  winid = new_winid
  bufnr = vim.api.nvim_get_current_buf()
  vim.bo[bufnr].bufhidden = "hide"

  if focus then
    vim.api.nvim_set_current_win(winid)
    vim.cmd("startinsert")
  else
    vim.api.nvim_set_current_win(original_win)
  end

  if config.show_native_term_exit_tip and not tip_shown then
    vim.notify("Native terminal opened. Press Ctrl-\\ Ctrl-N to return to Normal mode.", vim.log.levels.INFO)
    tip_shown = true
  end

  return true
end

local function close_terminal()
  if is_valid() then
    vim.api.nvim_win_close(winid, true)
    cleanup_state()
  end
end

local function focus_terminal()
  if is_valid() then
    vim.api.nvim_set_current_win(winid)
    vim.cmd("startinsert")
  end
end

local function is_terminal_visible()
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  local windows = vim.api.nvim_list_wins()
  for _, win in ipairs(windows) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == bufnr then
      winid = win
      return true
    end
  end

  winid = nil
  return false
end

local function hide_terminal()
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) and winid and vim.api.nvim_win_is_valid(winid) then
    vim.api.nvim_win_close(winid, false)
    winid = nil
    logger.debug("terminal", "Terminal window hidden, process preserved")
  end
end

local function show_hidden_terminal(effective_config, focus)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  if is_terminal_visible() then
    if focus then
      focus_terminal()
    end
    return true
  end

  local original_win = vim.api.nvim_get_current_win()
  local width = math.floor(vim.o.columns * effective_config.split_width_percentage)
  local full_height = vim.o.lines
  local placement_modifier = effective_config.split_side == "left" and "topleft " or "botright "

  vim.cmd(placement_modifier .. width .. "vsplit")
  local new_winid = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_height(new_winid, full_height)
  vim.api.nvim_win_set_buf(new_winid, bufnr)
  winid = new_winid

  if focus then
    vim.api.nvim_set_current_win(winid)
    vim.cmd("startinsert")
  else
    vim.api.nvim_set_current_win(original_win)
  end

  logger.debug("terminal", "Showed hidden terminal in new window")
  return true
end

local function find_existing_codex_terminal()
  local buffers = vim.api.nvim_list_bufs()
  for _, buf in ipairs(buffers) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_option(buf, "buftype") == "terminal" then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name:match("codex") then
        local windows = vim.api.nvim_list_wins()
        for _, win in ipairs(windows) do
          if vim.api.nvim_win_get_buf(win) == buf then
            logger.debug("terminal", "Found existing Codex terminal in buffer", buf, "window", win)
            return buf, win
          end
        end
      end
    end
  end

  return nil, nil
end

---@param term_config table
function M.setup(term_config)
  config = term_config
end

---@param cmd_string string
---@param env_table table
---@param effective_config table
---@param focus boolean|nil
function M.open(cmd_string, env_table, effective_config, focus)
  focus = utils.normalize_focus(focus)

  if is_valid() then
    if not winid or not vim.api.nvim_win_is_valid(winid) then
      show_hidden_terminal(effective_config, focus)
    elseif focus then
      focus_terminal()
    end
  else
    local existing_buf, existing_win = find_existing_codex_terminal()
    if existing_buf and existing_win then
      bufnr = existing_buf
      winid = existing_win
      logger.debug("terminal", "Recovered existing Codex terminal")
      if focus then
        focus_terminal()
      end
    else
      if not open_terminal(cmd_string, env_table, effective_config, focus) then
        vim.notify("Failed to open Codex terminal using native fallback.", vim.log.levels.ERROR)
      end
    end
  end
end

function M.close()
  close_terminal()
end

---@param cmd_string string
---@param env_table table
---@param effective_config table
function M.simple_toggle(cmd_string, env_table, effective_config)
  local has_buffer = bufnr and vim.api.nvim_buf_is_valid(bufnr)
  local visible = has_buffer and is_terminal_visible()

  if visible then
    hide_terminal()
  else
    if has_buffer then
      if show_hidden_terminal(effective_config, true) then
        logger.debug("terminal", "Showing hidden terminal")
      else
        logger.error("terminal", "Failed to show hidden terminal")
      end
    else
      local existing_buf, existing_win = find_existing_codex_terminal()
      if existing_buf and existing_win then
        bufnr = existing_buf
        winid = existing_win
        logger.debug("terminal", "Recovered existing Codex terminal")
        focus_terminal()
      else
        if not open_terminal(cmd_string, env_table, effective_config) then
          vim.notify("Failed to open Codex terminal using native fallback (simple_toggle).", vim.log.levels.ERROR)
        end
      end
    end
  end
end

---@param cmd_string string
---@param env_table table
---@param effective_config table
function M.focus_toggle(cmd_string, env_table, effective_config)
  local has_buffer = bufnr and vim.api.nvim_buf_is_valid(bufnr)
  local visible = has_buffer and is_terminal_visible()

  if has_buffer then
    if visible then
      local current_win_id = vim.api.nvim_get_current_win()
      if winid == current_win_id then
        hide_terminal()
      else
        focus_terminal()
      end
    else
      if show_hidden_terminal(effective_config, true) then
        logger.debug("terminal", "Showing hidden terminal")
      else
        logger.error("terminal", "Failed to show hidden terminal")
      end
    end
  else
    local existing_buf, existing_win = find_existing_codex_terminal()
    if existing_buf and existing_win then
      bufnr = existing_buf
      winid = existing_win
      logger.debug("terminal", "Recovered existing Codex terminal")

      local current_win_id = vim.api.nvim_get_current_win()
      if existing_win == current_win_id then
        hide_terminal()
      else
        focus_terminal()
      end
    else
      if not open_terminal(cmd_string, env_table, effective_config) then
        vim.notify("Failed to open Codex terminal using native fallback (focus_toggle).", vim.log.levels.ERROR)
      end
    end
  end
end

---@param cmd_string string
---@param env_table table
---@param effective_config table
function M.toggle(cmd_string, env_table, effective_config)
  M.simple_toggle(cmd_string, env_table, effective_config)
end

---@return number|nil
function M.get_active_bufnr()
  if is_valid() then
    return bufnr
  end

  return nil
end

---@return boolean
function M.is_available()
  return true
end

return M
