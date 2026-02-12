# Fix: Plugin Conflict Resolution

## Issue

After installing cursor-cli.nvim, users reported that the official claudecode.nvim plugin stopped working:

```
E492: Not an editor command: ClaudeCode
```

## Root Cause

This repository (`chanwutk/cursor-cli.nvim`) initially contained BOTH:
1. **claudecode module** (`lua/claudecode/` + `plugin/claudecode.lua`)
2. **cursor-cli module** (`lua/cursor-cli/` + `plugin/cursor-cli.lua`)

When users installed BOTH plugins:
- Official: `coder/claudecode.nvim` 
- This repo: `chanwutk/cursor-cli.nvim`

The claudecode files in THIS repository **conflicted** with the official claudecode.nvim plugin:
- Both provided `lua/claudecode/init.lua`
- Both tried to create `ClaudeCode*` commands
- One shadowed the other, causing command registration to fail

### Why This Happened

This repository was originally a fork that modified claudecode to support cursor. However, the requirement changed to:

> "This plugin should work **alongside** the base claudecode.nvim plugin"

This meant we needed to:
1. Keep the official `coder/claudecode.nvim` for Claude Code
2. Create a NEW standalone plugin for Cursor CLI
3. Ensure NO file/module conflicts between them

## The Fix

### Removed All ClaudeCode Files

Deleted **36 files** from this repository:

#### Plugin Loader
- `plugin/claudecode.lua` ❌

#### ClaudeCode Module
- `lua/claudecode/` (entire directory) ❌
  - config.lua
  - cwd.lua
  - diff.lua
  - init.lua
  - integrations.lua
  - lockfile.lua
  - logger.lua
  - selection.lua
  - terminal.lua
  - types.lua
  - utils.lua
  - visual_commands.lua
  - server/ (6 files)
  - terminal/ (4 files)
  - tools/ (12 files)

### What Remains

This repository now contains **ONLY** the cursor-cli plugin:

#### Plugin Loader
- `plugin/cursor-cli.lua` ✅

#### CursorCode Module
- `lua/cursor-cli/` ✅
  - config.lua
  - cwd.lua
  - init.lua
  - integrations.lua
  - logger.lua
  - selection.lua
  - terminal.lua
  - utils.lua
  - visual_commands.lua
  - terminal/ (4 providers)

## Repository Purpose

**This repository (`chanwutk/cursor-cli.nvim`) now provides ONLY:**
- Module: `cursor-cli`
- Commands: `CursorCode*`
- CLI: `agent` (cursor-cli command)
- No Claude Code support

**For Claude Code, users should install:**
- Repository: `coder/claudecode.nvim`
- Module: `claudecode`
- Commands: `ClaudeCode*`
- CLI: `claude`

## Installation Guide

### Install Both Plugins

Users can now install BOTH plugins without conflicts:

```lua
return {
  -- Official Claude Code plugin
  {
    "coder/claudecode.nvim",
    config = true,
    keys = {
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>aa", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add to Claude" },
    },
  },
  
  -- Cursor CLI plugin (this repo)
  {
    "chanwutk/cursor-cli.nvim",
    name = "cursor-cli",  -- Important: different module name
    dependencies = { "folke/snacks.nvim" },
    keys = {
      { "<leader>cc", "<cmd>CursorCode<cr>", desc = "Toggle Cursor" },
      { "<leader>cb", "<cmd>CursorCodeAdd %<cr>", desc = "Add to Cursor" },
    },
  },
}
```

### Result

After installation:
- ✅ `:ClaudeCode` works (from coder/claudecode.nvim)
- ✅ `:CursorCode` works (from chanwutk/cursor-cli.nvim)
- ✅ No file conflicts
- ✅ No module conflicts
- ✅ No command conflicts

## Verification

Check that only cursor files exist in this repo:

```bash
# Check plugin loaders
ls plugin/
# Output: cursor-cli.lua (only)

# Check lua modules
ls lua/
# Output: cursor-cli (only)

# Verify no claudecode files
find . -name "*claudecode*" -type f | grep -v ".git" | grep -v ".md"
# Output: (empty - no claudecode files)
```

## Technical Details

### Module Separation

| Plugin | Repository | Module | Commands |
|--------|-----------|---------|----------|
| Claude Code | `coder/claudecode.nvim` | `claudecode` | `ClaudeCode*` |
| Cursor CLI | `chanwutk/cursor-cli.nvim` | `cursor-cli` | `CursorCode*` |

### File Structure Comparison

**coder/claudecode.nvim:**
```
plugin/claudecode.lua
lua/claudecode/
  ├── init.lua
  ├── server/ (WebSocket server)
  ├── tools/ (MCP tools)
  └── ...
```

**chanwutk/cursor-cli.nvim (this repo):**
```
plugin/cursor-cli.lua
lua/cursor-cli/
  ├── init.lua
  ├── terminal/ (terminal providers)
  └── ... (no server, no MCP tools)
```

No overlap = no conflicts!

## Impact

### Before Fix
- Installing cursor-cli.nvim broke claudecode.nvim
- ClaudeCode commands didn't work
- File conflicts between plugins
- Users had to choose one or the other

### After Fix
- Both plugins can be installed simultaneously
- All commands work correctly
- No file conflicts
- Clean separation of functionality

## For Users

### Updating

If you were affected by the conflict:

1. **Update cursor-cli.nvim:**
   ```vim
   :Lazy update cursor-cli.nvim
   ```

2. **Reinstall claudecode.nvim if needed:**
   ```vim
   :Lazy clean
   :Lazy install
   ```

3. **Restart Neovim**

4. **Verify both work:**
   ```vim
   :ClaudeCode  " Should work
   :CursorCode  " Should work
   ```

### New Users

Just install both plugins as shown in the installation guide above. No special steps needed!

## Prevention

To prevent similar issues in the future:

1. **Clear separation**: Each plugin repository should contain only its own files
2. **Unique names**: Different module names (`claudecode` vs `cursor-cli`)
3. **No overlaps**: No shared file paths between plugins
4. **Documentation**: Clear indication of what each plugin provides

## Related Documentation

- [README.md](./README.md) - Updated to clarify cursor-only support
- [QUICKSTART.md](./QUICKSTART.md) - Dual installation guide
- [CURSORCODE_README.md](./CURSORCODE_README.md) - Complete cursor documentation

## Summary

✅ **Problem**: Plugin conflict broke ClaudeCode commands  
✅ **Cause**: Both plugins had claudecode files  
✅ **Solution**: Removed all claudecode files from cursor-cli.nvim  
✅ **Result**: Both plugins work independently  

This repository now provides ONLY cursor-cli support, as originally intended! 🎉
