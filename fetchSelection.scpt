-- Back up clipboard contents:
set savedClipboard to the clipboard

-- Copy selected text to clipboard:
tell application "System Events" to keystroke "c" using {command down}
delay 0.20 -- Without this, the clipboard may have stale data.

set theSelectedText to the clipboard

-- Restore clipboard:
set the clipboard to savedClipboard

do shell script "echo " & theSelectedText
