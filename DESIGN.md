# cursor-cli.nvim Design Document

**Last Updated**: 2026-02-12  
**Version**: 1.0.0

This document provides a comprehensive overview of the cursor-cli.nvim plugin's architecture, design decisions, and implementation details. It serves as the primary reference for understanding the codebase.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Divergence from claudecode.nvim](#divergence-from-claudecodenvim)
4. [Key Design Decisions](#key-design-decisions)
5. [Implementation Details](#implementation-details)
6. [Configuration](#configuration)
7. [Commands Reference](#commands-reference)
8. [Development Guide](#development-guide)

---

## Overview

### What is cursor-cli.nvim?

cursor-cli.nvim is a Neovim plugin that integrates Cursor CLI (`agent` command) directly into your Neovim workflow. It provides commands to open a Cursor terminal and send file/code references to it using @mention syntax.

### Relationship to claudecode.nvim

This plugin was forked from [coder/claudecode.nvim](https://github.com/coder/claudecode.nvim) but diverged significantly to support a different architecture:

- **claudecode.nvim**: Uses WebSocket + MCP protocol for bidirectional communication with Claude Code
- **cursor-cli.nvim**: Uses direct text input to type @mentions into Cursor terminal

Both plugins can be installed simultaneously without conflicts - they serve different AI assistants with different integration models.

### Core Purpose

Enable Neovim users to:
1. Open Cursor CLI in a terminal within Neovim
2. Send file references: `@filename`
3. Send code selections: `@filename:10-20`
4. Maintain seamless workflow: select → send → type question

---

## Architecture

### Module Structure

```
lua/cursor-cli/
├── init.lua              # Main plugin logic, command registration
├── config.lua            # Configuration defaults and validation
├── terminal.lua          # Terminal abstraction and provider selection
├── terminal/
│   ├── native.lua        # Native Neovim terminal provider
│   ├── snacks.lua        # Snacks.nvim terminal provider
│   ├── external.lua      # External terminal provider
│   └── none.lua          # No-op provider
├── selection.lua         # Visual selection handling
├── visual_commands.lua   # Visual mode command mappings
├── integrations.lua      # File explorer integrations
├── cwd.lua              # Working directory management
├── logger.lua           # Logging utilities
└── utils.lua            # General utilities

plugin/
└── cursor-cli.lua       # Plugin loader, auto-setup

fixtures/
├── netrw/              # Test config for netrw integration
├── nvim-tree/          # Test config for nvim-tree integration
├── oil/                # Test config for oil.nvim integration
└── mini-files/         # Test config for mini.files integration
```

### Key Components

#### 1. init.lua - Plugin Core
- **Responsibilities**: Command registration, @mention sending, plugin lifecycle
- **Key Functions**:
  - `setup(opts)` - Initialize plugin with user config
  - `send_at_mention(file, start_line, end_line)` - Send file/selection to Cursor
  - `_broadcast_at_mention()` - Format and send @mention text to terminal
- **State Management**: Maintains plugin state (config, terminal reference)

#### 2. terminal.lua - Terminal Abstraction
- **Responsibilities**: Abstract terminal operations across providers
- **Provider Selection**: Auto-detects available terminal (snacks → native → external)
- **Key Functions**:
  - `open()` - Open/focus Cursor terminal
  - `close()` - Close terminal
  - `send_keys(text)` - Send text to terminal (core @mention mechanism)
  - `get_cursor_command_and_env()` - Build `agent` command with environment

#### 3. Terminal Providers

**Native** (`terminal/native.lua`):
- Uses Neovim's built-in `:terminal`
- Splits window, manages buffer/window lifecycle
- Most compatible, always available

**Snacks** (`terminal/snacks.lua`):
- Uses [folke/snacks.nvim](https://github.com/folke/snacks.nvim) if available
- Floating window support, better UX
- Auto-cleanup on terminal exit

**External** (`terminal/external.lua`):
- Launches Cursor in separate terminal application
- Configured via `external_terminal_cmd` (e.g., `"alacritty -e %s"`)
- For users who prefer external terminals

**None** (`terminal/none.lua`):
- No-op provider for testing/debugging
- Prints actions without creating terminal

#### 4. selection.lua - Visual Selection
- **Responsibilities**: Detect and format visual selections
- **Integration**: Works with visual_commands.lua for visual mode operations
- **Key Function**: `send_at_mention_for_visual_selection()` - Send current visual selection

#### 5. config.lua - Configuration
- **Defaults**: Defines sensible defaults for all options
- **Validation**: Validates user-provided configuration
- **Exports**: `defaults` table, `validate()` function

---

## Divergence from claudecode.nvim

### What Was Removed

#### 1. WebSocket Server (`server/`)
**Removed**: Entire `lua/claudecode/server/` directory (7 files, ~2000 LOC)
- TCP server implementation
- WebSocket handshake (RFC 6455)
- Frame parsing and encoding
- Client connection management
- Authentication system

**Reason**: Cursor CLI doesn't use MCP protocol. It's a standalone terminal application that accepts text input. No need for bidirectional communication.

#### 2. MCP Protocol (`tools/`)
**Removed**: Entire `lua/claudecode/tools/` directory (12 tool implementations)
- `openFile`, `getCurrentSelection`, `getLatestSelection`
- `getOpenEditors`, `openDiff`, `closeAllDiffTabs`
- `checkDocumentDirty`, `saveDocument`
- `getWorkspaceFolders`, `getDiagnostics`

**Reason**: MCP is Claude Code's protocol for IDE integration. Cursor CLI uses simple text-based interaction via @mentions.

#### 3. Lockfile System (`lockfile.lua`)
**Removed**: Lock file creation/management at `~/.claude/ide/*.lock`

**Reason**: Lockfiles were for Claude CLI discovery of WebSocket port. Not needed for Cursor CLI.

#### 4. Diff Integration (`diff.lua`)
**Removed**: Native Neovim diff view support

**Reason**: Cursor handles diffs internally. Plugin focuses on sending references, not managing diffs.

### What Was Simplified

#### 1. Selection Tracking
**claudecode.nvim**: Real-time selection tracking with server broadcasts
```lua
-- Continuously tracks selections, broadcasts to server
selection_module.enable(server)
selection_module.update_selection()
```

**cursor-cli.nvim**: On-demand selection capture
```lua
-- Captures selection only when user sends it
local selection = get_current_visual_selection()
send_at_mention(file, start_line, end_line)
```

**Reason**: No server to broadcast to. Simpler implementation, less overhead.

#### 2. Configuration
**Removed Options**:
- `port_range` - WebSocket server ports
- `auto_start` - Auto-start server
- `connection_timeout` - WebSocket connection timeout
- `queue_timeout` - Message queue timeout
- `models` - AI model selection
- `diff_opts` - Diff view options

**Kept Options**:
- `terminal_cmd` - CLI command (default: `"agent"`)
- `terminal` - Terminal provider config
- `log_level` - Logging verbosity
- `focus_after_send` - Auto-focus terminal after sending (UX enhancement)

### What Was Added

#### 1. Direct Text Input Mechanism
**New**: `terminal.send_keys(text)` function
```lua
-- Types text directly into terminal as if user typed it
local text = string.format("@%s", relative_path)
if start_line and end_line then
  text = text .. string.format(":%d-%d", start_line + 1, end_line + 1)
end
terminal.send_keys(text .. " ")
```

**Implementation**: Uses `vim.fn.chansend()` to send text to terminal channel.

#### 2. Focus Management
**New**: `focus_after_send` configuration option (default: `true`)
```lua
if M.state.config.focus_after_send then
  terminal.open()  -- Focus terminal
  vim.schedule(function()
    vim.cmd("startinsert")  -- Enter insert mode
  end)
else
  terminal.ensure_visible()  -- Keep visible but don't focus
end
```

**Reason**: UX enhancement. After sending file reference, users typically want to type a question immediately.

#### 3. Visual Mode Exit Pattern
**New**: Automatic visual mode exit after sending selection
```lua
-- Exit visual mode in source buffer (matches claudecode.nvim pattern)
pcall(function()
  local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
  vim.api.nvim_feedkeys(esc, "i", true)
end)

-- Then enter insert mode in terminal
vim.schedule(function()
  vim.cmd("startinsert")
end)
```

**Reason**: Clean up visual selection state, enable immediate typing in terminal. Matches original claudecode.nvim's approach.

---

## Key Design Decisions

### 1. Direct Text Input vs WebSocket

**Decision**: Use direct text input to terminal instead of WebSocket protocol.

**Rationale**:
- **Simplicity**: 90% reduction in code complexity (removed ~2500 LOC)
- **Reliability**: Terminal text input is well-tested, no network issues
- **Cursor's Model**: Cursor CLI is designed for text-based interaction
- **No Bidirectional Need**: Plugin only sends data to Cursor, doesn't receive responses

**Trade-offs**:
- **Limited to @mentions**: Can't trigger complex Cursor features programmatically
- **One-way**: Cursor can't update Neovim state
- **Good for this use case**: Sending file/code references is the primary need

### 2. Terminal Provider Abstraction

**Decision**: Support multiple terminal providers (native, snacks, external) via abstraction layer.

**Rationale**:
- **User Choice**: Different users prefer different terminal experiences
- **Graceful Fallback**: Auto-detect best available (snacks → native → external)
- **Extensibility**: Easy to add new providers
- **Consistent API**: All providers implement same interface

**Implementation**:
```lua
-- terminal.lua provider interface
M.open = function() end
M.close = function() end
M.focus_toggle = function() end
M.send_keys = function(text) end
```

### 3. Visual Mode Handling Pattern

**Decision**: Exit visual mode in source buffer before terminal interaction.

**Rationale**:
- **Matches Original**: claudecode.nvim uses same pattern (lines 692-698)
- **Clean State**: Prevents visual mode "leaking" to terminal
- **Standard Practice**: Not a hack, it's how Neovim plugins handle visual mode
- **UX**: Then enter insert mode in terminal for immediate typing

**Evidence from claudecode.nvim**:
```lua
-- coder/claudecode.nvim (init.lua:692-698)
if sent_successfully then
  -- Exit any potential visual mode (for consistency)
  pcall(function()
    local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
    vim.api.nvim_feedkeys(esc, "i", true)
  end)
end
```

### 4. Error Handling Philosophy

**Decision**: Silent failures for expected edge cases, clear errors for unexpected issues.

**Examples**:

**Silent** (using `pcall`):
```lua
-- Window close might fail if already closed - that's ok
pcall(vim.api.nvim_win_close, winid, true)

-- Terminal close might fail if already stopped - that's ok
pcall(vim.fn.jobstop, jobid)
```

**Verbose** (using `logger.error`):
```lua
-- Unexpected failures should be reported
if not success then
  logger.error("terminal", "Failed to open Cursor CLI: " .. error_msg)
end
```

**Rationale**: Don't interrupt user workflow with errors for normal edge cases (window already closed, job already stopped). Do alert for unexpected failures.

### 5. Command Naming: CursorCLI* not CursorCode*

**Decision**: Use `CursorCLI*` prefix for all commands.

**Evolution**:
- Initially: `CursorCode*` (consistent with `ClaudeCode*`)
- Changed to: `CursorCLI*` (matches Cursor CLI product name)

**Rationale**:
- **Clarity**: "CLI" clearly indicates it's for Cursor CLI, not Cursor IDE
- **Consistency**: Matches the actual product name (cursor-cli)
- **Differentiation**: Distinguishes from potential future Cursor IDE integration

---

## Implementation Details

### How @mentions Are Sent

#### 1. User Action
```vim
:CursorCLIAdd myfile.lua 10 20
```

#### 2. Path Processing
```lua
-- Convert to relative path from workspace root
local relative_path = M._get_relative_path(file_path)
-- Example: "src/myfile.lua"
```

#### 3. Format @mention
```lua
local text = string.format("@%s", relative_path)
if start_line and end_line then
  -- Lines are 0-indexed internally, 1-indexed for display
  text = text .. string.format(":%d-%d", start_line + 1, end_line + 1)
end
-- Example: "@src/myfile.lua:11-21 "
```

#### 4. Send to Terminal
```lua
terminal.send_keys(text .. " ")  -- Trailing space for UX
```

#### 5. Terminal Provider Implementation (Native)
```lua
function M.send_keys(text)
  if not jobid or jobid == -1 then return end
  
  -- Send text to terminal channel
  vim.fn.chansend(jobid, text)
  
  logger.debug("terminal", "Sent to cursor: " .. text)
end
```

### Visual Mode Exit Pattern

This pattern is used in two places in `init.lua`:

#### In Source Buffer (Before Focus Change)
```lua
if success then
  -- Exit visual mode in source buffer (matches claudecode.nvim)
  pcall(function()
    if vim.api and vim.api.nvim_feedkeys then
      local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
      vim.api.nvim_feedkeys(esc, "i", true)  -- 'i' flag = remap and insert
    end
  end)
```

**Why 'i' flag?** Matches claudecode.nvim exactly. Allows remaps, processes in insert context.

#### In Terminal (After Focus Change)
```lua
if M.state.config.focus_after_send then
  terminal.open()  -- Focus terminal
  
  vim.schedule(function()
    vim.cmd("startinsert")  -- Enter insert mode
  end)
end
```

**Why `vim.schedule`?** Ensures command runs after terminal window is fully focused.

**Why `startinsert`?** Simple and reliable for entering insert mode in focused buffer.

### Focus Management

The `focus_after_send` feature (default: `true`) provides a seamless workflow:

```lua
-- 1. User selects code in visual mode
V
9j

-- 2. User sends selection
:CursorCLISend

-- 3. Plugin actions (automatic):
--    a. Send @mention to Cursor terminal
--    b. Exit visual mode in source buffer
--    c. Focus Cursor terminal window
--    d. Enter insert mode
--    e. User can immediately type question!
```

### Environment Variable Handling

Terminal command is built with environment variables:

```lua
local function get_cursor_command_and_env()
  local base_cmd = config.terminal_cmd or "agent"
  
  local env_table = {}
  for k, v in pairs(defaults.env or {}) do
    env_table[k] = v
  end
  
  -- Only pass env if it has values (avoid empty table issue)
  local termopen_opts = { cwd = config.cwd }
  if env_table and next(env_table) ~= nil then
    termopen_opts.env = env_table
  end
  
  return base_cmd, env_table
end
```

**Why conditional env?** Empty env table `{}` causes "Invalid argument: env" error in some Neovim versions. Only include if non-empty.

---

## Configuration

### Available Options

```lua
require("cursor-cli").setup({
  -- CLI command to run (default: "agent")
  terminal_cmd = "agent",
  
  -- Terminal provider ("auto", "snacks", "native", "external", "none")
  terminal = {
    provider = "auto",  -- Auto-select best available
    
    -- External terminal configuration (only if provider = "external")
    external_terminal_cmd = "alacritty -e %s",  -- %s replaced with command
  },
  
  -- Auto-focus terminal after sending file/selection (default: true)
  focus_after_send = true,
  
  -- Log level ("debug", "info", "warn", "error")
  log_level = "warn",
  
  -- Working directory (default: vim.fn.getcwd())
  cwd = nil,
  
  -- Environment variables for Cursor CLI
  env = {},
})
```

### Defaults and Rationale

| Option | Default | Rationale |
|--------|---------|-----------|
| `terminal_cmd` | `"agent"` | Cursor CLI command name |
| `terminal.provider` | `"auto"` | Auto-detect best available (snacks → native → external) |
| `focus_after_send` | `true` | UX: Users typically want to type immediately after sending |
| `log_level` | `"warn"` | Balance: Show issues but not too verbose |
| `cwd` | `vim.fn.getcwd()` | Use Neovim's current working directory |
| `env` | `{}` | No special environment variables needed by default |

### Terminal Provider Selection

**Auto-detection order**:
1. **Snacks**: If `require("snacks")` succeeds → use snacks.nvim
2. **Native**: Fall back to built-in Neovim terminal
3. **External**: If configured, use external terminal
4. **None**: Testing/debugging only

**Override**:
```lua
require("cursor-cli").setup({
  terminal = {
    provider = "native",  -- Force native terminal
  },
})
```

---

## Commands Reference

All commands support both normal mode and visual mode where appropriate.

### :CursorCLI
**Toggle** Cursor terminal (open if closed, close if open).

**Usage**:
```vim
:CursorCLI
```

**Implementation**: Calls `terminal.focus_toggle()`

### :CursorCLIOpen
**Open** Cursor terminal and focus it.

**Usage**:
```vim
:CursorCLIOpen
```

**Use Case**: Explicitly open terminal even if already open (ensures focus).

### :CursorCLIClose
**Close** Cursor terminal.

**Usage**:
```vim
:CursorCLIClose
```

**Note**: Uses `pcall` to handle edge case where terminal already closed.

### :CursorCLIFocus
**Focus** Cursor terminal without toggling (open if needed).

**Usage**:
```vim
:CursorCLIFocus
```

**Difference from CursorCLIOpen**: Doesn't create new terminal if one exists elsewhere.

### :CursorCLIAdd [file] [start] [end]
**Send file reference** to Cursor, optionally with line range.

**Usage**:
```vim
" Send entire current file
:CursorCLIAdd %

" Send specific file
:CursorCLIAdd src/main.lua

" Send file with line range (1-indexed)
:CursorCLIAdd src/main.lua 10 20
```

**Result**: Types `@src/main.lua:10-20 ` into Cursor terminal.

### :CursorCLISend
**Send visual selection** to Cursor.

**Usage** (in visual mode):
```vim
" 1. Select lines in visual mode
V
9j

" 2. Send selection
:'<,'>CursorCLISend
```

**Result**: Types `@currentfile.lua:10-20 ` into Cursor terminal.

**Note**: Automatically exits visual mode and enters insert mode in terminal (if `focus_after_send = true`).

### :CursorCLITreeAdd
**Send file from file explorer** (nvim-tree, oil.nvim, neo-tree, mini.files).

**Usage** (cursor on file in file explorer):
```vim
:CursorCLITreeAdd
```

**Implementation**: Uses `integrations.lua` to detect file explorer and get file path.

**Supported Explorers**:
- nvim-tree.lua
- oil.nvim
- neo-tree.nvim
- mini.files
- netrw (built-in)

---

## Development Guide

### Running the Plugin Locally

1. **Clone repository**:
```bash
git clone https://github.com/chanwutk/cursor-cli.nvim.git
```

2. **Use development config** (in `scripts/dev-config.lua`):
```bash
nvim -u scripts/dev-config.lua
```

3. **Or use fixtures** for testing specific integrations:
```bash
# Test with nvim-tree
cd fixtures/nvim-tree
nvim -u init.lua

# Test with oil.nvim
cd fixtures/oil
nvim -u init.lua
```

### Code Structure Guidelines

**Module Organization**:
- One responsibility per file
- Clear interfaces between modules
- Minimal coupling

**Error Handling**:
- Use `pcall` for expected edge cases (window close, job stop)
- Use `logger.error` for unexpected failures
- Never interrupt user workflow unnecessarily

**Visual Mode**:
- Always exit visual mode in source buffer before terminal operations
- Use claudecode.nvim's pattern (it's well-tested)
- Document why you're doing it (it's not obvious)

**Testing**:
- Use fixtures for integration testing
- Test with all terminal providers
- Test with all file explorers
- Verify error cases don't crash

### Common Patterns

**Getting relative path**:
```lua
local relative_path = M._get_relative_path(file_path)
```

**Sending @mention**:
```lua
local text = string.format("@%s", relative_path)
if start_line then
  text = text .. string.format(":%d-%d", start_line + 1, end_line + 1)
end
terminal.send_keys(text .. " ")
```

**Safe window close**:
```lua
pcall(vim.api.nvim_win_close, winid, true)
```

**Scheduled insert mode**:
```lua
vim.schedule(function()
  vim.cmd("startinsert")
end)
```

### Debugging

**Enable debug logging**:
```lua
require("cursor-cli").setup({
  log_level = "debug",
})
```

**Check logs**:
```vim
:messages
```

**Test terminal provider**:
```vim
:lua =require("cursor-cli.terminal").state
```

**Verify module loaded**:
```vim
:lua =package.loaded["cursor-cli"]
```

---

## Appendix: Evolution Summary

### Development Timeline

1. **Fork from claudecode.nvim** - Started with full MCP implementation
2. **Remove WebSocket/MCP** - Simplified to direct text input
3. **Fix command registration** - VimEnter timing issue
4. **Fix env argument** - Conditional env table passing
5. **Change CLI command** - `cursor` → `agent`
6. **Remove claudecode files** - Resolve plugin conflict
7. **Adapt selection module** - Remove server dependency
8. **Fix visual mode** - Implement exit pattern
9. **Add focus management** - `focus_after_send` feature
10. **Rename to cursor-cli** - `cursorcode` → `cursor-cli`, `CursorCode*` → `CursorCLI*`

### Code Size Comparison

| Metric | claudecode.nvim | cursor-cli.nvim | Change |
|--------|----------------|-----------------|--------|
| Lua files | 30+ | 14 | -53% |
| Lines of code | ~5500 | ~2500 | -55% |
| Commands | 10 | 7 | -30% |
| Config options | 15+ | 6 | -60% |
| Dependencies | MCP, WebSocket | None (optional snacks) | Simpler |

### Key Learnings

1. **Simplicity wins**: Removing WebSocket/MCP made the plugin more maintainable
2. **Follow patterns**: Visual mode handling from claudecode.nvim worked perfectly
3. **UX matters**: `focus_after_send` feature significantly improved workflow
4. **Document decisions**: This doc captures "why", not just "what"
5. **Test integrations**: Fixtures for file explorers caught many edge cases

---

## Conclusion

cursor-cli.nvim demonstrates that **less is more**. By removing the complex WebSocket/MCP infrastructure and focusing on a simple, reliable text input mechanism, we achieved:

- **55% less code** to maintain
- **Simpler mental model** for contributors
- **More reliable** operation (no network issues)
- **Better UX** through focus management
- **Easy installation** alongside claudecode.nvim

The design prioritizes **user workflow** (select → send → type) over technical sophistication, resulting in a tool that gets out of the user's way and just works.

For questions or contributions, see [DEVELOPMENT.md](DEVELOPMENT.md) and [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
