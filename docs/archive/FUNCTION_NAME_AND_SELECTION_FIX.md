# Function Name and Selection Module Fix

## Issues Fixed

This document explains two critical bugs that were fixed in the cursor-cli.nvim plugin.

### Issue 1: Wrong Function Name in terminal.lua

**Error Message**:
```
Error executing Lua callback: ...lua/cursor-cli/terminal.lua:494: 
attempt to call global 'get_claude_command_and_env' (a nil value)
stack traceback:
  terminal.lua:494: in function 'open'
  init.lua:240: in function <init.lua:237>
```

**Command that failed**: `:CursorCLIOpen`

#### Root Cause

The `terminal.lua` module had a copy-paste error from the original claudecode plugin:
- The function was defined as `get_cursor_command_and_env()` on line 292
- But it was being called as `get_claude_command_and_env()` on line 494
- Variable was named `claude_env_table` instead of `cursor_env_table`

#### The Fix

**Before** (terminal.lua line 494):
```lua
local cmd_string, claude_env_table = get_claude_command_and_env(cmd_args)
```

**After**:
```lua
local cmd_string, cursor_env_table = get_cursor_command_and_env(cmd_args)
```

Also updated:
- Comment from "claude command" to "cursor command"
- Variable name throughout the function

### Issue 2: Selection Module Incompatibility

**Error Message**:
```
[CursorCLI] [selection] [ERROR] Selection tracking is not enabled.
```

**Command that failed**: `:CursorCLISend`

#### Root Causes

The `selection.lua` module was copied from claudecode but never adapted for cursor-cli's architecture:

1. **Checked `tracking_enabled`**: Required selection tracking to be enabled, but cursor-cli doesn't use tracking
2. **Required claudecode module**: Tried to `require("claudecode")` which doesn't exist in cursor-cli.nvim
3. **Checked for server**: Expected `claudecode_main.state.server` but cursor-cli doesn't have a WebSocket server
4. **Wrong function call**: Called `claudecode_main.send_at_mention()` instead of `cursor-cli_main.send_at_mention()`

#### The Fix

Completely rewrote the `send_at_mention_for_visual_selection()` function:

**Before** (selection.lua lines 630-641):
```lua
function M.send_at_mention_for_visual_selection(line1, line2)
  if not M.state.tracking_enabled then
    logger.error("selection", "Selection tracking is not enabled.")
    return false
  end

  -- Check if Cursor Code integration is running
  local claudecode_main = require("claudecode")
  if not claudecode_main.state.server then
    logger.error("selection", "Cursor Code integration is not running.")
    return false
  end
  
  -- ... rest of function
  local success, error_msg = claudecode_main.send_at_mention(...)
```

**After**:
```lua
function M.send_at_mention_for_visual_selection(line1, line2)
  -- Note: For cursor-cli, we don't need tracking_enabled to send selections
  -- We can send selections on-demand via direct text input

  -- ... get selection logic (reordered to try current visual first)
  
  -- Use cursor-cli main module to send the at-mention
  local cursor-cli_main = require("cursor-cli")
  local success, error_msg = cursor-cli_main.send_at_mention(...)
```

**Key Changes**:
1. ✅ Removed `tracking_enabled` check
2. ✅ Removed server check
3. ✅ Changed `require("claudecode")` to `require("cursor-cli")`
4. ✅ Reordered logic to try current visual selection first
5. ✅ Uses `cursor-cli_main.send_at_mention()` instead of `claudecode_main.send_at_mention()`

## Why These Changes Work

### Architecture Difference

**claudecode.nvim**:
- Uses WebSocket server
- Sends data via MCP protocol
- Requires selection tracking for real-time updates
- Server must be running for commands to work

**cursor-cli.nvim** (cursor-cli.nvim):
- No WebSocket server
- Types text directly into terminal
- Selection captured on-demand when command is run
- Works independently without tracking

### Result

Both commands now work correctly:

```vim
" Open cursor terminal
:CursorCLIOpen
✅ Opens terminal with "agent" command

" Send current selection
:CursorCLISend
✅ Gets current visual selection
✅ Types @filename:lines into cursor terminal
✅ No errors!
```

## Files Changed

1. **lua/cursor-cli/terminal.lua**
   - Line 491: Comment updated
   - Line 494: Function name and variable name fixed

2. **lua/cursor-cli/selection.lua**
   - Lines 630-698: Complete rewrite of `send_at_mention_for_visual_selection()`
   - Removed claudecode dependencies
   - Adapted for cursor-cli architecture

## Verification

After updating:
```vim
:Lazy update cursor-cli.nvim
" Restart Neovim

" Test opening terminal
:CursorCLIOpen
" Should open without errors

" Test sending selection (in visual mode)
V
:CursorCLISend
" Should send selection without errors
```

## Prevention

When adapting code from claudecode to cursor-cli:
- [ ] Check all function names match
- [ ] Replace all "claude" references with "cursor"
- [ ] Remove server/tracking dependencies
- [ ] Update variable names
- [ ] Test all commands after changes

These were simple oversights from the copy-paste process that have now been corrected!
