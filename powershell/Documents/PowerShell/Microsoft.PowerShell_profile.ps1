# ============================================================
# PowerShell Profile
# Mirrors .zshrc setup: Starship prompt, fzf, PSReadLine
# ============================================================

# ── PATH: ensure winget-installed tools are always available ─
$env:PATH = "C:\Program Files\starship\bin;$env:PATH"
$env:PATH = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\junegunn.fzf_Microsoft.Winget.Source_8wekyb3d8bbwe;$env:PATH"
$env:PATH = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\eza-community.eza_Microsoft.Winget.Source_8wekyb3d8bbwe;$env:PATH"
$env:PATH = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\ajeetdsouza.zoxide_Microsoft.Winget.Source_8wekyb3d8bbwe;$env:PATH"

# ── Editor ────────────────────────────────────────────────
$env:EDITOR = 'nvim'
$env:VISUAL = 'nvim'

# ── Aliases ───────────────────────────────────────────────
# ll / ls: use eza with icons if available, fall back to Get-ChildItem
# Remove built-in ls/ll aliases first so our functions take precedence
Remove-Alias ls -Force -ErrorAction SilentlyContinue
Remove-Alias ll -Force -ErrorAction SilentlyContinue
if (Get-Command eza -ErrorAction SilentlyContinue) {
    # mirrors zsh: ls -larht  (long, all, reverse, human-readable, sort by time)
    function ll { eza -la --sort=modified --reverse --icons @args }
    function ls { eza --icons @args }
} else {
    function ll { Get-ChildItem -Force @args | Sort-Object LastWriteTime }
}

Set-Alias cc Clear-Host

# Documents shortcut (mirrors zsh: alias cdd)
function cdd { Set-Location "$env:USERPROFILE\Documents" }

# Safe remove (prompts before deleting, mirrors zsh: alias rm="rm -i")
function rm {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Paths)
    Remove-Item -Confirm @Paths
}

# ── History ───────────────────────────────────────────────
Set-PSReadLineOption -MaximumHistoryCount 100000
Set-PSReadLineOption -HistoryNoDuplicates
Set-PSReadLineOption -HistorySaveStyle SaveIncrementally

# ── Autosuggestions (inline history prediction) ───────────
# Wrapped in try/catch: fails gracefully when stdout is redirected (e.g. non-interactive)
try {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle InlineView
} catch {}

# ── Syntax highlighting colours (Catppuccin Mocha) ────────
Set-PSReadLineOption -Colors @{
    Command            = '#89b4fa'   # blue
    Parameter          = '#cba6f7'   # mauve
    String             = '#a6e3a1'   # green
    Comment            = '#6c7086'   # overlay0
    Keyword            = '#f38ba8'   # red
    Number             = '#fab387'   # peach
    Operator           = '#94e2d5'   # teal
    Variable           = '#cdd6f4'   # text
    Type               = '#f9e2af'   # yellow
    Member             = '#89dceb'   # sky
    InlinePrediction   = '#585b70'   # surface2
}

# ── Key bindings ──────────────────────────────────────────
# Word navigation (mirrors Ctrl+Arrow in zsh)
Set-PSReadLineKeyHandler -Chord Ctrl+RightArrow -Function ForwardWord
Set-PSReadLineKeyHandler -Chord Ctrl+LeftArrow  -Function BackwardWord

# History prefix search with Up/Down (mirrors zsh bindkey)
Set-PSReadLineKeyHandler -Chord UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Chord DownArrow -Function HistorySearchForward
Set-PSReadLineOption -HistorySearchCursorMovesToEnd

# Accept inline autosuggestion with RightArrow (like zsh-autosuggestions)
# ForwardChar moves one char; at end-of-line it accepts the suggestion
Set-PSReadLineKeyHandler -Chord RightArrow -Function AcceptNextSuggestionWord

# ── fzf integration ───────────────────────────────────────
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    $env:FZF_DEFAULT_OPTS = '--height 100% --layout reverse --preview-window=wrap'

    # Ctrl+R: fuzzy history search (mirrors zsh CTRL+R)
    Set-PSReadLineKeyHandler -Chord Ctrl+r -ScriptBlock {
        $histPath = (Get-PSReadLineOption).HistorySavePath
        $history = if (Test-Path $histPath) {
            Get-Content $histPath |
                Where-Object { $_ -ne '' } |
                Select-Object -Unique |
                ForEach-Object { $_.Trim() }
        } else { @() }

        $selected = $history | fzf --tac --no-sort `
            --preview 'echo {}' --preview-window 'down:3:wrap' `
            --bind 'ctrl-r:toggle-sort' 2>$null

        if ($selected) {
            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selected)
        }
    }

    # Ctrl+T: fuzzy file search with preview (mirrors zsh CTRL+T)
    Set-PSReadLineKeyHandler -Chord Ctrl+t -ScriptBlock {
        $selected = Get-ChildItem -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '\\\.git\\' } |
            Select-Object -ExpandProperty FullName |
            fzf --preview 'powershell -NoProfile -Command "if (Test-Path -PathType Container \"{}\"){ Get-ChildItem \"{}\" }else{ Get-Content \"{}\" }"' 2>$null

        if ($selected) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selected)
        }
    }
}

# ── Starship prompt ───────────────────────────────────────
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# ── Zoxide (smart cd) ─────────────────────────────────────
# --cmd cd makes zoxide replace cd directly (same as zsh z -> cd behaviour)
# zi opens an interactive fzf picker
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
}
