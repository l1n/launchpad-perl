#!/bin/sh
while true
do
curl -s --negotiate -u : 'https://nagios.ncbi.nlm.nih.gov/nagios/cgi/status.cgi?hostgroup=all&style=overview' -o nagios-status.html
egrep 'hostgroup=|miniStatusCRITICAL|miniStatusWarning|miniStatusOK' nagios-status.html | fgrep -v hostgroup=all | fgrep -vf sysnote-host.list | fgrep -vf nagios-exclude.list | perl nagios-notify.pl | grep -vE 'gc-va\t' | perl nagios-notify.pl | tee nagios-status.tsv
done
