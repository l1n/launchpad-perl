#!/bin/perl

use strict;
use warnings;

use Data::Dumper;
use IO::Handle;
use JSON;

autoflush STDOUT              0;
my $first                   = 1;
# local $Data::Dumper::Purity = 1;
# local $Data::Dumper::Terse  = 1;

my $user = $ENV{USER};
my $loca = `find '/Users/$user/Library/Application Support/Firefox/Profiles/' -name recovery.jsonlz4 | fgrep default`;
chomp $loca;

die "Couldn't locate recovery.jsonlz4!" unless -f $loca;
while (1) {
	my $buf;
	$buf .= Data::Dumper->Dump([decode_json `./dejsonlz4 '$loca'`], [qw(ftab)]);
	$buf =~ s/\n//g;
	$buf .= "\n";
	print $buf;
	STDOUT->flush;
	sleep 1;
	$first = 0;
}
