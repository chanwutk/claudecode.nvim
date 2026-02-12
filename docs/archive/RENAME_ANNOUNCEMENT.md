# 🎉 Rename Complete!

## cursor-cli.nvim - Now with Consistent Naming

The plugin has been renamed for clarity and consistency:

### What Changed

| Aspect | Before | After |
|--------|--------|-------|
| **Package Name** | `cursorcode` | `cursor-cli` |
| **Commands** | `:CursorCode*` | `:CursorCLI*` |
| **Module Path** | `lua/cursorcode/` | `lua/cursor-cli/` |

## Quick Migration

### 1. Update lazy.nvim Config

```lua
-- Before
{
  "chanwutk/cursor-cli.nvim",
  name = "cursorcode",  -- ❌ Old
  config = function()
    require("cursorcode").setup({})  -- ❌ Old
  end,
}

-- After
{
  "chanwutk/cursor-cli.nvim",
  name = "cursor-cli",  -- ✅ New
  config = function()
    require("cursor-cli").setup({})  -- ✅ New
  end,
}
```

### 2. Update Keybindings

```lua
-- Before
{ "<leader>cc", "<cmd>CursorCode<cr>" },      -- ❌ Old
{ "<leader>ca", "<cmd>CursorCodeAdd %<cr>" }, -- ❌ Old

-- After
{ "<leader>cc", "<cmd>CursorCLI<cr>" },      -- ✅ New
{ "<leader>ca", "<cmd>CursorCLIAdd %<cr>" }, -- ✅ New
```

### 3. Reinstall

```vim
:Lazy clean
:Lazy install
" Restart Neovim
```

## New Command Names

| Old Command | New Command |
|-------------|-------------|
| `:CursorCode` | `:CursorCLI` |
| `:CursorCodeOpen` | `:CursorCLIOpen` |
| `:CursorCodeClose` | `:CursorCLIClose` |
| `:CursorCodeAdd` | `:CursorCLIAdd` |
| `:CursorCodeSend` | `:CursorCLISend` |
| `:CursorCodeTreeAdd` | `:CursorCLITreeAdd` |

## Why This Change?

1. **Better Alignment**: Package name `cursor-cli` matches the CLI tool name
2. **Clearer Commands**: `CursorCLI*` makes it obvious these are cursor CLI commands
3. **Consistency**: Repository → `cursor-cli.nvim`, Package → `cursor-cli`, Commands → `CursorCLI*`

## Need Help?

- See [RENAME_SUMMARY.md](./RENAME_SUMMARY.md) for detailed migration guide
- See [README.md](./README.md) for updated installation instructions
- See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) if you encounter issues

## What Works

✅ All functionality remains the same
✅ All features work as before
✅ Better, more consistent naming
✅ Clearer documentation

The only change is the names - everything else works exactly as before! 🚀
