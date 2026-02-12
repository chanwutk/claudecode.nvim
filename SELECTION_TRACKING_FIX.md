# Selection Tracking Error Fix

## Issue

Users encountered this error when trying to send selections to Cursor:

```
[ClaudeCode] [selection] [ERROR] Selection tracking is not enabled.
```

## Problems Identified

### 1. Wrong Plugin Branding in Logger

The logger module was using "ClaudeCode" branding instead of "CursorCLI":
- Log prefix: `[ClaudeCode]` should be `[CursorCLI]`
- Notification titles: "ClaudeCode Error/Warning" should be "CursorCLI Error/Warning"
- Module documentation referred to "Claude Code" instead of "Cursor Code"

### 2. Selection Tracking Incompatibility

The selection tracking module was copied from the claudecode plugin but never adapted for cursor-cli's architecture:

**ClaudeCode's Architecture**:
- Has WebSocket server
- Real-time selection broadcasting to Claude Code via MCP protocol
- Selection updates sent automatically as user moves cursor

**CursorCLI's Architecture**:
- No WebSocket server (types text directly to terminal)
- @mentions sent on-demand via commands like `:CursorCLIAdd`
- No need for real-time selection broadcasting

**The Problem**:
- `selection.lua` expected a `server` object to broadcast to
- `init.lua` tried to call `selection_module.setup()` which didn't exist
- Selection tracking was enabled by default but couldn't work without server

## The Fix

### 1. Fixed Logger Branding

**File**: `lua/cursor-cli/logger.lua`

**Changes**:
```lua
-- Before
local prefix = "[ClaudeCode]"
vim.notify(prefix .. " " .. message, vim.log.levels.ERROR, { title = "ClaudeCode Error" })

-- After  
local prefix = "[CursorCLI]"
vim.notify(prefix .. " " .. message, vim.log.levels.ERROR, { title = "CursorCLI Error" })
```

**Also Updated**:
- Line 3: Module description comment
- Line 33: Default notification message
- Lines 77, 79: Notification titles

### 2. Disabled Selection Tracking

**File**: `lua/cursor-cli/config.lua`

**Changes**:
```lua
-- Before
M.defaults = {
  track_selection = true,  -- Doesn't work without WebSocket server!
  -- ...
}

-- After
M.defaults = {
  track_selection = false,  -- Cursorcode doesn't need selection tracking
  -- ...
}
```

**Reason**: Cursorcode doesn't have a WebSocket server to broadcast selections to. Commands like `:CursorCLIAdd` and `:CursorCLISend` directly capture and send the current selection when invoked.

**File**: `lua/cursor-cli/init.lua`

**Removed** (lines 209-215):
```lua
-- This code tried to setup selection tracking but selection.lua has no setup() function
if M.state.config.track_selection then
  local selection_ok, selection_module = pcall(require, "cursor-cli.selection")
  if selection_ok and type(selection_module.setup) == "function" then
    selection_module.setup(M.state.config)
  end
end
```

## Why This Solution Works

### Selection Capture Still Works

Even with selection tracking disabled, selections still work perfectly:

1. **User makes visual selection**
2. **User runs** `:CursorCLISend` or `:CursorCLIAdd`
3. **Plugin captures selection** from the current buffer
4. **Plugin formats** as `@filename:start-end`
5. **Plugin types** the @mention directly into cursor terminal

**No real-time tracking needed** - selections are captured on-demand when the user explicitly invokes a command.

### Benefits

1. ✅ **Simplified Architecture**: No unused selection tracking code
2. ✅ **No Errors**: Selection tracking won't try to initialize without a server
3. ✅ **Correct Branding**: All messages show "[CursorCLI]" not "[ClaudeCode]"
4. ✅ **Functionality Preserved**: Commands like :CursorCLISend still work perfectly

## Verification

### Test That Errors Are Gone

```vim
" Make a visual selection
:normal! ggVG

" Send to cursor - should work without error
:CursorCLISend
```

**Before**: `[ClaudeCode] [selection] [ERROR] Selection tracking is not enabled.`  
**After**: Selection sent to cursor successfully with `@filename:1-end` format

### Test Logger Branding

```vim
" Trigger any error (e.g., send without terminal)
:CursorCLIAdd nonexistent.txt
```

**Before**: Error shows `[ClaudeCode] ...`  
**After**: Error shows `[CursorCLI] ...`

### Verify Config

```vim
:lua print(vim.inspect(require("cursor-cli").state.config.track_selection))
```

**Expected**: `false`

## For Users

### What Changed

1. **Error messages now use "CursorCLI" branding** instead of "ClaudeCode"
2. **Selection tracking disabled by default** (wasn't working anyway)
3. **Commands still work the same** - you can still send files and selections to cursor

### No Action Required

This fix is automatic. After updating the plugin:
- `:CursorCLIAdd %` - Still works
- `:CursorCLISend` with visual selection - Still works  
- No more "[ClaudeCode] [selection] [ERROR]" messages

### If You Want to Enable Selection Tracking

**Don't** - it won't work because cursor-cli doesn't have a WebSocket server. The on-demand approach (using commands) is the correct way for cursor-cli.

## Technical Details

### Files Modified

1. **lua/cursor-cli/logger.lua** (5 changes)
   - Line 3: Module description
   - Line 33: Default error message  
   - Line 47: Log prefix
   - Line 77: Error notification title
   - Line 79: Warning notification title

2. **lua/cursor-cli/config.lua** (1 change)
   - Line 14: `track_selection = false` (was `true`)

3. **lua/cursor-cli/init.lua** (removed lines 209-215)
   - Deleted non-functional selection tracking setup code

### Why Selection Module Remains

The `lua/cursor-cli/selection.lua` file still exists but is not used. It could be removed in a future cleanup, but keeping it:
- Maintains code similarity with claudecode for easier comparison
- Allows future enhancements if needed
- Doesn't cause problems since it's not initialized

## Related Fixes

This is part of a series of fixes to make cursor-cli work correctly:

1. ✅ Command registration timing (VimEnter autocmd)
2. ✅ Config syntax error (missing parenthesis)
3. ✅ Invalid env argument (conditional env passing)
4. ✅ Wrong command name ("cursor" → "agent")
5. ✅ Plugin conflict (removed claudecode files)
6. ✅ **Selection tracking and logger branding** (this fix)

The plugin should now work completely end-to-end!
