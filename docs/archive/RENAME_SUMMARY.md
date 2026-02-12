# Major Rename: cursorcode → cursor-cli

## Summary

This document describes the major rename that changed the plugin from using `cursorcode` as the package name and `CursorCode*` as command names to `cursor-cli` and `CursorCLI*` respectively.

## What Changed

### Module Name
- **Before**: `cursorcode`
- **After**: `cursor-cli`

### Directory Structure
- **Before**: `lua/cursorcode/`
- **After**: `lua/cursor-cli/`

### Plugin Loader
- **Before**: `plugin/cursorcode.lua`
- **After**: `plugin/cursor-cli.lua`

### Commands

| Before | After |
|--------|-------|
| `:CursorCode` | `:CursorCLI` |
| `:CursorCodeOpen` | `:CursorCLIOpen` |
| `:CursorCodeClose` | `:CursorCLIClose` |
| `:CursorCodeFocus` | `:CursorCLIFocus` |
| `:CursorCodeAdd` | `:CursorCLIAdd` |
| `:CursorCodeSend` | `:CursorCLISend` |
| `:CursorCodeTreeAdd` | `:CursorCLITreeAdd` |

### Configuration Variables

| Before | After |
|--------|-------|
| `vim.g.loaded_cursorcode` | `vim.g.loaded_cursor_cli` |
| `vim.g.cursorcode_user_config` | `vim.g.cursor_cli_user_config` |
| `vim.g.cursorcode_auto_setup` | `vim.g.cursor_cli_auto_setup` |

### Module Requires

| Before | After |
|--------|-------|
| `require("cursorcode")` | `require("cursor-cli")` |
| `require("cursorcode.terminal")` | `require("cursor-cli.terminal")` |
| `require("cursorcode.selection")` | `require("cursor-cli.selection")` |
| etc. | etc. |

## Impact on Users

### Breaking Changes

This is a **major breaking change** for existing users:

1. **Old command names no longer work**
   - `:CursorCode` → Error: "Not an editor command"
   - Users must update to `:CursorCLI`

2. **Module name changed**
   - Old: `require("cursorcode").setup({})`
   - New: `require("cursor-cli").setup({})`

3. **Configuration variables changed**
   - Users with custom `vim.g.cursorcode_*` settings need to update

### Migration Guide

#### Update lazy.nvim Configuration

**Before**:
```lua
{
  "chanwutk/cursor-cli.nvim",
  name = "cursorcode",  -- Old module name
  config = function()
    require("cursorcode").setup({})  -- Old require
  end,
}
```

**After**:
```lua
{
  "chanwutk/cursor-cli.nvim",
  name = "cursor-cli",  -- New module name
  config = function()
    require("cursor-cli").setup({})  -- New require
  end,
}
```

#### Update Keybindings

**Before**:
```lua
{ "<leader>cc", "<cmd>CursorCode<cr>", desc = "Toggle Cursor" },
{ "<leader>ca", "<cmd>CursorCodeAdd %<cr>", desc = "Add to Cursor" },
{ "<leader>cs", "<cmd>CursorCodeSend<cr>", desc = "Send to Cursor" },
```

**After**:
```lua
{ "<leader>cc", "<cmd>CursorCLI<cr>", desc = "Toggle Cursor" },
{ "<leader>ca", "<cmd>CursorCLIAdd %<cr>", desc = "Add to Cursor" },
{ "<leader>cs", "<cmd>CursorCLISend<cr>", desc = "Send to Cursor" },
```

#### Update Custom Configuration

**Before**:
```lua
vim.g.cursorcode_user_config = {
  terminal_cmd = "agent",
}
```

**After**:
```lua
vim.g.cursor_cli_user_config = {
  terminal_cmd = "agent",
}
```

## Rationale

The rename was done to:

1. **Better align package name with CLI tool**
   - The CLI tool is called `cursor-cli` (or `agent`)
   - Package name `cursor-cli` is more descriptive

2. **Clearer command names**
   - `CursorCLI*` makes it obvious these are cursor CLI commands
   - Distinguishes from other cursor-related plugins

3. **Consistency with repository name**
   - Repository: `chanwutk/cursor-cli.nvim`
   - Package: `cursor-cli`
   - Commands: `CursorCLI*`

## Implementation Details

### Files Changed

**Code**:
- 14 Lua files renamed/updated
- All 13 module files in `lua/cursor-cli/`
- Plugin loader `plugin/cursor-cli.lua`

**Documentation**:
- 33 markdown files updated
- All command examples updated
- All configuration examples updated

### Total Changes

- **361** occurrences of `CursorCode` → `CursorCLI`
- **63** occurrences of `cursorcode` → `cursor-cli`
- **14** files moved/renamed
- **33** documentation files updated

## Verification

To verify the rename was successful:

```vim
" Check module loads
:lua require("cursor-cli")

" Check commands exist
:CursorCLI
:CursorCLIAdd
:CursorCLISend

" Check old commands are gone
:CursorCode  " Should error: "Not an editor command"
```

## Support

If you encounter issues after the rename:

1. **Update your configuration** following the migration guide above
2. **Reinstall the plugin**:
   ```vim
   :Lazy clean
   :Lazy install
   ```
3. **Restart Neovim** to ensure all changes take effect

## Timeline

- **Date**: 2026-02-12
- **Commits**:
  - Code rename: `856c7de`
  - Documentation update: `b262452`

This rename represents a major version change and brings the plugin naming in line with best practices and user expectations.
