# Fix for CursorCode Command Registration Issue

## Problem
Users reported the error:
```
:CursorCode
E492: Not an editor command: CursorCode
```

## Root Cause
The plugin was not automatically registering commands unless users explicitly called `require("cursorcode").setup()`. The plugin loader only called setup if `vim.g.cursorcode_auto_setup` was set, which most users wouldn't do when installing via package managers.

## Solution Implemented

### Changes Made

1. **plugin/cursorcode.lua** - Auto-setup on load
   ```lua
   -- Before: Only setup if vim.g.cursorcode_auto_setup was set
   if vim.g.cursorcode_auto_setup then
     -- setup code
   end
   
   -- After: Always setup with defaults
   vim.defer_fn(function()
     local config = vim.g.cursorcode_user_config or vim.g.cursorcode_auto_setup or {}
     cursorcode.setup(config)
   end, 0)
   ```

2. **lua/cursorcode/init.lua** - Guard against duplicate commands
   ```lua
   function M._create_commands()
     -- Guard against duplicate command creation
     if M.state.commands_created then
       return
     end
     
     -- ... create commands ...
     
     M.state.commands_created = true
   end
   ```

### How It Works

1. When Neovim loads the plugin (`plugin/cursorcode.lua`), it:
   - Sets the loaded flag
   - Schedules setup to run via `vim.defer_fn()`
   - Looks for user config in `vim.g.cursorcode_user_config` or `vim.g.cursorcode_auto_setup`
   - Falls back to empty config `{}` if no user config provided

2. The `setup()` function:
   - Applies configuration
   - Sets up terminal module
   - Creates commands via `_create_commands()`
   - Marks as initialized

3. The `_create_commands()` function:
   - Checks if commands were already created
   - Creates all CursorCode* commands
   - Sets flag to prevent duplicate creation

### Benefits

✅ Commands available immediately after plugin loads  
✅ No configuration required for basic usage  
✅ Users can still customize via explicit `setup()` call  
✅ No duplicate command errors if setup is called multiple times  
✅ Works with all package managers (lazy.nvim, packer, etc.)  

### User Experience

**Minimal Install (works out of the box):**
```lua
{
  "chanwutk/cursor-cli.nvim",
  name = "cursorcode",
  dependencies = { "folke/snacks.nvim" },
}
```
Commands are available: `:CursorCode`, `:CursorCodeAdd`, etc.

**Custom Config (still supported):**
```lua
{
  "chanwutk/cursor-cli.nvim",
  name = "cursorcode",
  dependencies = { "folke/snacks.nvim" },
  config = function()
    require("cursorcode").setup({
      terminal_cmd = "cursor",
      log_level = "debug",
    })
  end,
}
```

### Testing Verification

- ✅ Syntax validation passed
- ✅ Auto-setup logic verified
- ✅ Guard against duplicate commands added
- ✅ Documentation updated

### Files Modified

1. `plugin/cursorcode.lua` - Auto-setup mechanism
2. `lua/cursorcode/init.lua` - Duplicate command guard
3. `CURSORCODE_README.md` - Updated installation docs
4. `QUICKSTART.md` - Updated quick start guide

## Expected Behavior After Fix

```vim
" After installing the plugin, these commands work immediately:
:CursorCode           " ✓ Opens cursor terminal
:CursorCodeAdd %      " ✓ Adds current file
:CursorCodeSend       " ✓ Sends visual selection
:CursorCodeTreeAdd    " ✓ Adds from file explorer
```

No additional configuration needed!
