#!/bin/perl
# Script must be run as JIRA user
# .jirarc file contains one line with a HTTP Basic Auth token
# Open tickets is dassarmas2 filter 30311 `010 Unresolved Assigned Tickets'

use strict;
use warnings;

use IO::Handle;

autoflush STDOUT 0;
my $first = 1;

my $user = $ENV{USER};
my $auth = `cat .jirarc`;
chomp $auth;
while (1) {
	my $buf;
	$buf .= "OPEN\t";
	$buf .= qx[curl -s --user-agent 'Intequeo/0.1' -H 'Authorization: Basic $auth' 'https://jira.ncbi.nlm.nih.gov/rest/api/2/search?jql=assignee='$user'+AND+status!=Closed+AND+component!="Unix+Projects"+order+by+updatedDate+DESC'];
	$buf .= "\n";
	sleep 60 unless $first;
	$buf .= "CLOSED\t";
	$buf .= qx[curl -s --user-agent 'Intequeo/0.1' -H 'Authorization: Basic $auth' 'https://jira.ncbi.nlm.nih.gov/rest/api/2/search?jql=assignee='$user'+AND+status=Closed+AND+component!="Unix+Projects"+order+by+updatedDate+DESC'];
	$buf .= "\n";
	print $buf;
	STDOUT->flush;
	sleep 60;
	$first = 0;
}
