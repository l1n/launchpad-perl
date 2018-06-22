#!/bin/perl
# Script must be run as JIRA user
# .jirarc file contains one line with a HTTP Basic Auth token

use strict;
use warnings;

use English;
$OUTPUT_AUTOFLUSH = 1;

my $user = $ENV{USER};
my $auth = `cat .jirarc`;
chomp $auth;
while (1) {
	system "curl -s --user-agent 'Intequeo/0.1' -H 'Authorization: Basic $auth' 'https://jira.ncbi.nlm.nih.gov/rest/api/2/search?jql=assignee='$user'+order+by+updatedDate+DESC'";
	print "\n";
	sleep 60;
}
