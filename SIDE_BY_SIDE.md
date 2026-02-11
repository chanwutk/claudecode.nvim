# Side-by-Side Installation with claudecode.nvim

This fork can be installed alongside the original [coder/claudecode.nvim](https://github.com/coder/claudecode.nvim) plugin without conflicts.

## How It Works

### Different Command Names
This fork uses **`CursorCode*`** commands while the original uses **`ClaudeCode*`** commands:

| This Fork (Cursor) | Original (Claude Code) |
|-------------------|------------------------|
| `:CursorCode` | `:ClaudeCode` |
| `:CursorCodeAdd` | `:ClaudeCodeAdd` |
| `:CursorCodeSend` | `:ClaudeCodeSend` |
| `:CursorCodeTreeAdd` | `:ClaudeCodeTreeAdd` |
| `:CursorCodeFocus` | `:ClaudeCodeFocus` |
| `:CursorCodeStart` | `:ClaudeCodeStart` |
| `:CursorCodeStop` | `:ClaudeCodeStop` |

### Different Plugin Sources
- **Original**: `"coder/claudecode.nvim"`
- **This Fork**: `"chanwutk/claudecode.nvim"`

Lazy.nvim treats these as separate plugins.

### Shared Module Name
Both plugins use `require("claudecode")`, so you need to configure them in separate config blocks.

## Installation Example

```lua
-- Install BOTH plugins side by side
return {
  -- Original claudecode.nvim for Claude Code
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    opts = {
      terminal_cmd = "claude",  -- Explicitly use claude
    },
    config = true,
    keys = {
      { "<leader>cl", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>ca", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add to Claude" },
      { "<leader>cs", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
    },
  },

  -- This fork for Cursor CLI
  {
    "chanwutk/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    opts = {
      terminal_cmd = "agent",  -- Explicitly use agent (cursor-cli)
    },
    config = true,
    keys = {
      { "<leader>cu", "<cmd>CursorCode<cr>", desc = "Toggle Cursor" },
      { "<leader>ua", "<cmd>CursorCodeAdd %<cr>", desc = "Add to Cursor" },
      { "<leader>us", "<cmd>CursorCodeSend<cr>", mode = "v", desc = "Send to Cursor" },
    },
  },
}
```

## Avoiding Keybinding Conflicts

Use different leader key prefixes for each plugin:

### Option 1: Different Prefixes
```lua
-- Claude Code: <leader>cl* (cl = CLaude)
{ "<leader>cl", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
{ "<leader>cla", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add to Claude" },

-- Cursor: <leader>cu* (cu = CUrsor)
{ "<leader>cu", "<cmd>CursorCode<cr>", desc = "Toggle Cursor" },
{ "<leader>cua", "<cmd>CursorCodeAdd %<cr>", desc = "Add to Cursor" },
```

### Option 2: Separate Leader Keys
```lua
-- Claude Code: <leader>c* (c = Claude)
{ "<leader>c", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
{ "<leader>ca", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add to Claude" },

-- Cursor: <leader>a* (a = Agent)
{ "<leader>a", "<cmd>CursorCode<cr>", desc = "Toggle Cursor" },
{ "<leader>aa", "<cmd>CursorCodeAdd %<cr>", desc = "Add to Cursor" },
```

### Option 3: Conditional Keybindings
```lua
-- Choose one at a time with a config flag
local use_cursor = true  -- Set to false to use Claude

if use_cursor then
  return {
    "chanwutk/claudecode.nvim",
    keys = {
      { "<leader>ai", "<cmd>CursorCode<cr>", desc = "Toggle AI" },
    },
  }
else
  return {
    "coder/claudecode.nvim",
    keys = {
      { "<leader>ai", "<cmd>ClaudeCode<cr>", desc = "Toggle AI" },
    },
  }
end
```

## Configuration Considerations

### Separate Terminal Windows
Each plugin opens its own terminal:
- Claude Code terminal runs `claude`
- Cursor terminal runs `agent`

They can both be open simultaneously in different splits.

### Separate WebSocket Servers
Both plugins may start WebSocket servers on different ports:
- Original: Random port (10000-65535)
- This fork: Random port (10000-65535)

They won't conflict as they use different ports.

### Shared Dependencies
Both use:
- `folke/snacks.nvim` for terminal support
- Same Neovim APIs

This is fine - they share these dependencies without issues.

## Workflow Examples

### Using Both
```lua
-- Open both side by side
:ClaudeCode    " Opens Claude in right split
:CursorCode    " Opens Cursor in another split

-- Send same file to both
:ClaudeCodeAdd %
:CursorCodeAdd %

-- Compare responses
" Navigate between Claude and Cursor splits
```

### Switching Between Them
```lua
-- Close Claude, use Cursor
:ClaudeCodeClose
:CursorCode

-- Close Cursor, use Claude
:CursorCodeClose
:ClaudeCode
```

## Recommended Setup

For most users who want both:

```lua
return {
  -- Claude Code (original)
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    config = true,
    keys = {
      -- Use 'c' prefix for Claude
      { "<leader>cc", "<cmd>ClaudeCode<cr>", desc = "Claude" },
      { "<leader>ca", "<cmd>ClaudeCodeAdd %<cr>", desc = "Claude: Add" },
      { "<leader>cs", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Claude: Send" },
    },
  },

  -- Cursor (this fork)
  {
    "chanwutk/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    config = true,
    keys = {
      -- Use 'a' prefix for Cursor (Agent)
      { "<leader>aa", "<cmd>CursorCode<cr>", desc = "Cursor" },
      { "<leader>ab", "<cmd>CursorCodeAdd %<cr>", desc = "Cursor: Add" },
      { "<leader>as", "<cmd>CursorCodeSend<cr>", mode = "v", desc = "Cursor: Send" },
    },
  },
}
```

## Troubleshooting

### Both Plugins Loading Same Module
If you see conflicts with `require("claudecode")`, make sure both plugins are configured in separate plugin spec blocks (as shown above).

### Keybinding Conflicts
If keybindings don't work, check for conflicts:
```vim
:verbose map <leader>a
```

### Wrong CLI Launching
Make sure each plugin explicitly sets `terminal_cmd`:
- Original: `terminal_cmd = "claude"`
- This fork: `terminal_cmd = "agent"`

### Both Terminals Opening
This is expected! They're separate plugins managing separate terminals. Use `:ClaudeCodeClose` or `:CursorCodeClose` to close the one you don't need.

## Summary

✅ **Safe to install both** - Different command names prevent conflicts
✅ **Use different keybindings** - Avoid conflicts with separate prefixes
✅ **Explicitly configure** - Set `terminal_cmd` in each to be sure
✅ **Can run simultaneously** - Both terminals can be open at once
