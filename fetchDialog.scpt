set theSelectedText to the text returned of (display dialog "Search Term" default answer "")
do shell script "echo " & theSelectedText
