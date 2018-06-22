#!/usr/bin/perl
use strict;
use warnings;
my($hostgroup, $hostname, $hostflags, $hostcount);
$hostgroup = "";
$hostflags = "";
$hostcount = 0;

while (<>) {
	if (/\t/) {
		@{$hostname} = split /\t/;
		if ($hostname->[0] ne $hostgroup) {
			print "\t$hostcount\n" if $hostflags =~ /f/;
			$hostgroup = $hostname->[0];
			print "$hostgroup";
			$hostcount = 0;
			$hostflags = "f";
		}
		$hostcount += $hostname->[3] * 0.5 + $hostname->[4];
	} else {
		if (/^<a/) {
			/hostgroup=(.*?)&/;
			$hostgroup = $1;
			$hostname = "";
		} else {
			/host=(.*?)&/;
			if ($hostname ne $1) {
				$hostname = $1;
				if ($hostcount) {
					print "\t0" if $hostflags !~ /o/;
					print "\t0" if $hostflags !~ /w/;
					print "\t0" if $hostflags !~ /c/;
					print "\n";
				}
				print "$hostgroup\t$hostname";
				$hostflags = "";
				$hostcount++;
			}
			if (/(\d+) OK/) {
				print "\t$1";
				$hostflags .= "o";
			} elsif (/(\d+) WARNING/) {
				if ($hostflags !~ /o/) {
					$hostflags .= "o";
					print "\t0" ;
				}
				/(\d+) WARNING/;
				print "\t$1";
				$hostflags .= "w";
			} elsif (/(\d+) CRITICAL/) {
				if ($hostflags !~ /o/) {
					$hostflags .= "o";
					print "\t0" ;
				}
				if ($hostflags !~ /w/) {
					$hostflags .= "w";
					print "\t0" ;
				}
				/(\d+) CRITICAL/;
				print "\t$1";
				$hostflags .= "c";
			}
		}
	} 
}
if ($hostflags =~ /f/) {
	print "\t$hostcount";
} else {
	print "\t0" if $hostflags !~ /o/;
	print "\t0" if $hostflags !~ /w/;
	print "\t0" if $hostflags !~ /c/;
}
print "\n";
