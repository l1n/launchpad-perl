on firefoxRunning()
	tell application "System Events" to (name of processes) contains "Firefox"
end firefoxRunning

on run argv

	if (firefoxRunning() = false) then
		do shell script "open -a Firefox " & (item 1 of argv)
	else
		tell application "System Events"
			tell application "Firefox"
				open location item 1 of argv
				activate
			end tell
		end tell
	end if
end run
