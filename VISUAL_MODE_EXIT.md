# Visual Mode Exit After Send

## Overview

When using `CursorCodeSend` from visual mode, the plugin now automatically:
1. Exits visual mode
2. Enters insert mode
3. Allows immediate typing in the cursor terminal

This creates a seamless workflow: **select → send → type**.

## The Problem

**Previous behavior**:
```vim
" In myfile.lua
" Select lines 10-20 with line-wise visual mode
V
9j
:CursorCodeSend

" What happened:
" ✓ @myfile.lua:10-20 sent to cursor terminal
" ✓ Focus moved to cursor terminal
" ✗ Still in visual mode in the terminal
" ✗ Can't type - had to press Esc, then i
```

Users found themselves stuck in visual mode after the focus moved to the terminal, requiring manual intervention to start typing.

## The Solution

**New behavior**:
```vim
" In myfile.lua
" Select lines 10-20 with line-wise visual mode
V
9j
:CursorCodeSend

" What happens now:
" ✓ @myfile.lua:10-20 sent to cursor terminal
" ✓ Focus moved to cursor terminal
" ✓ Visual mode automatically exited
" ✓ Insert mode automatically entered
" ✓ Ready to type immediately!
```

## How It Works

After `terminal.open()` is called (when `focus_after_send = true`), the plugin:

1. **Detects visual mode**: Checks if currently in any visual mode using:
   ```lua
   vim.fn.mode():match("[vV\22]")
   ```
   - `v` = character-wise visual mode
   - `V` = line-wise visual mode
   - `\22` = block-wise visual mode (Ctrl-V)

2. **Exits visual mode**: If in visual mode, executes:
   ```lua
   vim.cmd("normal! \\<Esc>")
   ```

3. **Enters insert mode**: Starts insert mode at cursor position:
   ```lua
   vim.cmd("startinsert")
   ```

4. **Proper timing**: Uses `vim.schedule()` to ensure this runs after the terminal window is focused

## User Experience

### Example 1: Quick Code Question
```vim
" Select a function you want to ask about
V
5j
:CursorCodeSend
" Immediately type: "what does this function do?"
```

### Example 2: Debugging Help
```vim
" Select problematic code
Ctrl-V
10j
5l
:CursorCodeSend
" Immediately type: "why isn't this working?"
```

### Example 3: Code Explanation
```vim
" Select complex algorithm
v
/end_of_algorithm<CR>
:CursorCodeSend
" Immediately type: "explain this algorithm step by step"
```

## Configuration

This feature:
- ✅ Works with all visual modes (v, V, Ctrl-V)
- ✅ Only applies when `focus_after_send = true` (default)
- ✅ Integrates seamlessly with the focus workflow
- ✅ No additional configuration needed

To disable the auto-focus (and thus this feature):
```lua
require("cursorcode").setup({
  focus_after_send = false,
})
```

## Technical Details

### Code Location
The feature is implemented in `lua/cursorcode/init.lua` in the `send_at_mention()` function, at two locations:

1. When terminal already exists (after line 147)
2. When terminal needs to be created (after line 164)

### Mode Detection Pattern
The pattern `[vV\22]` matches:
- Regular character-wise visual: `v`
- Line-wise visual: `V`
- Block-wise visual: `\22` (Ctrl-V character code)

### Timing
Uses `vim.schedule()` to ensure the mode change happens after:
- Terminal window is focused
- Buffer is properly set
- Cursor is in the terminal

## Benefits

✅ **Seamless workflow**: No manual mode switching needed  
✅ **Natural interaction**: Works how users expect  
✅ **Faster workflow**: Eliminate extra keystrokes  
✅ **Less cognitive load**: Don't need to think about modes  
✅ **Better UX**: Just select, send, and type!

## Summary

This feature completes the natural workflow for sending code selections to Cursor:

1. **Select** code in visual mode (v, V, or Ctrl-V)
2. **Send** with `:CursorCodeSend`
3. **Type** your question immediately - no manual mode switching!

Combined with `focus_after_send = true`, this creates a completely smooth, integrated experience that feels natural and efficient.
