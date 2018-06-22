#!/bin/sh
USER=$1
while true
do
ssh irbdev12 '/opt/systems/bin/sysnote_search -u '$USER' --no-color | tail -n +4 | head -n -1 | wc -l'
sleep 10;
done
