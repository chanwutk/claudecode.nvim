# Fix: Cursor CLI Command Name Update

## Issue

Users encountered this error when trying to open the cursor terminal:

```
1: term:///data/cwkt/l/.config/nvim//3528893:cursor
   33                                                                                                                                                      │/bin/bash: line 1: cursor: command not found
```

The plugin was attempting to run `cursor` command, but the actual cursor-cli executable is called `agent`.

## Root Cause

The default terminal command was hardcoded as `"cursor"` in the codebase. This was an incorrect assumption about the cursor-cli command name.

### Where the Error Occurred

The error happened in the terminal opening flow:
1. User runs `:CursorCode`
2. Plugin calls `get_cursor_command_and_env()`
3. Function returns `"cursor"` as the default command
4. Terminal provider executes: `cursor` (via jobstart/termopen)
5. Shell returns: `cursor: command not found`

### The Actual Command

Cursor CLI's actual command is **`agent`**, not `cursor`.

## The Fix

Updated the default command from `"cursor"` to `"agent"` throughout the codebase.

### Code Changes

#### 1. Terminal Module (`lua/cursorcode/terminal.lua`)

**Before** (Line 295):
```lua
local function get_cursor_command_and_env(cmd_args)
  local cmd_from_config = defaults.terminal_cmd
  local base_cmd
  if not cmd_from_config or cmd_from_config == "" then
    base_cmd = "cursor" -- Default cursor command
  else
    base_cmd = cmd_from_config
  end
  -- ...
end
```

**After**:
```lua
local function get_cursor_command_and_env(cmd_args)
  local cmd_from_config = defaults.terminal_cmd
  local base_cmd
  if not cmd_from_config or cmd_from_config == "" then
    base_cmd = "agent" -- Default cursor-cli command
  else
    base_cmd = cmd_from_config
  end
  -- ...
end
```

#### 2. Config Module (`lua/cursorcode/config.lua`)

**Before** (Line 11):
```lua
M.defaults = {
  terminal_cmd = nil, -- Will default to "cursor" if not set
  env = {}, -- Custom environment variables for Cursor terminal
  -- ...
}
```

**After**:
```lua
M.defaults = {
  terminal_cmd = nil, -- Will default to "agent" (cursor-cli command) if not set
  env = {}, -- Custom environment variables for Cursor terminal
  -- ...
}
```

### Documentation Updates

#### 3. README.md

**Before**:
```markdown
> **Note:** This fork defaults to `cursor` command. To use Claude Code instead, set `terminal_cmd = "claude"` in your config.

- Default cursor command is `"cursor"`
```

**After**:
```markdown
> **Note:** This fork defaults to `agent` command (cursor-cli). To use Claude Code instead, set `terminal_cmd = "claude"` in your config.

- Default cursor-cli command is `"agent"`
```

#### 4. CURSORCODE_README.md

**Before**:
```markdown
### Cursor command not found
Error: cursor: command not found

Solution: Install cursor-cli or configure the path:
require("cursorcode").setup({
  terminal_cmd = "/path/to/cursor",
})
```

**After**:
```markdown
### Cursor command not found
Error: agent: command not found

Solution: Install cursor-cli or configure the path:
require("cursorcode").setup({
  terminal_cmd = "/path/to/agent",
})
```

## Verification

After the fix, verify it works:

```vim
" 1. Open cursor terminal
:CursorCode

" Should now execute 'agent' command instead of 'cursor'
" Terminal should open successfully if cursor-cli is installed
```

### Check the Command Being Used

You can verify what command the plugin is using:

```vim
" Enable debug logging
:lua require("cursorcode").setup({ log_level = "debug" })

" Then open terminal
:CursorCode

" Check messages for the command being executed
:messages
```

## Files Changed

1. **lua/cursorcode/terminal.lua**
   - Line 295: Changed default from `"cursor"` to `"agent"`
   - Updated comment to clarify it's the cursor-cli command

2. **lua/cursorcode/config.lua**
   - Line 11: Updated comment to reference `"agent"` command

3. **README.md**
   - Updated default command references
   - Updated notes about cursor command

4. **CURSORCODE_README.md**
   - Updated troubleshooting section with correct command

## Impact

### Before Fix
- Plugin tried to run: `cursor`
- Result: Command not found error
- Users couldn't use the plugin with cursor-cli

### After Fix
- Plugin runs: `agent`
- Result: Cursor-cli starts successfully
- Users can immediately use the plugin

## For Users

### Standard Installation

If you installed cursor-cli normally (with `agent` command in PATH):
```lua
{
  "chanwutk/cursor-cli.nvim",
  name = "cursorcode",
  dependencies = { "folke/snacks.nvim" },
  -- No config needed - will use 'agent' by default
}
```

Then just run:
```vim
:CursorCode
```

### Custom Installation

If your cursor-cli has a different command or path:
```lua
require("cursorcode").setup({
  terminal_cmd = "/custom/path/to/agent",
  -- or if you named it differently:
  -- terminal_cmd = "my-cursor-cli",
})
```

## Related Issues

This fix completes the series of initialization fixes:
1. ✅ Command registration (VimEnter autocmd)
2. ✅ Config syntax error (missing parenthesis)
3. ✅ Invalid env argument (empty table)
4. ✅ **Correct cursor-cli command name** (this fix)

All issues resolved - the plugin should now work end-to-end! 🎉

## Testing Checklist

- [x] Verify `agent` is the correct cursor-cli command
- [x] Update default command in code
- [x] Update documentation references
- [x] Test that terminal opens with `agent` command
- [x] Verify custom command override still works

## Prevention

To prevent similar issues:
1. Verify actual command names before hardcoding defaults
2. Document the command name in multiple places
3. Make the command easily configurable
4. Provide clear error messages when command not found
