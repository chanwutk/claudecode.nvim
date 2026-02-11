# Migration Guide: claudecode.nvim → cursor-cli.nvim

## Repository Renamed

The repository has been renamed from `chanwutk/claudecode.nvim` to `chanwutk/cursor-cli.nvim` to better reflect its purpose as a Cursor CLI integration.

## What Changed

### Repository Name
- **Old**: `chanwutk/claudecode.nvim`
- **New**: `chanwutk/cursor-cli.nvim`

### What Stayed the Same
- **Module name**: `cursorcode` (unchanged)
- **Commands**: `CursorCode*` (unchanged)
- **Internal structure**: All Lua modules remain the same

## Migration Steps

### For lazy.nvim Users

#### Old Configuration
```lua
{
  "chanwutk/claudecode.nvim",  -- Old repository name
  name = "cursorcode",
  dependencies = { "folke/snacks.nvim" },
}
```

#### New Configuration
```lua
{
  "chanwutk/cursor-cli.nvim",  -- ✅ New repository name
  name = "cursorcode",           -- Same module name
  dependencies = { "folke/snacks.nvim" },
}
```

#### Migration Steps

1. **Update your config file** (e.g., `~/.config/nvim/lua/plugins/cursor.lua`):
   ```lua
   -- Change this line:
   "chanwutk/claudecode.nvim",
   
   -- To this:
   "chanwutk/cursor-cli.nvim",
   ```

2. **Clean and reinstall**:
   ```vim
   :Lazy clean
   :Lazy install
   ```

3. **Restart Neovim**

4. **Verify**:
   ```vim
   :CursorCode
   ```

### For packer.nvim Users

#### Old Configuration
```lua
use {
  'chanwutk/claudecode.nvim',
  as = 'cursorcode',
  requires = { 'folke/snacks.nvim' },
}
```

#### New Configuration
```lua
use {
  'chanwutk/cursor-cli.nvim',  -- ✅ New repository name
  as = 'cursorcode',             -- Same module name
  requires = { 'folke/snacks.nvim' },
}
```

#### Migration Steps

1. **Update your config file**:
   ```lua
   -- Change this line:
   'chanwutk/claudecode.nvim',
   
   -- To this:
   'chanwutk/cursor-cli.nvim',
   ```

2. **Clean and reinstall**:
   ```vim
   :PackerClean
   :PackerSync
   ```

3. **Restart Neovim**

4. **Verify**:
   ```vim
   :CursorCode
   ```

### For Manual Installation

If you cloned the repository manually:

1. **Update remote URL**:
   ```bash
   cd ~/.local/share/nvim/site/pack/*/start/cursorcode
   git remote set-url origin https://github.com/chanwutk/cursor-cli.nvim.git
   git pull
   ```

2. **Or clone fresh**:
   ```bash
   cd ~/.local/share/nvim/site/pack/*/start/
   rm -rf cursorcode
   git clone https://github.com/chanwutk/cursor-cli.nvim.git cursorcode
   ```

## Verification

After migration, verify everything works:

```vim
" Check module loads
:lua print(require("cursorcode").version:string())

" Check commands exist
:CursorCode
:CursorCodeAdd %
:CursorCodeSend
```

## Troubleshooting

### Error: "module 'cursorcode' not found"

This means the plugin isn't installed correctly. See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for solutions.

**Quick fix**:
1. Make sure `name = "cursorcode"` is in your config
2. Run `:Lazy clean` then `:Lazy install`
3. Restart Neovim

### Error: Plugin not found in lazy.nvim

The old repository name might still be cached:

1. Remove the plugin directory:
   ```bash
   rm -rf ~/.local/share/nvim/lazy/cursorcode
   ```

2. Reinstall:
   ```vim
   :Lazy install
   ```

### Commands still don't work

1. Check if plugin is loaded:
   ```vim
   :Lazy
   ```
   Look for `cursorcode` in the list

2. Check for errors:
   ```vim
   :messages
   ```

3. Try loading manually:
   ```vim
   :lua require("cursorcode").setup()
   ```

## No Breaking Changes

**Important**: This is just a repository rename. There are no breaking changes to:
- Module names (`cursorcode`)
- Command names (`CursorCode*`)
- Configuration options
- API or functionality

Your existing configuration will work with only the repository name change!

## Side-by-Side Installation

If you want both the original Claude Code plugin and this Cursor plugin:

```lua
{
  -- Original Claude Code
  {
    "coder/claudecode.nvim",
    config = true,
  },
  
  -- Cursor CLI
  {
    "chanwutk/cursor-cli.nvim",
    name = "cursorcode",
    dependencies = { "folke/snacks.nvim" },
  },
}
```

See [QUICKSTART.md](./QUICKSTART.md) for detailed dual installation guide.

## Questions?

- **Full documentation**: [CURSORCODE_README.md](./CURSORCODE_README.md)
- **Troubleshooting**: [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
- **Quick start**: [QUICKSTART.md](./QUICKSTART.md)

## Summary

**What you need to do**:
1. Change `"chanwutk/claudecode.nvim"` to `"chanwutk/cursor-cli.nvim"` in your config
2. Run `:Lazy clean` and `:Lazy install`
3. Restart Neovim

That's it! Everything else stays the same.
