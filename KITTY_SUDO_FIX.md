# Kitty Terminal - Sudo TERMINFO Fix

## Problem
When using sudo in Kitty terminal, you get this error:
```
sudo: sorry, you are not allowed to set the following environment variables: TERMINFO
```

## Root Cause
Kitty's built-in shell integration defines its own `sudo()` function that **adds** the `TERMINFO` environment variable to sudo commands. However, the system's sudo configuration doesn't allow setting this variable, causing the error.

## Solution
The fix is implemented in `~/.zshenv`:

1. **Disable Kitty's sudo wrapper** by setting:
   ```bash
   export KITTY_SHELL_INTEGRATION="no-sudo"
   ```

2. **Define custom sudo wrapper** that strips TERMINFO:
   ```bash
   sudo() {
       env -u TERMINFO /usr/bin/sudo "$@"
   }
   ```

## Files Modified
- `~/.zshenv` - Contains the KITTY_SHELL_INTEGRATION setting and custom sudo function
- `~/dotfiles/zshrc/.zshrc` - Also contains the sudo function as backup

## Why This Works
- `.zshenv` is sourced first for all shells
- `KITTY_SHELL_INTEGRATION="no-sudo"` tells kitty integration to skip its sudo function
- Our custom sudo function uses `env -u TERMINFO` to remove the variable before calling sudo
- This prevents the "not allowed to set environment variables" error

## Testing
After restarting Kitty, this should work without errors:
```bash
sudo echo test
```

## Reference
- Kitty shell integration file: `~/.local/kitty.app/lib/kitty/shell-integration/zsh/kitty-integration`
- Lines 342-357 contain kitty's sudo function implementation
