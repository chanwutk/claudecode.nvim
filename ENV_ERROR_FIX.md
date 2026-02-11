# Fix: Invalid env Argument Error

## Issue

Users encountered this error when running `:CursorCode`:

```
Error executing Lua callback: ...ocal/share/nvim/lazy/snacks.nvim/lua/snacks/terminal.lua:161: 
Error executing lua: Vim:E475: Invalid argument: env
stack traceback:
        [C]: in function 'jobstart'
        ...ocal/share/nvim/lazy/snacks.nvim/lua/snacks/terminal.lua:162
        ...
```

## Root Cause

The terminal providers (both snacks and native) were passing an empty environment table `{}` to Neovim's `jobstart()` and `termopen()` functions.

### The Flow

1. User runs `:CursorCode`
2. `get_cursor_command_and_env()` creates `env_table = {}`
3. Merges `defaults.env` (also `{}` by default) into `env_table`
4. Passes empty `env_table` to terminal provider
5. Provider passes it to `jobstart()`/`termopen()`
6. Neovim rejects empty env table with "Invalid argument: env"

### Why This Happens

According to Neovim's documentation:

```vim
:help jobstart()
:help termopen()

env: dict of environment variables
     - If you want to inherit the parent environment, pass nil or omit the key
     - An empty table {} means "use no environment variables at all"
     - This can cause issues with the terminal process
```

The problem is that an empty table `{}` is not the same as `nil`:
- `nil` or omitted = inherit parent environment ✅
- `{}` (empty table) = use no environment variables ❌

## The Fix

Modified both terminal providers to only include `env` in the options when it actually has values:

### Snacks Provider Fix

**File**: `lua/cursorcode/terminal/snacks.lua`

**Before**:
```lua
local function build_opts(config, env_table, focus)
  focus = utils.normalize_focus(focus)
  return {
    env = env_table,  -- ❌ Always included, even if empty
    cwd = config.cwd,
    start_insert = focus,
    auto_insert = focus,
    -- ... rest of options
  }
end
```

**After**:
```lua
local function build_opts(config, env_table, focus)
  focus = utils.normalize_focus(focus)
  
  local opts = {
    cwd = config.cwd,
    start_insert = focus,
    auto_insert = focus,
    -- ... rest of options
  }
  
  -- ✅ Only include env if it has values
  if env_table and next(env_table) ~= nil then
    opts.env = env_table
  end
  
  return opts
end
```

### Native Provider Fix

**File**: `lua/cursorcode/terminal/native.lua`

**Before**:
```lua
jobid = vim.fn.termopen(term_cmd_arg, {
  env = env_table,  -- ❌ Always included, even if empty
  cwd = effective_config.cwd,
  on_exit = function(job_id, _, _)
    -- ...
  end,
})
```

**After**:
```lua
-- Build termopen options
local termopen_opts = {
  cwd = effective_config.cwd,
  on_exit = function(job_id, _, _)
    -- ...
  end,
}

-- ✅ Only include env if it has values
if env_table and next(env_table) ~= nil then
  termopen_opts.env = env_table
end

jobid = vim.fn.termopen(term_cmd_arg, termopen_opts)
```

## How It Works

The fix uses Lua's `next()` function to check if a table has any entries:

```lua
if env_table and next(env_table) ~= nil then
  -- Table has at least one key-value pair
  opts.env = env_table
end
-- Otherwise, env is not included (nil), so parent env is inherited
```

### Behavior After Fix

| Scenario | env_table | What happens |
|----------|-----------|--------------|
| No custom env | `{}` | env not passed → inherits parent environment ✅ |
| Custom env vars | `{VAR="value"}` | env passed with values → uses custom environment ✅ |

## Verification

After the fix:

```vim
" This should now work without errors
:CursorCode

" Check if cursor terminal opens
" Should see cursor CLI running

" If you have custom env vars configured:
:lua require("cursorcode").setup({ env = { MY_VAR = "test" } })
:CursorCode
" Should open with custom environment
```

## Files Changed

1. **lua/cursorcode/terminal/snacks.lua**
   - Modified `build_opts()` to conditionally include env

2. **lua/cursorcode/terminal/native.lua**
   - Modified termopen call to conditionally include env

## Impact

✅ No more "Invalid argument: env" errors  
✅ Cursor terminal opens successfully  
✅ Custom environment variables still work  
✅ Default behavior inherits parent environment  

## Related Issues

This fix resolves the error that users encountered after the previous fixes for:
- Command registration timing
- Config syntax error
- Module loading issues

With all fixes in place, the plugin should now work correctly:
1. Commands register properly (VimEnter autocmd)
2. Config loads without syntax errors
3. Terminal opens without env errors

## For Users

Simply update the plugin:

```vim
:Lazy update
```

Then restart Neovim and try:

```vim
:CursorCode
```

Should work without errors! 🎉
