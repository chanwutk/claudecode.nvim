# Focus After Send - UX Improvement

## Overview

By default, when you use `:CursorCodeSend` or `:CursorCodeAdd`, the plugin now automatically moves your cursor to the cursor-cli terminal window. This provides a more natural workflow.

## User Experience

### New Default Behavior

1. You're editing a file: `myproject/utils.lua`
2. You run: `:CursorCodeAdd %`
3. Plugin sends: `@myproject/utils.lua ` to cursor terminal
4. ✨ **Your cursor automatically moves to the cursor terminal**
5. You can immediately type: "Explain this function"

### Before This Change

1. Run `:CursorCodeAdd %`
2. File reference sent to cursor
3. Cursor stayed in the original buffer
4. You had to manually switch to cursor terminal (`:CursorCode` or window navigation)
5. Then type your message

## Configuration

### Default (Enabled)

```lua
require("cursorcode").setup({
  -- focus_after_send is true by default
  -- No configuration needed!
})
```

### Disable Auto-Focus

If you prefer the old behavior (stay in current buffer):

```lua
require("cursorcode").setup({
  focus_after_send = false,  -- Stay in current buffer
})
```

## How It Works

The `focus_after_send` configuration option controls what happens after successfully sending a file reference:

- **`true` (default)**: Calls `terminal.open()` which focuses the cursor terminal
- **`false`**: Calls `terminal.ensure_visible()` which keeps terminal visible but doesn't change focus

## Code Reference

The logic is in `lua/cursorcode/init.lua`:

```lua
function M.send_at_mention(file_path, start_line, end_line, context)
  -- ... send the @mention ...
  
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    local success, error_msg = M._send_at_mention(file_path, start_line, end_line)
    if success then
      if M.state.config and M.state.config.focus_after_send then
        terminal.open()          -- Focus the terminal
      else
        terminal.ensure_visible() -- Keep visible, don't focus
      end
    end
    return success, error_msg
  end
end
```

## Benefits

✅ **Natural workflow**: Send file → immediately type your question  
✅ **No manual switching**: Plugin handles focus for you  
✅ **Faster interaction**: Fewer keystrokes to start chatting  
✅ **Still configurable**: Can disable if you prefer different behavior  

## Examples

### Example 1: Quick Question

```vim
" You're in utils.lua
:CursorCodeAdd %
" Cursor moves to terminal automatically
" Type: "What does this file do?"
```

### Example 2: Specific Lines

```vim
" You're in main.py, lines 45-60 selected in visual mode
:CursorCodeSend
" Cursor moves to terminal automatically
" Type: "Can you optimize this function?"
```

### Example 3: From File Explorer

```vim
" In nvim-tree/oil/neo-tree
" Cursor on config.lua
:CursorCodeTreeAdd
" Cursor moves to terminal automatically
" Type: "Review this configuration file"
```

## Commit

This feature was enabled by default in commit `e9c4f9e`:
- Changed `focus_after_send = false` to `focus_after_send = true`
- Updated comment to document the better UX

## Related

- See `lua/cursorcode/config.lua` for all configuration options
- See `CURSORCODE_README.md` for complete plugin documentation
