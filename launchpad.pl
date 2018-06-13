#!/usr/bin/perl

use strict;
use warnings;

use local::lib 'perl5';

my $device = shift || 'Launchpad S'; # TODO sanitize
my($tx, $rx);
open($tx, "| ./sendmidi dev '$device'") || die "Could not open TX pipe: $!";
open($rx, "./receivemidi dev 'device' |") || die "Could not open RX pipe: $!";
close($tx);
close($rx);
