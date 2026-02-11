# Cursor CLI Support

This fork adds support for [Cursor CLI](https://cursor.com/cli) as an alternative to Claude Code.

## What Changed

The plugin now:
1. **Uses `cursor` as the default CLI command** instead of `claude`
2. **Sends file references directly to the terminal** by typing `@filename` or `@filename:start-end` instead of using WebSocket messages
3. **Maintains all existing functionality** - terminal integration, keybindings, and commands work the same way

## How It Works

When you use commands like `:ClaudeCodeAdd myfile.ts` or `:ClaudeCodeSend` in visual mode:

1. The plugin opens a cursor-cli terminal (if not already open)
2. It types the file reference directly into the terminal: `@myfile.ts` or `@myfile.ts:10-20`
3. You can then interact with cursor's chat normally

## Installation

```lua
{
  "chanwutk/claudecode.nvim",  -- This fork
  dependencies = { "folke/snacks.nvim" },
  config = true,
  keys = {
    { "<leader>a", nil, desc = "AI/Cursor" },
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Cursor" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Cursor" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Cursor" },
    -- More keybindings...
  },
}
```

## Requirements

- Neovim >= 0.8.0
- [Cursor CLI](https://cursor.com/cli) installed and in your PATH
- [folke/snacks.nvim](https://github.com/folke/snacks.nvim) for enhanced terminal support

## Configuration

### Using a Custom Cursor Command Path

If `cursor` is not in your PATH, configure the plugin:

```lua
{
  "chanwutk/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  opts = {
    terminal_cmd = "/path/to/cursor",  -- Custom cursor path
  },
  config = true,
}
```

### Other Configuration Options

All original configuration options still work:

```lua
{
  "chanwutk/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  opts = {
    terminal_cmd = "cursor",           -- CLI command (default)
    focus_after_send = false,          -- Focus terminal after sending @mention
    auto_start = true,                 -- Auto-start server on setup
    
    terminal = {
      provider = "snacks",             -- "snacks" | "native" | "external"
      split_side = "right",            -- "left" | "right"
      split_width_percentage = 0.30,   -- Terminal width (0-1)
    },
  },
  config = true,
}
```

## Available Commands

All commands work the same as the original plugin:

| Command | Description |
|---------|-------------|
| `:ClaudeCode` | Toggle cursor terminal |
| `:ClaudeCodeOpen` | Open cursor terminal |
| `:ClaudeCodeClose` | Close cursor terminal |
| `:ClaudeCodeFocus` | Focus or toggle cursor terminal |
| `:ClaudeCodeAdd <file>` | Add file to cursor context (types `@file`) |
| `:ClaudeCodeAdd <file> <start> <end>` | Add file lines to context (types `@file:start-end`) |
| `:ClaudeCodeSend` | Send visual selection to cursor (types `@file:lines`) |
| `:ClaudeCodeTreeAdd` | Add selected file from tree explorer |

## Usage Examples

### Add Current File
```vim
:ClaudeCodeAdd %
```
This types `@currentfile.ts` into the cursor terminal.

### Add File with Line Range
```vim
:ClaudeCodeAdd src/main.ts 10 50
```
This types `@src/main.ts:10-50` into the cursor terminal.

### Send Visual Selection
1. Select text in visual mode
2. Press `<leader>as` (or run `:ClaudeCodeSend`)
3. The plugin types `@filename:start-end` into cursor

### Add from File Explorer
In NvimTree, oil.nvim, or other file explorers:
1. Navigate to a file
2. Press `<leader>as` (or run `:ClaudeCodeTreeAdd`)
3. The file reference is sent to cursor

## Differences from Original

### What's Different
- **Default command**: `cursor` instead of `claude`
- **File references**: Typed directly into terminal instead of WebSocket
- **No MCP dependency**: Cursor doesn't need to support WebSocket/MCP protocol

### What's the Same
- All commands and keybindings
- Terminal integration (Snacks.nvim, native, external)
- File explorer integration
- Configuration options
- Visual selection tracking

### WebSocket Server
The WebSocket server still starts in the background for compatibility, but cursor-cli doesn't use it. This allows:
- Easy switching back to Claude Code if needed
- Future cursor features that might support MCP
- Minimal code changes from the original plugin

## Troubleshooting

### Cursor command not found
```
Error: cursor: command not found
```
**Solution**: Install cursor-cli or configure `terminal_cmd` with the full path:
```lua
opts = {
  terminal_cmd = "/full/path/to/cursor",
}
```

### Terminal not responding
If the terminal doesn't receive the `@mention`:
1. Check that cursor terminal is active: `:ClaudeCodeOpen`
2. Verify cursor CLI is running properly
3. Try manually typing `@filename` in the cursor terminal to test

### File references not working
The plugin sends text to the terminal using vim's `chansend()`. If it's not working:
1. Ensure you're using a terminal-based cursor CLI (not the GUI)
2. Check cursor documentation for the correct `@mention` syntax
3. Enable debug logging: `opts = { log_level = "debug" }`

## Manual Testing

To verify the integration is working:

1. Start Neovim with the plugin
2. Run `:ClaudeCode` to open cursor terminal
3. Run `:ClaudeCodeAdd %` to send current file
4. Check the cursor terminal - you should see `@filename` typed

## Going Back to Claude Code

To switch back to Claude Code, just change the command:

```lua
opts = {
  terminal_cmd = "claude",  -- Back to Claude Code
}
```

All other functionality remains the same since the plugin structure is unchanged.

## Contributing

Issues and PRs welcome! This is a fork focused on cursor-cli support while maintaining compatibility with the original claudecode.nvim.

## Credits

Based on [coder/claudecode.nvim](https://github.com/coder/claudecode.nvim) - a brilliant reverse-engineering of Anthropic's Claude Code extension.
