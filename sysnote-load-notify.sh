#!/bin/sh
while true
do
ssh irbdev12 '/opt/systems/bin/sysnote_search -u $USER --no-color | tail -n +4 | head -n -1 | wc -l' 2> /dev/null # Redirect STDERR to quash "No result found" messages
ssh irbdev12 '/opt/systems/bin/sysnote_search --no-color | tail -n +4 | head -n -1' > sysnote.db
perl -pe 's/^ *([^ ]+) .*$/$1/' sysnote.db > sysnote-host.list
sleep 10;
done
