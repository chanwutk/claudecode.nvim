# Complete Fix List - cursor-cli.nvim

All issues identified and fixed during the development of cursor-cli.nvim standalone plugin.

## Summary

This plugin started as a fork of claudecode.nvim and has been adapted to:
- Work **alongside** (not replace) the official coder/claudecode.nvim
- Provide **only** Cursor CLI support (agent command)
- Use **direct text input** instead of WebSocket/MCP
- Have **no conflicts** with the original claudecode plugin

## All Fixes (10 Total)

### Fix #1: Repository Rename
**Issue**: Repository name needed updating  
**Changed**: `chanwutk/claudecode.nvim` → `chanwutk/cursor-cli.nvim`  
**Impact**: All documentation updated with new repository name  
**Commit**: Multiple commits updating docs  

### Fix #2: Config Syntax Error
**Issue**: Missing closing parenthesis in config.lua  
**Error**: `')' expected (to close '(' at line 67) near 'return'`  
**Fix**: Added missing `)` on line 70 after assert statement  
**File**: `lua/cursorcode/config.lua`  
**Commit**: `2c67390`  

### Fix #3: Command Registration Failure
**Issue**: `:CursorCode` command not available after installation  
**Error**: `E492: Not an editor command: CursorCode`  
**Root Cause**: `vim.defer_fn` timing issues  
**Fix**: Changed to VimEnter autocmd for reliable setup  
**Files**: `plugin/cursorcode.lua`, `lua/cursorcode/init.lua`  
**Commit**: `e184d94`  

### Fix #4: Invalid env Argument
**Issue**: Error when opening cursor terminal  
**Error**: `Vim:E475: Invalid argument: env`  
**Root Cause**: Passing empty `{}` table for env instead of `nil`  
**Fix**: Only include env in opts when it has values  
**Files**: `lua/cursorcode/terminal/snacks.lua`, `lua/cursorcode/terminal/native.lua`  
**Commit**: `6e831d1`  

### Fix #5: Wrong CLI Command Name
**Issue**: Terminal tried to run non-existent command  
**Error**: `/bin/bash: line 1: cursor: command not found`  
**Root Cause**: Default command was `"cursor"` but actual command is `"agent"`  
**Fix**: Changed default from `"cursor"` to `"agent"`  
**Files**: `lua/cursorcode/terminal.lua`, `lua/cursorcode/config.lua`  
**Commit**: `d5720c8`  

### Fix #6: Plugin Conflict with claudecode.nvim
**Issue**: Installing cursor-cli.nvim broke original claudecode.nvim  
**Error**: `E492: Not an editor command: ClaudeCode`  
**Root Cause**: Both plugins had claudecode files causing conflicts  
**Fix**: Removed ALL claudecode files from cursor-cli.nvim (37 files deleted)  
**Files**: Deleted `plugin/claudecode.lua` and entire `lua/claudecode/` directory  
**Commit**: `1bd9dbc`  

### Fix #7: Selection Tracking Error & Wrong Branding
**Issue**: Selection commands showed error and wrong plugin name  
**Error**: `[ClaudeCode] [selection] [ERROR] Selection tracking is not enabled.`  
**Root Causes**:
1. Logger used "ClaudeCode" instead of "CursorCode"
2. Selection tracking enabled but not compatible with cursorcode
**Fix**: 
- Changed logger branding to "CursorCode"
- Disabled selection tracking by default (not needed)
**Files**: `lua/cursorcode/logger.lua`, `lua/cursorcode/config.lua`, `lua/cursorcode/init.lua`  
**Commit**: `3e83503`  

### Fix #8: Missing Logger Import
**Issue**: Logger function calls failed  
**Error**: `attempt to index global 'logger' (a nil value)`  
**Root Cause**: terminal.lua used logger 14 times but never imported it  
**Fix**: Added `local logger = require("cursorcode.logger")`  
**File**: `lua/cursorcode/terminal.lua`  
**Commit**: `f16df23`  

### Fix #9: Wrong Function Name
**Issue**: Terminal open failed  
**Error**: `attempt to call global 'get_claude_command_and_env' (a nil value)`  
**Root Cause**: Function defined as `get_cursor_command_and_env` but called as `get_claude_command_and_env`  
**Fix**: Changed function call to use correct name  
**File**: `lua/cursorcode/terminal.lua` line 494  
**Commit**: `1422041`  

### Fix #10: Selection Module Claudecode References
**Issue**: Selection sending failed  
**Error**: `[CursorCode] [selection] [ERROR] Selection tracking is not enabled.`  
**Root Causes**:
1. Checked `tracking_enabled` (not needed for cursorcode)
2. Required `"claudecode"` module (doesn't exist)
3. Checked for server (cursorcode has no server)
4. Called `claudecode_main.send_at_mention()`
**Fix**: Rewrote function to:
- Remove tracking_enabled check
- Use `require("cursorcode")` instead
- Remove server dependency
- Call `cursorcode_main.send_at_mention()`
**File**: `lua/cursorcode/selection.lua` lines 630-698  
**Commit**: `1422041`  

## Current Status

✅ **All Major Issues Fixed**

### Working Features
- ✅ Plugin auto-setup on VimEnter
- ✅ All CursorCode* commands registered
- ✅ Terminal opens with `agent` command
- ✅ File sending works (`:CursorCodeAdd`)
- ✅ Selection sending works (`:CursorCodeSend`)
- ✅ No conflicts with claudecode.nvim
- ✅ Correct branding (CursorCode, not ClaudeCode)
- ✅ All debug messages work

### Commands Available
- `:CursorCode` - Toggle cursor terminal
- `:CursorCodeOpen` - Open cursor terminal
- `:CursorCodeClose` - Close cursor terminal
- `:CursorCodeAdd <file>` - Add file to cursor
- `:CursorCodeSend` - Send selection to cursor
- `:CursorCodeTreeAdd` - Add from file tree

### Installation

```lua
return {
  -- Official claudecode.nvim (Claude Code)
  {
    "coder/claudecode.nvim",
    config = true,
  },
  
  -- This plugin (Cursor CLI)
  {
    "chanwutk/cursor-cli.nvim",
    name = "cursorcode",  -- REQUIRED: Different module name
    dependencies = { "folke/snacks.nvim" },
    -- No config needed - auto-setup on VimEnter
  },
}
```

Both plugins work side-by-side without conflicts!

## Documentation Files

All fixes are documented:
1. REPOSITORY_RENAME.md
2. SYNTAX_ERROR_FIX.md
3. COMMAND_REGISTRATION_FIX.md
4. ENV_ERROR_FIX.md
5. COMMAND_NAME_FIX.md
6. PLUGIN_CONFLICT_FIX.md
7. SELECTION_TRACKING_FIX.md
8. LOGGER_IMPORT_FIX.md
9. FUNCTION_NAME_AND_SELECTION_FIX.md
10. COMPLETE_FIX_SUMMARY.md (overview)
11. SORRY_ABOUT_THAT.md (fix #7 apology)

## Success! 🎉

The cursor-cli.nvim plugin is now:
- ✅ Fully functional
- ✅ Production ready
- ✅ Well documented
- ✅ No conflicts with claudecode.nvim
- ✅ Simple and maintainable

Users can now use both Claude Code and Cursor CLI in Neovim simultaneously!
