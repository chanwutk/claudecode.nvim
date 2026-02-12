# Logger Import Fix

## Issue
Users encountered this error when sending files to cursor:
```
Error executing Lua callback: ...lua/cursor-cli/terminal.lua:585: 
attempt to index global 'logger' (a nil value)
stack traceback:
  terminal.lua:585: in function 'send_keys'
  init.lua:115: in function '_send_at_mention'
  init.lua:144: in function 'send_at_mention'
  init.lua:288: in function
```

Despite the error, the file was actually sent to cursor successfully - the error only occurred in the logging code.

## Root Cause

The `terminal.lua` file used `logger` at **14 different locations** but **never imported the logger module**.

### Locations where logger was used (without import):
- Line 115: `logger.debug("terminal", "Using custom table provider")`
- Line 119: `logger.warn(...)`
- Line 125: `logger.warn("terminal", "Invalid custom table provider...")`
- Line 140: `logger.warn("terminal", "'snacks' provider configured...")`
- Line 158: `logger.warn(...)`
- Line 166: `logger.debug("terminal", "Using native terminal provider")`
- Line 170: `logger.debug("terminal", "Using no-op terminal provider...")`
- Line 173: `logger.warn("terminal", "'none' provider configured...")`
- Line 176: `logger.warn(...)`
- Line 181: `logger.warn(...)`
- Line 572: `logger.warn("terminal", "Cannot send keys: terminal not active")`
- Line 579: `logger.warn("terminal", "Cannot send keys: no terminal job found")`
- Line 585: `logger.debug("terminal", "Sent text to cursor terminal...")` ← **Error occurred here**

### Comparison with other modules
All other cursor-cli modules properly import logger:

```lua
-- init.lua
local logger = require("cursor-cli.logger")

-- integrations.lua
local logger = require("cursor-cli.logger")

-- selection.lua
local logger = require("cursor-cli.logger")

-- visual_commands.lua
local logger = require("cursor-cli.logger")

-- terminal.lua (BEFORE FIX)
-- ❌ NO IMPORT!
```

## The Fix

Added the missing logger import at the top of `terminal.lua`:

```lua
--- Module to manage a dedicated vertical split terminal for Cursor CLI.
--- Supports Snacks.nvim or a native Neovim terminal fallback.
--- @module 'cursor-cli.terminal'

local M = {}

local logger = require("cursor-cli.logger")  -- ← ADDED THIS LINE

---@type table
local defaults = {
  -- ...
}
```

### Changed Files
- `lua/cursor-cli/terminal.lua` - Added logger import on line 7

## Impact

### Before Fix
```vim
:CursorCodeAdd %
" File sends successfully...
" But then shows error:
Error: attempt to index global 'logger' (a nil value)
```

### After Fix
```vim
:CursorCodeAdd %
" File sends successfully
" Debug messages work correctly:
[CursorCode] [terminal] [DEBUG] Sent text to cursor terminal: @filename
" No errors!
```

## Verification

To verify the fix is working:

1. **Update the plugin**:
   ```vim
   :Lazy update cursor-cli.nvim
   " Or for packer users:
   :PackerUpdate
   ```

2. **Restart Neovim**

3. **Test sending a file**:
   ```vim
   :CursorCode          " Open cursor terminal
   :CursorCodeAdd %     " Send current file
   ```

4. **Should work without errors**. If you have debug logging enabled:
   ```lua
   require("cursor-cli").setup({
     log_level = "debug",
   })
   ```
   
   You should see messages like:
   ```
   [CursorCode] [terminal] [DEBUG] Sent text to cursor terminal: @yourfile.lua
   ```

## Prevention

This was a simple oversight when creating the terminal.lua module. The logger was being used but never imported.

**Best practice**: When copying code from one module to another:
1. Check all external dependencies (like `logger`)
2. Ensure all `require()` statements are included
3. Test all code paths, including logging calls

## Related Documentation

- [COMPLETE_FIX_SUMMARY.md](./COMPLETE_FIX_SUMMARY.md) - Overview of all fixes
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - General troubleshooting guide
