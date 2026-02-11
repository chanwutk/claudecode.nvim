# cursorcode.nvim

A Neovim plugin for Cursor CLI integration - works **alongside** [claudecode.nvim](https://github.com/coder/claudecode.nvim).

## Overview

This plugin provides seamless integration between Neovim and Cursor CLI, enabling you to:
- Send file references to Cursor with `@filename` syntax
- Send code selections with `@filename:lines` syntax
- Use file tree explorers to add files to Cursor context
- All through simple Neovim commands

**Important**: This is a **standalone plugin** that works alongside the original `claudecode.nvim`. You can have both installed simultaneously without conflicts!

## Key Features

✅ **Independent Plugin** - Separate from claudecode.nvim  
✅ **Different Commands** - Uses `CursorCode*` (not `ClaudeCode*`)  
✅ **Direct Text Input** - Types @mentions directly into cursor terminal  
✅ **No WebSocket** - Simpler architecture, just terminal integration  
✅ **File Explorer Integration** - Works with nvim-tree, oil.nvim, neo-tree, mini.files  
✅ **Visual Selection** - Send selected code ranges  

## Installation

### With lazy.nvim

```lua
{
  -- Original Claude Code plugin (optional)
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    config = true,
  },
  
  -- New Cursor Code plugin (this repo)
  {
    "chanwutk/claudecode.nvim",  -- Or your fork
    name = "cursorcode",  -- Important: give it a different name
    dependencies = { "folke/snacks.nvim" },
    -- Note: config is optional - commands are auto-registered!
    -- You can omit config entirely for defaults:
    -- (no config needed)
    
    -- Or customize with config:
    config = function()
      require("cursorcode").setup({
        -- your custom config here
      })
    end,
    
    keys = {
      { "<leader>c", nil, desc = "Cursor" },
      { "<leader>cc", "<cmd>CursorCode<cr>", desc = "Toggle Cursor" },
      { "<leader>co", "<cmd>CursorCodeOpen<cr>", desc = "Open Cursor" },
      { "<leader>cC", "<cmd>CursorCodeClose<cr>", desc = "Close Cursor" },
      { "<leader>cb", "<cmd>CursorCodeAdd %<cr>", desc = "Add current buffer" },
      { "<leader>cs", "<cmd>CursorCodeSend<cr>", mode = "v", desc = "Send to Cursor" },
      {
        "<leader>ct",
        "<cmd>CursorCodeTreeAdd<cr>",
        desc = "Add from tree",
        ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
      },
    },
  },
}
```

**Note**: The plugin now auto-registers commands on load, so you don't need to call `setup()` unless you want to customize settings. Both approaches work:

```lua
-- Minimal install (uses all defaults)
{
  "chanwutk/claudecode.nvim",
  name = "cursorcode",
  dependencies = { "folke/snacks.nvim" },
}

-- Custom config
{
  "chanwutk/claudecode.nvim",
  name = "cursorcode",
  dependencies = { "folke/snacks.nvim" },
  config = function()
    require("cursorcode").setup({
      terminal_cmd = "cursor",
      log_level = "debug",
    })
  end,
}
```

### With packer.nvim

```lua
use {
  'chanwutk/claudecode.nvim',
  as = 'cursorcode',  -- Important: give it a different name
  requires = { 'folke/snacks.nvim' },
  config = function()
    require('cursorcode').setup({})
  end
}
```

## Requirements

- Neovim >= 0.8.0
- [Cursor CLI](https://cursor.com/cli) installed and in PATH
- [folke/snacks.nvim](https://github.com/folke/snacks.nvim) (optional, for enhanced terminal)

## Configuration

### Minimal Setup

```lua
require("cursorcode").setup({})
```

### Custom Configuration

```lua
require("cursorcode").setup({
  terminal_cmd = "cursor",  -- Command to run (default: "cursor")
  
  -- Terminal configuration
  terminal = {
    provider = "snacks",         -- "snacks" | "native" | "external" | "auto"
    split_side = "right",        -- "left" | "right"
    split_width_percentage = 0.30,
    auto_close = true,
    
    -- For external terminals
    provider_opts = {
      external_terminal_cmd = "tmux new-window -c %s",
    },
    
    -- Working directory
    git_repo_cwd = false,  -- Use git root as cwd
    cwd = nil,             -- Or set static cwd
  },
  
  -- Behavior
  focus_after_send = false,  -- Focus terminal after sending @mention
  track_selection = true,    -- Enable visual selection tracking
  
  -- Logging
  log_level = "info",  -- "trace" | "debug" | "info" | "warn" | "error"
  
  -- Custom environment variables
  env = {},
})
```

## Commands

| Command | Description |
|---------|-------------|
| `:CursorCode` | Toggle cursor terminal (smart focus) |
| `:CursorCodeOpen` | Open cursor terminal |
| `:CursorCodeClose` | Close cursor terminal |
| `:CursorCodeFocus` | Focus or toggle cursor terminal |
| `:CursorCodeAdd <file> [start] [end]` | Add file to cursor (types `@file` or `@file:start-end`) |
| `:CursorCodeSend` | Send visual selection to cursor |
| `:CursorCodeTreeAdd` | Add selected file from tree explorer |

## Usage Examples

### Add Current File
```vim
:CursorCodeAdd %
```
Types `@currentfile.ts ` into cursor terminal.

### Add File with Line Range
```vim
:CursorCodeAdd src/main.ts 10 50
```
Types `@src/main.ts:10-50 ` into cursor terminal.

### Send Visual Selection
1. Select text in visual mode (V, v, or Ctrl-V)
2. Press `<leader>cs` or run `:CursorCodeSend`
3. Plugin types `@filename:start-end ` into cursor

### Add from File Explorer
In NvimTree, oil.nvim, neo-tree, or mini.files:
1. Navigate to a file
2. Press `<leader>ct` or run `:CursorCodeTreeAdd`
3. File reference sent to cursor

## How It Works

Unlike `claudecode.nvim` which uses a WebSocket server for MCP protocol, `cursorcode.nvim` uses a simpler approach:

1. Opens a cursor CLI terminal in Neovim
2. When you reference a file/selection, it types the @mention directly into the terminal
3. Cursor CLI receives the text input and processes it

**Example Flow**:
```
:CursorCodeAdd myfile.ts 10 20
  ↓
Opens cursor terminal (if needed)
  ↓
Types: @myfile.ts:10-20 
  ↓
Cursor processes the file reference
```

## Differences from claudecode.nvim

### cursorcode.nvim (this plugin)
- ✅ Works with Cursor CLI
- ✅ Direct text input approach
- ✅ No WebSocket server
- ✅ Uses `:CursorCode*` commands
- ✅ Simpler architecture
- ✅ Can coexist with claudecode.nvim

### claudecode.nvim (original)
- ✅ Works with Claude Code
- ✅ WebSocket/MCP protocol
- ✅ Bidirectional communication
- ✅ Uses `:ClaudeCode*` commands
- ✅ Full MCP tool support

**Both can be installed together!** They use different module names and commands.

## Troubleshooting

### Cursor command not found
```
Error: cursor: command not found
```
**Solution**: Install cursor-cli or configure the path:
```lua
require("cursorcode").setup({
  terminal_cmd = "/path/to/cursor",
})
```

### Terminal not opening
If `:CursorCode` doesn't open a terminal:
1. Check that cursor is in your PATH: `which cursor`
2. Try opening manually: `:CursorCodeOpen`
3. Check logs: Set `log_level = "debug"` in config

### @mentions not appearing
If text isn't being typed into the terminal:
1. Verify terminal is active: `:CursorCode`
2. Try adding a file: `:CursorCodeAdd %`
3. Check the cursor terminal for the text
4. Enable debug logging to see what's happening

### Conflicts with claudecode.nvim
Both plugins can coexist, but if you experience issues:
1. Ensure you use different key mappings
2. Use `name = "cursorcode"` in lazy.nvim config
3. Check that commands don't overlap (CursorCode* vs ClaudeCode*)

## Terminal Providers

The plugin supports multiple terminal backends:

### Snacks.nvim (Recommended)
```lua
terminal = { provider = "snacks" }
```
Best experience with floating windows and advanced features.

### Native Neovim Terminal
```lua
terminal = { provider = "native" }
```
Built-in terminal, no extra dependencies.

### External Terminal
```lua
terminal = {
  provider = "external",
  provider_opts = {
    external_terminal_cmd = "tmux new-window -c %s",
    -- or "kitty @ launch --cwd=%s"
    -- or "wezterm cli spawn --cwd %s"
  }
}
```
Launches cursor in a separate terminal application.

## Contributing

This is a focused plugin for Cursor CLI integration. PRs welcome for:
- Bug fixes
- Better cursor CLI integration
- Documentation improvements
- New terminal provider support

## Credits

- Inspired by [coder/claudecode.nvim](https://github.com/coder/claudecode.nvim)
- Uses terminal integration patterns from claudecode.nvim
- Built specifically for Cursor CLI

## License

Same license as the original claudecode.nvim project.
