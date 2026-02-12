# Visual Mode Handling - Following Original claudecode.nvim Pattern

## User Question

> "Exiting the visual mode after moving cursor seems like a hack. What does the original claudecode.nvim do?"

**Great question!** This led us to examine the original plugin and align our implementation with established patterns.

## What the Original claudecode.nvim Does

Examined the source code of `coder/claudecode.nvim` (lines 692-698 of init.lua):

```lua
local sent_successfully = selection_module.send_at_mention_for_visual_selection(line1, line2)
if sent_successfully then
  -- Exit any potential visual mode (for consistency)
  pcall(function()
    if vim.api and vim.api.nvim_feedkeys then
      local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
      vim.api.nvim_feedkeys(esc, "i", true)
    end
  end)
end
```

### Key Findings

1. ✅ **They ALSO exit visual mode** - Not a hack, it's standard practice!
2. ✅ **In source buffer** - They exit visual mode in the code file (before any focus change)
3. ✅ **Comment says**: "Exit any potential visual mode (for consistency)"
4. ✅ **Only `<Esc>`** - They send escape only, not `<Esc>i`
5. ✅ **Flag 'i'** - They use flag `'i'` (remap and insert) not `'n'` (normal)

## Why Exit Visual Mode?

### The Problem
When you select text in visual mode and send it somewhere:
- Visual mode is still active in the buffer
- Visual selection can interfere with subsequent operations
- Mode state can "leak" to other buffers
- Creates inconsistent editor state

### The Solution
Exit visual mode after using the selection:
- Cleans up the visual state
- Returns buffer to normal mode
- Prevents mode interference
- "For consistency" as the original comment says

### Not a Hack!
This is **standard Neovim plugin practice** when working with visual selections. The official claudecode.nvim does it, and so should we.

## Our Implementation

We now match the original's pattern with one extension for better UX:

### Step 1: Exit Visual Mode in Source Buffer
**Same as original**:
```lua
-- Exit visual mode in source buffer (matches claudecode.nvim behavior)
pcall(function()
  if vim.api and vim.api.nvim_feedkeys then
    local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
    vim.api.nvim_feedkeys(esc, "i", true)
  end
end)
```

This happens in the **code file where the selection was made**, before any window/buffer switching.

### Step 2: Enter Insert Mode in Terminal (Our Extension)
**Only if `focus_after_send = true`**:
```lua
if M.state.config and M.state.config.focus_after_send then
  terminal.open()
  -- Enter insert mode in terminal so user can type immediately
  vim.schedule(function()
    vim.cmd("startinsert")
  end)
else
  terminal.ensure_visible()
end
```

This happens in the **cursor terminal**, after focus has switched there.

## Comparison

### Original claudecode.nvim
```
1. User selects text in visual mode
2. Runs :ClaudeCodeSend
3. Selection sent via WebSocket
4. Visual mode exited in source buffer ✓
5. Terminal shown (if focus_after_send, which defaults to false)
6. User manually enters insert mode in terminal
```

### Our cursorcode.nvim
```
1. User selects text in visual mode
2. Runs :CursorCodeSend
3. Selection sent as @mention text
4. Visual mode exited in source buffer ✓ (matches original)
5. Terminal focused (focus_after_send defaults to true)
6. Insert mode entered automatically ✓ (our UX enhancement)
```

## Why We Do Both

### Clean Visual State (Source Buffer)
```lua
// myfile.lua - USER IS HERE
function example() {  // Lines 10-20 selected in visual mode
  // code here
}

// After :CursorCodeSend:
// Visual mode EXITED ✓ - buffer is clean
// No visual selection lingering
// Buffer returned to normal mode
```

### Ready to Type (Terminal Buffer)
```lua
// cursor terminal - USER MOVES HERE
@myfile.lua:10-20 █  // Cursor blinking in insert mode
// User can immediately type:
// "What does this function do?"
```

## Technical Details

### Why Different Flags?

**In source buffer** - Use flag `'i'`:
```lua
vim.api.nvim_feedkeys(esc, "i", true)  -- 'i' = remap and insert
```
- Respects user's key mappings
- Standard for interactive key feeding
- Matches original claudecode.nvim

**In terminal buffer** - Use `startinsert`:
```lua
vim.cmd("startinsert")
```
- Simpler when already in correct buffer
- Reliable after vim.schedule
- No need for key feeding

### Why pcall?

Both we and the original wrap the visual mode exit in `pcall`:
```lua
pcall(function()
  if vim.api and vim.api.nvim_feedkeys then
    -- exit visual mode
  end
end)
```

**Reasons**:
- Defensive programming - won't crash if API unavailable
- Works gracefully in different Neovim versions
- Prevents errors from stopping the workflow

## Benefits of This Approach

### ✅ Matches Original
- Follows established claudecode.nvim pattern
- Uses same API calls and flags
- Same comment philosophy ("for consistency")

### ✅ Clean Separation
- Visual mode exit happens in source buffer
- Insert mode entry happens in terminal buffer
- Each buffer gets appropriate mode handling

### ✅ Not a Hack
- Standard Neovim plugin practice
- Official plugin does the same thing
- Well-established pattern

### ✅ Better UX
- Still provides our focus_after_send enhancement
- User can type immediately
- Extends the original's pattern appropriately

## User Experience

### The Complete Workflow

```vim
" 1. Select code in visual mode
V
9j          " Select 10 lines

" 2. Send to cursor
:CursorCodeSend

" 3. What happens:
" ✓ @myfile.lua:10-20 sent to cursor terminal
" ✓ Visual mode exited in myfile.lua (clean state)
" ✓ Focus moved to cursor terminal
" ✓ Insert mode entered in cursor terminal
" ✓ Ready to type question immediately!

" 4. User types:
What does this code do?<Enter>
```

**Seamless, natural workflow with proper mode management!**

## Conclusion

### Is it a hack?
**No!** The original claudecode.nvim does the exact same thing - exit visual mode after sending the selection.

### Why do both plugins do this?
**For consistency** (as the original's comment says) - clean up visual mode state after using it.

### What's different?
We **extend** the pattern by also entering insert mode in the terminal when `focus_after_send = true`, providing a better UX for our default configuration.

### Result
- ✅ Follows best practices from original plugin
- ✅ Clean mode management
- ✅ Enhanced UX for our workflow
- ✅ Not a hack - it's the standard way!

---

**Thank you for the great question!** It led us to align with the original plugin's established patterns while maintaining our UX enhancements.
