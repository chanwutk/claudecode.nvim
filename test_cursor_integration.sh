#!/bin/bash
# Manual test script for cursor-cli integration
# This script helps verify the cursor integration is working

set -e

echo "=================================================="
echo "Cursor-CLI Integration Test Script"
echo "=================================================="
echo ""

# Check if cursor is available
echo "1. Checking for cursor command..."
if command -v cursor &> /dev/null; then
    echo "   ✓ cursor found at: $(which cursor)"
else
    echo "   ✗ cursor not found in PATH"
    echo "   Please install cursor-cli or configure terminal_cmd"
    echo ""
    echo "   You can still test with a mock cursor command:"
    echo "   Just create a simple script that prints its arguments"
    exit 1
fi

echo ""
echo "2. Checking Neovim version..."
if command -v nvim &> /dev/null; then
    nvim_version=$(nvim --version | head -n1)
    echo "   ✓ $nvim_version"
else
    echo "   ✗ nvim not found"
    exit 1
fi

echo ""
echo "3. Plugin file structure check..."
required_files=(
    "lua/claudecode/init.lua"
    "lua/claudecode/terminal.lua"
    "lua/claudecode/config.lua"
    "CURSOR_SUPPORT.md"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✓ $file"
    else
        echo "   ✗ $file not found"
    fi
done

echo ""
echo "4. Checking for key changes..."

# Check terminal.lua for cursor command
if grep -q 'base_cmd = "cursor"' lua/claudecode/terminal.lua; then
    echo "   ✓ Default command is 'cursor'"
else
    echo "   ✗ Default command not set to 'cursor'"
fi

# Check for send_keys function
if grep -q 'function M.send_keys' lua/claudecode/terminal.lua; then
    echo "   ✓ send_keys function exists"
else
    echo "   ✗ send_keys function not found"
fi

# Check init.lua for terminal.send_keys call
if grep -q 'terminal.send_keys' lua/claudecode/init.lua; then
    echo "   ✓ init.lua calls terminal.send_keys"
else
    echo "   ✗ init.lua doesn't call send_keys"
fi

echo ""
echo "=================================================="
echo "Basic checks complete!"
echo "=================================================="
echo ""
echo "Next steps for manual testing:"
echo ""
echo "1. Start Neovim with the plugin loaded"
echo "2. Run :ClaudeCode to open cursor terminal"
echo "3. Run :ClaudeCodeAdd % to send current file"
echo "4. Check the cursor terminal - you should see @filename"
echo ""
echo "Example test session:"
echo "---"
echo "  nvim testfile.lua"
echo "  :ClaudeCode"
echo "  :ClaudeCodeAdd %"
echo "  # Watch the cursor terminal for '@testfile.lua'"
echo "---"
echo ""
echo "For visual selection test:"
echo "---"
echo "  1. Select some lines in visual mode (V)"
echo "  2. Run :ClaudeCodeSend"
echo "  3. Check cursor terminal for '@filename:start-end'"
echo "---"
echo ""
echo "See CURSOR_SUPPORT.md for more details!"
