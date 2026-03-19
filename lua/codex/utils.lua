---Shared utility functions for codex.nvim
---@module 'codex.utils'

local M = {}

---Normalizes focus parameter to default to true for backward compatibility.
---@param focus boolean? The focus parameter
---@return boolean
function M.normalize_focus(focus)
  if focus == nil then
    return true
  end

  return focus
end

---Build an `env` dict for |jobstart()| / |termopen()|.
---Empty user env returns nil so callers can omit the key (empty `{}` can trigger
---`E475: Invalid argument: env` with some Neovim + snacks.nvim combinations).
---Non-empty user env is merged on top of |environ()| so PATH and defaults stay set.
---@param extra_env table|nil
---@return table|nil
function M.prepare_job_env(extra_env)
  if type(extra_env) ~= "table" then
    return nil
  end

  local merged = nil
  for key, value in pairs(extra_env) do
    if type(key) == "string" and key ~= "" then
      if merged == nil then
        merged = {}
        for k, v in pairs(vim.fn.environ()) do
          merged[k] = v
        end
      end
      merged[key] = type(value) == "string" and value or tostring(value)
    end
  end

  return merged
end

return M
