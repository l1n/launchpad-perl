on firefoxRunning()
	tell application "System Events" to (name of processes) contains "Firefox"
end firefoxRunning

on run argv
	set alertReply to display alert "JIRA" message "New ticket in Unix queue!" buttons ["Cancel", "Show"] default button 2 giving up after 60
	if button returned of alertReply is equal to "Show" then

		if (firefoxRunning() = false) then
			do shell script "open -a Firefox https://jira.ncbi.nlm.nih.gov/issues/" & (item 1 of argv) & "?filter=30407"
		else
			tell application "System Events"
				tell application "Firefox"
					open location "https://jira.ncbi.nlm.nih.gov/issues/" & (item 1 of argv) & "?filter=30407"
					activate
				end tell
			end tell
		end if
	end if
end run
