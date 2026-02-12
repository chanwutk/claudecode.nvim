# Quick Start: cursor-cli.nvim

This guide helps you get cursor-cli.nvim running alongside claudecode.nvim.

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
    "chanwutk/cursor-cli.nvim",
    name = "cursor-cli",  -- IMPORTANT: Different name!
    dependencies = { "folke/snacks.nvim" },
    -- Note: config is optional, commands auto-register!
    -- Omit config for defaults, or customize:
    -- config = function()
    --   require("cursor-cli").setup({})
    -- end,
    keys = {
      { "<leader>c", nil, desc = "AI/Cursor" },
      { "<leader>cc", "<cmd>CursorCLI<cr>", desc = "Toggle Cursor" },
      { "<leader>cb", "<cmd>CursorCLIAdd %<cr>", desc = "Add buffer to Cursor" },
      { "<leader>cs", "<cmd>CursorCLISend<cr>", mode = "v", desc = "Send to Cursor" },
    },
  },
}
```

**Key Points**:
1. `name = "cursor-cli"` - Gives the second plugin a different identifier
2. Different keybindings: `<leader>a*` for Claude, `<leader>c*` for Cursor
3. Different commands: `ClaudeCode*` vs `CursorCLI*`
4. **NEW**: Config is optional - commands auto-register on plugin load!

## Step 2: Verify Installation

After restarting Neovim:

```vim
:lua print(vim.inspect(require("claudecode")))  " Should load Claude plugin
:lua print(vim.inspect(require("cursor-cli")))   " Should load Cursor plugin
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
:CursorCLI        " Open Cursor terminal
:CursorCLIAdd %   " Add current file to Cursor (types @filename)
```

## Step 4: Use Both!

You can now use both AI assistants side by side:

### Claude Code Workflow
1. `:ClaudeCode` - Opens Claude terminal (right side by default)
2. `:ClaudeCodeAdd %` - Adds current file via WebSocket
3. Claude receives the file through MCP protocol
4. Chat with Claude in the terminal

### Cursor Code Workflow
1. `:CursorCLI` - Opens Cursor terminal
2. `:CursorCLIAdd %` - Types `@filename` into terminal
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
  { "<leader>cc", "<cmd>CursorCLI<cr>", desc = "Cursor: Toggle" },
  { "<leader>co", "<cmd>CursorCLIOpen<cr>", desc = "Cursor: Open" },
  { "<leader>cX", "<cmd>CursorCLIClose<cr>", desc = "Cursor: Close" },
  { "<leader>cb", "<cmd>CursorCLIAdd %<cr>", desc = "Cursor: Add buffer" },
  { "<leader>cs", "<cmd>CursorCLISend<cr>", mode = "v", desc = "Cursor: Send selection" },
  { "<leader>ct", "<cmd>CursorCLITreeAdd<cr>", desc = "Cursor: Add from tree", ft = { "NvimTree", "oil" } },
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
require("cursor-cli").setup({
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
require("cursor-cli").setup({
  terminal = {
    provider = "native",
    split_side = "right",
  },
})
```

## Troubleshooting

### Both plugins conflict
**Check**: Make sure you used `name = "cursor-cli"` in lazy config.

### Wrong commands
- `ClaudeCode*` = Original plugin (Claude)
- `CursorCLI*` = New plugin (Cursor)

### Can't load cursor-cli module
```vim
:lua print(vim.inspect(package.loaded))
```
Check if both `claudecode` and `cursor-cli` are loaded.

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
    "chanwutk/cursor-cli.nvim",
    name = "cursor-cli",
    dependencies = { "folke/snacks.nvim" },
    config = function()
      require("cursor-cli").setup({
        terminal = {
          split_side = "left",
        },
      })
    end,
  },
}
```

Now you have both Claude and Cursor available in Neovim! 🎉
