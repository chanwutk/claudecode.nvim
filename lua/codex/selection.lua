--- Manages selection tracking and context extraction for Codex.
---@module 'codex.selection'

local M = {}

local logger = require("codex.logger")
local terminal = require("codex.terminal")

M.state = {
  latest_selection = nil,
  tracking_enabled = false,
  debounce_timer = nil,
  debounce_ms = 100,
  last_active_visual_selection = nil,
  demotion_timer = nil,
  visual_demotion_delay_ms = 50,
}

---@param server table|nil
---@param visual_demotion_delay_ms number
function M.enable(server, visual_demotion_delay_ms)
  if M.state.tracking_enabled then
    return
  end

  M.state.tracking_enabled = true
  M.server = server
  M.state.visual_demotion_delay_ms = visual_demotion_delay_ms
  M._create_autocommands()
end

function M.disable()
  if not M.state.tracking_enabled then
    return
  end

  M.state.tracking_enabled = false
  M._clear_autocommands()
  M.state.latest_selection = nil
  M.server = nil

  if M.state.debounce_timer then
    vim.loop.timer_stop(M.state.debounce_timer)
    M.state.debounce_timer = nil
  end
end

function M._create_autocommands()
  local group = vim.api.nvim_create_augroup("CodexSelection", { clear = true })

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufEnter" }, {
    group = group,
    callback = function()
      M.on_cursor_moved()
    end,
  })

  vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    callback = function()
      M.on_mode_changed()
    end,
  })

  vim.api.nvim_create_autocmd("TextChanged", {
    group = group,
    callback = function()
      M.on_text_changed()
    end,
  })
end

function M._clear_autocommands()
  vim.api.nvim_clear_autocmds({ group = "CodexSelection" })
end

function M.on_cursor_moved()
  M.debounce_update()
end

function M.on_mode_changed()
  M.debounce_update()
end

function M.on_text_changed()
  M.debounce_update()
end

function M.debounce_update()
  if M.state.debounce_timer then
    vim.loop.timer_stop(M.state.debounce_timer)
  end

  M.state.debounce_timer = vim.defer_fn(function()
    M.update_selection()
    M.state.debounce_timer = nil
  end, M.state.debounce_ms)
end

function M.update_selection()
  if not M.state.tracking_enabled then
    return
  end

  local current_buf = vim.api.nvim_get_current_buf()
  local buf_name = vim.api.nvim_buf_get_name(current_buf)

  if buf_name and buf_name:match("^term://") and buf_name:lower():find("codex", 1, true) then
    if M.state.demotion_timer then
      M.state.demotion_timer:stop()
      M.state.demotion_timer:close()
      M.state.demotion_timer = nil
    end
    return
  end

  local codex_term_bufnr = terminal.get_active_terminal_bufnr()
  if codex_term_bufnr and current_buf == codex_term_bufnr then
    if M.state.demotion_timer then
      M.state.demotion_timer:stop()
      M.state.demotion_timer:close()
      M.state.demotion_timer = nil
    end
    return
  end

  local current_mode = vim.api.nvim_get_mode().mode
  local current_selection

  if current_mode == "v" or current_mode == "V" or current_mode == "\022" then
    if M.state.demotion_timer then
      M.state.demotion_timer:stop()
      M.state.demotion_timer:close()
      M.state.demotion_timer = nil
    end

    current_selection = M.get_visual_selection()
    if current_selection then
      M.state.last_active_visual_selection = {
        bufnr = current_buf,
        selection_data = vim.deepcopy(current_selection),
        timestamp = vim.loop.now(),
      }
    elseif M.state.last_active_visual_selection and M.state.last_active_visual_selection.bufnr == current_buf then
      M.state.last_active_visual_selection = nil
    end
  else
    local last_visual = M.state.last_active_visual_selection

    if M.state.demotion_timer then
      current_selection = M.get_cursor_position()
    elseif
      last_visual
      and last_visual.bufnr == current_buf
      and last_visual.selection_data
      and not last_visual.selection_data.selection.isEmpty
    then
      current_selection = M.state.latest_selection

      if M.state.demotion_timer then
        M.state.demotion_timer:stop()
        M.state.demotion_timer:close()
      end

      M.state.demotion_timer = vim.loop.new_timer()
      M.state.demotion_timer:start(M.state.visual_demotion_delay_ms, 0, vim.schedule_wrap(function()
        if M.state.demotion_timer then
          M.state.demotion_timer:stop()
          M.state.demotion_timer:close()
          M.state.demotion_timer = nil
        end
        M.handle_selection_demotion(current_buf)
      end))
    else
      current_selection = M.get_cursor_position()
      if last_visual and last_visual.bufnr == current_buf then
        M.state.last_active_visual_selection = nil
      end
    end
  end

  if not current_selection then
    current_selection = M.get_cursor_position()
  end

  local changed = M.has_selection_changed(current_selection)
  if changed then
    M.state.latest_selection = current_selection
    if M.server then
      M.send_selection_update(current_selection)
    end
  end
end

---@param original_bufnr_when_scheduled number
function M.handle_selection_demotion(original_bufnr_when_scheduled)
  local current_buf = vim.api.nvim_get_current_buf()
  local codex_term_bufnr = terminal.get_active_terminal_bufnr()

  if codex_term_bufnr and current_buf == codex_term_bufnr then
    if
      M.state.last_active_visual_selection
      and M.state.last_active_visual_selection.bufnr == original_bufnr_when_scheduled
    then
      M.state.last_active_visual_selection = nil
    end
    return
  end

  local current_mode = vim.api.nvim_get_mode().mode
  if current_buf == original_bufnr_when_scheduled and (current_mode == "v" or current_mode == "V" or current_mode == "\022") then
    if
      M.state.last_active_visual_selection
      and M.state.last_active_visual_selection.bufnr == original_bufnr_when_scheduled
    then
      M.state.last_active_visual_selection = nil
    end
    return
  end

  if current_buf == original_bufnr_when_scheduled then
    local new_sel_for_demotion = M.get_cursor_position()
    if M.has_selection_changed(new_sel_for_demotion) then
      M.state.latest_selection = new_sel_for_demotion
      if M.server then
        M.send_selection_update(M.state.latest_selection)
      end
    end
  end

  if
    M.state.last_active_visual_selection
    and M.state.last_active_visual_selection.bufnr == original_bufnr_when_scheduled
  then
    M.state.last_active_visual_selection = nil
  end
end

---@return boolean, string|nil
local function validate_visual_mode()
  local current_nvim_mode = vim.api.nvim_get_mode().mode
  local fixed_anchor_pos_raw = vim.fn.getpos("v")

  if not (current_nvim_mode == "v" or current_nvim_mode == "V" or current_nvim_mode == "\22") then
    return false, "not in visual mode"
  end

  if fixed_anchor_pos_raw[2] == 0 then
    return false, "no visual selection mark"
  end

  return true, nil
end

---@return string|nil
local function get_effective_visual_mode()
  local current_nvim_mode = vim.api.nvim_get_mode().mode
  local visual_fn_mode_char = vim.fn.visualmode()

  if visual_fn_mode_char and visual_fn_mode_char ~= "" then
    return visual_fn_mode_char
  end

  if current_nvim_mode == "V" then
    return "V"
  elseif current_nvim_mode == "v" then
    return "v"
  elseif current_nvim_mode == "\22" then
    return "\22"
  end

  return nil
end

---@return table, table
local function get_selection_coordinates()
  local fixed_anchor_pos_raw = vim.fn.getpos("v")
  local current_cursor_nvim = vim.api.nvim_win_get_cursor(0)

  local p1 = { lnum = fixed_anchor_pos_raw[2], col = fixed_anchor_pos_raw[3] }
  local p2 = { lnum = current_cursor_nvim[1], col = current_cursor_nvim[2] + 1 }

  if p1.lnum < p2.lnum or (p1.lnum == p2.lnum and p1.col <= p2.col) then
    return p1, p2
  end

  return p2, p1
end

---@param lines_content table
---@param start_coords table
---@return string
local function extract_linewise_text(lines_content, start_coords)
  start_coords.col = 1
  return table.concat(lines_content, "\n")
end

---@param lines_content table
---@param start_coords table
---@param end_coords table
---@return string|nil
local function extract_characterwise_text(lines_content, start_coords, end_coords)
  if start_coords.lnum == end_coords.lnum then
    if not lines_content[1] then
      return nil
    end
    return string.sub(lines_content[1], start_coords.col, end_coords.col)
  end

  if not lines_content[1] or not lines_content[#lines_content] then
    return nil
  end

  local text_parts = {}
  table.insert(text_parts, string.sub(lines_content[1], start_coords.col))
  for i = 2, #lines_content - 1 do
    table.insert(text_parts, lines_content[i])
  end
  table.insert(text_parts, string.sub(lines_content[#lines_content], 1, end_coords.col))
  return table.concat(text_parts, "\n")
end

---@param start_coords table
---@param end_coords table
---@param visual_mode string
---@param lines_content table
---@return table
local function calculate_lsp_positions(start_coords, end_coords, visual_mode, lines_content)
  local lsp_start_line = start_coords.lnum - 1
  local lsp_end_line = end_coords.lnum - 1
  local lsp_start_char, lsp_end_char

  if visual_mode == "V" then
    lsp_start_char = 0
    if #lines_content > 0 and lines_content[#lines_content] then
      lsp_end_char = #lines_content[#lines_content]
    else
      lsp_end_char = 0
    end
  else
    lsp_start_char = start_coords.col - 1
    lsp_end_char = end_coords.col
  end

  return {
    start = { line = lsp_start_line, character = lsp_start_char },
    ["end"] = { line = lsp_end_line, character = lsp_end_char },
  }
end

---@return table|nil
function M.get_visual_selection()
  local valid = validate_visual_mode()
  if not valid then
    return nil
  end

  local visual_mode = get_effective_visual_mode()
  if not visual_mode then
    return nil
  end

  local start_coords, end_coords = get_selection_coordinates()
  local current_buf = vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(current_buf)

  local lines_content = vim.api.nvim_buf_get_lines(current_buf, start_coords.lnum - 1, end_coords.lnum, false)
  if #lines_content == 0 then
    return nil
  end

  local final_text
  if visual_mode == "V" then
    final_text = extract_linewise_text(lines_content, start_coords)
  elseif visual_mode == "v" or visual_mode == "\22" then
    final_text = extract_characterwise_text(lines_content, start_coords, end_coords)
    if not final_text then
      return nil
    end
  else
    return nil
  end

  local lsp_positions = calculate_lsp_positions(start_coords, end_coords, visual_mode, lines_content)

  return {
    text = final_text or "",
    filePath = file_path,
    fileUrl = "file://" .. file_path,
    selection = {
      start = lsp_positions.start,
      ["end"] = lsp_positions["end"],
      isEmpty = not final_text or #final_text == 0,
    },
  }
end

---@return table
function M.get_cursor_position()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local current_buf = vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(current_buf)

  return {
    text = "",
    filePath = file_path,
    fileUrl = "file://" .. file_path,
    selection = {
      start = { line = cursor_pos[1] - 1, character = cursor_pos[2] },
      ["end"] = { line = cursor_pos[1] - 1, character = cursor_pos[2] },
      isEmpty = true,
    },
  }
end

---@param new_selection table|nil
---@return boolean
function M.has_selection_changed(new_selection)
  local old_selection = M.state.latest_selection

  if not new_selection then
    return old_selection ~= nil
  end

  if not old_selection then
    return true
  end

  if old_selection.filePath ~= new_selection.filePath then
    return true
  end

  if old_selection.text ~= new_selection.text then
    return true
  end

  if
    old_selection.selection.start.line ~= new_selection.selection.start.line
    or old_selection.selection.start.character ~= new_selection.selection.start.character
    or old_selection.selection["end"].line ~= new_selection.selection["end"].line
    or old_selection.selection["end"].character ~= new_selection.selection["end"].character
  then
    return true
  end

  return false
end

---@param selection table
function M.send_selection_update(selection)
  if M.server and type(M.server.broadcast) == "function" then
    M.server.broadcast("selection_changed", selection)
  end
end

---@return table|nil
function M.get_latest_selection()
  return M.state.latest_selection
end

---@param line1 number
---@param line2 number
---@return table|nil
function M.get_range_selection(line1, line2)
  if not line1 or not line2 or line1 < 1 or line2 < 1 or line1 > line2 then
    return nil
  end

  local current_buf = vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(current_buf)
  local total_lines = vim.api.nvim_buf_line_count(current_buf)
  if line2 > total_lines then
    line2 = total_lines
  end

  local lines_content = vim.api.nvim_buf_get_lines(current_buf, line1 - 1, line2, false)
  if #lines_content == 0 then
    return nil
  end

  local final_text = table.concat(lines_content, "\n")
  local lsp_start_line = line1 - 1
  local lsp_end_line = line2 - 1
  local lsp_start_char = 0
  local lsp_end_char = #lines_content[#lines_content]

  return {
    text = final_text or "",
    filePath = file_path,
    fileUrl = "file://" .. file_path,
    selection = {
      start = { line = lsp_start_line, character = lsp_start_char },
      ["end"] = { line = lsp_end_line, character = lsp_end_char },
      isEmpty = not final_text or #final_text == 0,
    },
  }
end

---@param line1 number|nil
---@param line2 number|nil
---@return boolean
function M.send_context_for_visual_selection(line1, line2)
  local sel_to_send

  if line1 and line2 then
    sel_to_send = M.get_range_selection(line1, line2)
    if not sel_to_send or sel_to_send.selection.isEmpty then
      logger.warn("selection", "Invalid range selection to send as context.")
      return false
    end
  else
    local current_visual = M.get_visual_selection()
    if current_visual and not current_visual.selection.isEmpty then
      sel_to_send = current_visual
    elseif M.state.latest_selection and not M.state.latest_selection.selection.isEmpty then
      sel_to_send = M.state.latest_selection
    else
      logger.warn("selection", "No visual selection to send as context.")
      return false
    end
  end

  local current_buf_name = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
  if sel_to_send.filePath ~= current_buf_name then
    logger.warn(
      "selection",
      "Tracked selection is for '"
        .. sel_to_send.filePath
        .. "', but current buffer is '"
        .. current_buf_name
        .. "'. Not sending."
    )
    return false
  end

  local codex_main = require("codex")
  local file_path = sel_to_send.filePath
  local start_line = sel_to_send.selection.start.line
  local end_line = sel_to_send.selection["end"].line

  local success, error_msg = codex_main.send_context_reference(file_path, start_line, end_line, "CodexSend")
  if success then
    logger.debug("selection", "Visual selection sent as context reference.")
    return true
  end

  logger.error("selection", "Failed to send context reference: " .. (error_msg or "unknown error"))
  return false
end

return M
