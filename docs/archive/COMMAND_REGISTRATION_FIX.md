# Fix: CursorCLI Command Not Available

## Issue

Users reported that even after following the setup instructions, the `:CursorCLI` command was not available:

```
:CursorCLI
E492: Not an editor command: CursorCLI
```

## Root Causes

### 1. Race Condition with `vim.defer_fn`

The original plugin loader used `vim.defer_fn(fn, 0)` to schedule the setup:

```lua
vim.defer_fn(function()
  local ok, cursor-cli = pcall(require, "cursor-cli")
  if ok then
    cursor-cli.setup(config)
  end
end, 0)
```

**Problem**: `defer_fn` schedules the function to run "later", but there's no guarantee when. Users could try to use `:CursorCLI` before the deferred function executed, resulting in the command not being found.

### 2. Early Config Module Loading

The `init.lua` file required the config module at the module level:

```lua
M.state = {
  config = require("cursor-cli.config").defaults,
  initialized = false,
}
```

**Problem**: If the config module had any issues (like the recent syntax error), it would prevent the entire module from loading. This early require also created potential for circular dependencies.

### 3. Insufficient Error Handling

If the setup failed for any reason, the error wasn't clearly reported, making it hard to diagnose issues.

## The Fix

### 1. Improved Plugin Loader

Replaced `vim.defer_fn` with a proper VimEnter autocmd:

```lua
local function setup_cursor-cli()
  local ok, cursor-cli = pcall(require, "cursor-cli")
  if ok then
    local config = vim.g.cursor-cli_user_config or vim.g.cursor-cli_auto_setup or {}
    local setup_ok, setup_err = pcall(cursor-cli.setup, config)
    if not setup_ok then
      vim.api.nvim_err_writeln("cursor-cli.nvim: setup failed: " .. tostring(setup_err))
    end
  else
    vim.api.nvim_err_writeln("cursor-cli.nvim: failed to load module: " .. tostring(cursor-cli))
  end
end

if vim.v.vim_did_enter == 1 then
  setup_cursor-cli()
else
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      setup_cursor-cli()
    end,
    once = true,
  })
end
```

**Benefits**:
- ✅ Reliable timing: VimEnter ensures Neovim is fully initialized
- ✅ Immediate execution if Vim already started
- ✅ Better error handling with separate pcall for setup
- ✅ Clear error messages

### 2. Lazy Config Loading

Changed config initialization to be lazy:

```lua
M.state = {
  config = nil, -- Will be set during setup
  initialized = false,
}
```

The config is now properly initialized in the `setup()` function:

```lua
function M.setup(opts)
  opts = opts or {}
  local config = require("cursor-cli.config")
  M.state.config = config.apply(opts)
  -- ...
end
```

**Benefits**:
- ✅ No early module loading
- ✅ Avoids circular dependencies
- ✅ Config only loaded when actually needed

## Verification

After the fix, you can verify it works:

```vim
" 1. Check plugin is loaded
:lua print(vim.g.loaded_cursor-cli)
" Should output: 1

" 2. Check module version
:lua print(require("cursor-cli").version:string())
" Should output: 1.0.0 (or similar)

" 3. Try the command
:CursorCLI
" Should open the cursor terminal (or show appropriate error if cursor not installed)

" 4. List all CursorCLI commands
:command CursorCLI
" Should show the CursorCLI command and its description
```

## For Users

### If You're Still Having Issues

1. **Update the plugin**:
   ```vim
   :Lazy update
   ```
   Then restart Neovim.

2. **Check for errors**:
   ```vim
   :messages
   ```

3. **Manually trigger setup** (if needed):
   ```vim
   :lua require("cursor-cli").setup()
   ```

4. **Verify installation**:
   ```vim
   :Lazy
   ```
   Make sure `cursor-cli` is in the list.

### Proper Configuration

Make sure your lazy.nvim config includes the `name` field:

```lua
{
  "chanwutk/cursor-cli.nvim",
  name = "cursor-cli",  -- ✅ This is required!
  dependencies = { "folke/snacks.nvim" },
}
```

## Related Issues

- Syntax error in config.lua (fixed separately)
- Module loading errors
- Repository rename from claudecode.nvim to cursor-cli.nvim

## Timeline

- **Issue reported**: Commands not available after setup
- **Root cause**: Race condition with vim.defer_fn
- **Fix implemented**: VimEnter autocmd + lazy config loading
- **Status**: ✅ Fixed

## Prevention

To prevent similar issues in the future:

1. **Test plugin loading**:
   - Verify commands are available after fresh install
   - Test with both lazy.nvim and packer.nvim
   - Check error messages are helpful

2. **Use reliable autocmds**:
   - Prefer VimEnter for plugin initialization
   - Avoid vim.defer_fn for critical setup tasks

3. **Lazy-load modules**:
   - Don't require modules at the top level
   - Load modules in functions when needed
   - Avoids circular dependencies

4. **Better error handling**:
   - Use pcall for operations that might fail
   - Provide clear error messages
   - Log errors to :messages
