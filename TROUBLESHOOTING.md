# Troubleshooting Guide

## Common Errors

### 1. Command Not Available: "E492: Not an editor command: CursorCode"

If you see this error:
```
:CursorCode
E492: Not an editor command: CursorCode
```

This means the plugin loaded but commands were not registered.

#### Quick Fix

Try restarting Neovim. If that doesn't work:

1. **Check if plugin is loaded**:
   ```vim
   :lua print(vim.g.loaded_cursorcode)
   ```
   Should output `1`. If not, the plugin didn't load.

2. **Manually trigger setup**:
   ```vim
   :lua require("cursorcode").setup()
   ```
   Then try `:CursorCode` again.

3. **Check for errors**:
   ```vim
   :messages
   ```
   Look for any error messages about cursorcode.

4. **Verify module loads**:
   ```vim
   :lua print(require("cursorcode").version:string())
   ```
   Should print version number (e.g., "1.0.0").

#### Root Causes

This issue was fixed in recent versions by:
- Using VimEnter autocmd instead of vim.defer_fn
- Better error handling in plugin loader
- Lazy config loading to avoid early failures

**Make sure you have the latest version**:
```vim
:Lazy update
```

### 2. Module 'cursorcode' Not Found

If you see this error:
```
module 'cursorcode' not found:
  no field package.preload['cursorcode']
  ...
```

This means Neovim cannot find the `cursorcode` Lua module. This is typically an installation or configuration issue.

## Solutions

### Solution 1: Verify Package Manager Installation

The most common cause is that the plugin isn't properly installed or loaded by your package manager.

#### For lazy.nvim

Make sure you're using the correct repository name and module name:

```lua
{
  "chanwutk/cursor-cli.nvim",  -- ✅ Correct repository name
  name = "cursorcode",           -- ✅ Important: set internal name
  dependencies = { "folke/snacks.nvim" },
  -- Config is optional - commands auto-register on load
}
```

**Key points:**
- Repository: `"chanwutk/cursor-cli.nvim"`
- Module name: `name = "cursorcode"` (this is crucial!)
- The module name tells lazy.nvim what to call internally

#### For packer.nvim

```lua
use {
  'chanwutk/cursor-cli.nvim',
  as = 'cursorcode',  -- ✅ Important: set internal name
  requires = { 'folke/snacks.nvim' },
}
```

### Solution 2: Reinstall the Plugin

#### With lazy.nvim

1. Remove the plugin:
   ```vim
   :Lazy clean
   ```

2. Restart Neovim

3. Install the plugin:
   ```vim
   :Lazy install
   ```

4. Verify installation:
   ```vim
   :Lazy
   ```
   Look for `cursorcode` in the list

#### With packer.nvim

1. Clean and reinstall:
   ```vim
   :PackerClean
   :PackerInstall
   ```

### Solution 3: Check Runtimepath

Verify the plugin is in your runtimepath:

```vim
:lua print(vim.inspect(vim.api.nvim_list_runtime_paths()))
```

Look for a path containing `cursor-cli.nvim` or `cursorcode`.

### Solution 4: Manual Verification

Check if the module files exist:

```vim
:lua print(vim.fn.stdpath('data') .. '/lazy/cursorcode')
```

The path should exist and contain `lua/cursorcode/init.lua`.

### Solution 5: Check for Naming Conflicts

If you previously had `claudecode.nvim` installed, make sure it's properly removed or that both plugins use different names:

```lua
-- Both plugins can coexist
{
  "coder/claudecode.nvim",      -- Claude Code plugin
  config = true,
},
{
  "chanwutk/cursor-cli.nvim",   -- Cursor CLI plugin
  name = "cursorcode",            -- Different internal name
  dependencies = { "folke/snacks.nvim" },
}
```

### Solution 6: Debug Loading

Add debug output to see what's happening:

```lua
{
  "chanwutk/cursor-cli.nvim",
  name = "cursorcode",
  dependencies = { "folke/snacks.nvim" },
  init = function()
    print("Loading cursor-cli.nvim...")
  end,
  config = function()
    print("Configuring cursorcode...")
    local ok, cursorcode = pcall(require, "cursorcode")
    if ok then
      print("✓ cursorcode module loaded successfully")
      cursorcode.setup({})
    else
      print("✗ Failed to load cursorcode:", cursorcode)
    end
  end,
}
```

### Solution 7: Check Your init.lua

The error mentions `init.lua:43`. Check line 43 of your config:

```lua
-- Make sure you're not trying to require cursorcode before it's installed
-- This is WRONG if it's not wrapped in a config function:
local cursorcode = require("cursorcode")  -- ❌ This will fail if not in config/init

-- This is CORRECT:
{
  "chanwutk/cursor-cli.nvim",
  name = "cursorcode",
  config = function()
    require("cursorcode").setup({})  -- ✅ Module loaded after plugin is available
  end,
}
```

### Solution 8: Minimal Working Configuration

Try this minimal configuration to test:

```lua
-- In your lazy.nvim setup
require("lazy").setup({
  {
    "chanwutk/cursor-cli.nvim",
    name = "cursorcode",
    dependencies = { "folke/snacks.nvim" },
  },
})
```

Then test:
```vim
:lua print(require("cursorcode").version:string())
```

Should output the version number if working correctly.

## Common Mistakes

### ❌ Wrong Repository Name
```lua
"chanwutk/claudecode.nvim"  -- Old name
```

### ✅ Correct Repository Name
```lua
"chanwutk/cursor-cli.nvim"  -- New name
```

### ❌ Missing Module Name
```lua
{
  "chanwutk/cursor-cli.nvim",
  -- Missing: name = "cursorcode"
}
```

### ✅ Correct Module Name
```lua
{
  "chanwutk/cursor-cli.nvim",
  name = "cursorcode",  -- This is required!
}
```

## Still Not Working?

1. Check lazy.nvim logs:
   ```vim
   :Lazy log
   ```

2. Check for error messages:
   ```vim
   :messages
   ```

3. Verify Neovim version:
   ```vim
   :version
   ```
   Requires Neovim >= 0.8.0

4. Try installing with verbose logging:
   ```vim
   :Lazy! install
   ```

## Getting Help

If you're still experiencing issues:

1. Provide your exact lazy.nvim/packer configuration
2. Run `:checkhealth` and share the output
3. Share the full error message from `:messages`
4. Verify the plugin files exist at the expected location

The issue is almost always related to:
- Incorrect repository name in config
- Missing `name = "cursorcode"` in lazy.nvim
- Plugin not properly installed
- Trying to require the module before it's loaded
