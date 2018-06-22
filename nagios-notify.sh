#!/bin/sh
while true
do
curl -s --negotiate -u : 'https://nagios.ncbi.nlm.nih.gov/nagios/cgi/status.cgi?hostgroup=all&style=overview' -o nagios-status.html
egrep 'hostgroup=|miniStatusCRITICAL|miniStatusWarning|miniStatusOK' nagios-status.html | grep -v hostgroup=all | perl nagios-notify.pl | grep -vE 'gc-va\t' | perl nagios-notify.pl | tee nagios-status.tsv
done
