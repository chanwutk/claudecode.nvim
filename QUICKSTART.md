# Quick Start: cursorcode.nvim

This guide helps you get cursorcode.nvim running alongside claudecode.nvim.

## Step 1: Install Both Plugins

### With lazy.nvim

```lua
return {
  -- Original Claude Code plugin
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    config = true,
    keys = {
      { "<leader>a", nil, desc = "AI/Claude" },
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add buffer to Claude" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
    },
  },
  
  -- New Cursor Code plugin  
  {
    "chanwutk/claudecode.nvim",
    name = "cursorcode",  -- IMPORTANT: Different name!
    dependencies = { "folke/snacks.nvim" },
    -- Note: config is optional, commands auto-register!
    -- Omit config for defaults, or customize:
    -- config = function()
    --   require("cursorcode").setup({})
    -- end,
    keys = {
      { "<leader>c", nil, desc = "AI/Cursor" },
      { "<leader>cc", "<cmd>CursorCode<cr>", desc = "Toggle Cursor" },
      { "<leader>cb", "<cmd>CursorCodeAdd %<cr>", desc = "Add buffer to Cursor" },
      { "<leader>cs", "<cmd>CursorCodeSend<cr>", mode = "v", desc = "Send to Cursor" },
    },
  },
}
```

**Key Points**:
1. `name = "cursorcode"` - Gives the second plugin a different identifier
2. Different keybindings: `<leader>a*` for Claude, `<leader>c*` for Cursor
3. Different commands: `ClaudeCode*` vs `CursorCode*`
4. **NEW**: Config is optional - commands auto-register on plugin load!

## Step 2: Verify Installation

After restarting Neovim:

```vim
:lua print(vim.inspect(require("claudecode")))  " Should load Claude plugin
:lua print(vim.inspect(require("cursorcode")))   " Should load Cursor plugin
```

Both should load without errors!

## Step 3: Test Commands

### Test Claude Code (Original Plugin)
```vim
:ClaudeCodeStart   " Start WebSocket server
:ClaudeCode        " Open Claude terminal
:ClaudeCodeAdd %   " Add current file to Claude
```

### Test Cursor Code (New Plugin)
```vim
:CursorCode        " Open Cursor terminal
:CursorCodeAdd %   " Add current file to Cursor (types @filename)
```

## Step 4: Use Both!

You can now use both AI assistants side by side:

### Claude Code Workflow
1. `:ClaudeCode` - Opens Claude terminal (right side by default)
2. `:ClaudeCodeAdd %` - Adds current file via WebSocket
3. Claude receives the file through MCP protocol
4. Chat with Claude in the terminal

### Cursor Code Workflow
1. `:CursorCode` - Opens Cursor terminal
2. `:CursorCodeAdd %` - Types `@filename` into terminal
3. Cursor receives the text input
4. Chat with Cursor in the terminal

## Common Keybinding Setup

Here's a complete keybinding setup for both:

```lua
keys = {
  -- Claude Code (<leader>a*)
  { "<leader>a", nil, desc = "+ai/claude" },
  { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Claude: Toggle" },
  { "<leader>ao", "<cmd>ClaudeCodeOpen<cr>", desc = "Claude: Open" },
  { "<leader>aX", "<cmd>ClaudeCodeClose<cr>", desc = "Claude: Close" },
  { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Claude: Add buffer" },
  { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Claude: Send selection" },
  { "<leader>at", "<cmd>ClaudeCodeTreeAdd<cr>", desc = "Claude: Add from tree", ft = { "NvimTree", "oil" } },
  
  -- Cursor Code (<leader>c*)
  { "<leader>c", nil, desc = "+ai/cursor" },
  { "<leader>cc", "<cmd>CursorCode<cr>", desc = "Cursor: Toggle" },
  { "<leader>co", "<cmd>CursorCodeOpen<cr>", desc = "Cursor: Open" },
  { "<leader>cX", "<cmd>CursorCodeClose<cr>", desc = "Cursor: Close" },
  { "<leader>cb", "<cmd>CursorCodeAdd %<cr>", desc = "Cursor: Add buffer" },
  { "<leader>cs", "<cmd>CursorCodeSend<cr>", mode = "v", desc = "Cursor: Send selection" },
  { "<leader>ct", "<cmd>CursorCodeTreeAdd<cr>", desc = "Cursor: Add from tree", ft = { "NvimTree", "oil" } },
}
```

## Configuration Tips

### Separate Terminal Positions

Put them on different sides:

```lua
-- Claude on the right
require("claudecode").setup({
  terminal = {
    split_side = "right",
    split_width_percentage = 0.30,
  },
})

-- Cursor on the left
require("cursorcode").setup({
  terminal = {
    split_side = "left",
    split_width_percentage = 0.30,
  },
})
```

### Or Use Different Providers

```lua
-- Claude with Snacks (floating)
require("claudecode").setup({
  terminal = {
    provider = "snacks",
  },
})

-- Cursor with native (split)
require("cursorcode").setup({
  terminal = {
    provider = "native",
    split_side = "right",
  },
})
```

## Troubleshooting

### Both plugins conflict
**Check**: Make sure you used `name = "cursorcode"` in lazy config.

### Wrong commands
- `ClaudeCode*` = Original plugin (Claude)
- `CursorCode*` = New plugin (Cursor)

### Can't load cursorcode module
```vim
:lua print(vim.inspect(package.loaded))
```
Check if both `claudecode` and `cursorcode` are loaded.

### Both try to use same keybindings
Use different prefixes:
- Claude: `<leader>a*`
- Cursor: `<leader>c*`

## Complete Example Config

```lua
-- ~/.config/nvim/lua/plugins/ai.lua
return {
  -- Claude Code Integration
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    config = function()
      require("claudecode").setup({
        terminal = {
          split_side = "right",
        },
      })
    end,
  },
  
  -- Cursor Code Integration (Standalone)
  {
    "chanwutk/claudecode.nvim",
    name = "cursorcode",
    dependencies = { "folke/snacks.nvim" },
    config = function()
      require("cursorcode").setup({
        terminal = {
          split_side = "left",
        },
      })
    end,
  },
}
```

Now you have both Claude and Cursor available in Neovim! 🎉
