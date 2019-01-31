#!/bin/perl
# Script must be run as JIRA user
# .jirarc file contains one line with a HTTP Basic Auth token
# Ticket source is dassarmas2 filter 30407 `Unix Q'

use strict;
use warnings;

use IO::Handle;
use JSON::PP qw(decode_json);

autoflush STDOUT 0;
my $first = 1;
my $MODE = shift || "standalone";
unless (grep ( /^$MODE$/, qw(standalone subprocess) )) {
	$MODE = "standalone";
}

my $user = $ENV{USER};
my $auth = `cat .jirarc`;
chomp $auth;
my $i = 0;
my $last_ticket_count = 0;
my $current_ticket_count = 0;
do {
	$current_ticket_count = qx[curl -s --user-agent 'Intequeo/0.1' -H 'Authorization: Basic $auth' 'https://jira.ncbi.nlm.nih.gov/rest/api/2/search?jql=project+=+SYS+AND+component+=+UNIX+AND+assignee+is+EMPTY+AND+(status+=+Open+OR+status+=+New)+ORDER+BY+created+DESC'];
	$current_ticket_count = decode_json($current_ticket_count);
	if ($i) {
		if ($MODE eq "standalone" && $current_ticket_count->{'total'} > $last_ticket_count) {
			system "osascript ffjiranotify.scpt "+$current_ticket_count->{'issues'}[0]->{'key'};
		}
		sleep 30;
	}
	$current_ticket_count = $current_ticket_count->{'total'};
	print "$current_ticket_count\n" if $MODE eq "subprocess";
	STDOUT->flush;
	$last_ticket_count = $current_ticket_count;
} while (++$i);
