#!/usr/bin/perl

use strict;
use warnings;

use local::lib 'perl5';

use FindBin ();
use File::Basename ();
use File::Spec::Functions qw(catfile);
use IO::Select;
use JSON;
use MIME::Base64;
use POSIX;
use Term::ANSIScreen;
use Time::HiRes qw( usleep );
use Term::ReadKey;

# Launchpad S PRM https://d2xhy469pqj8rc.cloudfront.net/sites/default/files/novation/downloads/4700/launchpad-s-prm.pdf

print("\e[3J\033]0;Intequeo\007\n");

my $DEBUG;
my $JIRA_ENABLED;

my $script = File::Basename::basename($0);
my $SELF  = catfile($FindBin::Bin, $script);

$SIG{HUP} = sub {
	print "SIGHUP: Reloading\n" if $DEBUG;
	exec($SELF, @ARGV) || die "Couldn't restart: $!";
};

my $device = shift @ARGV || 'Launchpad S'; # TODO sanitize

$DEBUG = shift @ARGV || 0;
$JIRA_ENABLED = 1;

my $is = IO::Select->new();

my($tx, $rx, $nx, $ox, $sx, $jx);
open($tx, "|-", "./sendmidi", "dev", $device, '--') || die "Could not open TX pipe: $!";
heat($tx);
open($rx, "-|", "./receivemidi", "dev", $device, "on", "off") || die "Could not open RX pipe: $!";
heat($rx);
$is->add($rx);

open($nx, "-|", "sh nagios-notify.sh") || die "Could not open Nagios Notifier: $!";
heat($nx);
$is->add($nx);

open($ox, "-|", "sh outlook-notify.sh") || die "Could not open Outlook Notifier: $!";
heat($ox);
$is->add($ox);

tx("hex raw B0 00 01\n"); # X-Y layout
tx("hex raw B0 00 00\n"); # Reset
tx("hex raw F0 00 20 29 09 01\n"); # Start Text (Yellow, Non-Looping)
tx("hex raw 42 4f 4f 54 49 4e 47 20 55 50\n"); # "BOOTING UP"
tx("hex raw F7\n"); # End Text

my $key;

my %kt = (
		1 =>  0,
		2 =>  1,
		3 =>  2,
		4 =>  3,
		q => 16,
		w => 17,
		e => 18,
		r => 19,
		a => 32,
		s => 33,
		d => 34,
		f => 35,
		z => 48,
		x => 49,
		c => 50,
		v => 51,
	 );

my %hm = (
		ACVALinuxServers => xy(4,1),
		BSDServers => xy(4,0),
		CiscoSwitches => xy(4,2),
		LinuxDesktops => xy(5,1),
		LinuxServers => xy(5,0),
		MacDesktops => xy(6,1),
		MacServers => xy(6,0),
		Netapps => xy(7,2),
		UbuntuLinuxDesktops => xy(7,1),
		UbuntuLinuxServers => xy(7,0),
		VirtualHosts => xy(5,2),
		WindowsServers => xy(6,2),
		blast => 52,
		blastwebservers => 53,
		externalsites => 54,
		ftp => 55,
		fwdaemon => 68,
		gpexec => 69,
		idflow => 70,
		ldapserver => 71,
		mssql => 84,
		nosql => 85,
		pmbackend => 86,
		pmc => 87,
		postgres => 100,
		pubchem => 101,
		pubmed => 102,
		qa => 103,
		rabbitmq => 116,
		solidfire => 117,
		squid => 118,
		structure => 119,
		sybase => xy(0,6),
		sybiq => xy(1,6),
		vhod => xy(2,6),
		virtuoso => xy(3,6),
		webfrontends => xy(0,7),
		webservers => xy(1,7),
		wga => xy(2,7),
		);
my %mh = reverse %hm;

my %jh = (
		xy(0,2) => '/secure/Dashboard.jspa',
		xy(1,2) => '/secure/Dashboard.jspa',
		xy(2,2) => '/secure/Dashboard.jspa',
		xy(3,2) => '/secure/Dashboard.jspa',
		xy(0,3) => '/secure/Dashboard.jspa',
		xy(1,3) => '/secure/Dashboard.jspa',
		xy(2,3) => '/secure/Dashboard.jspa',
		xy(3,3) => '/secure/Dashboard.jspa',
		xy(0,4) => '/secure/Dashboard.jspa',
		xy(1,4) => '/secure/Dashboard.jspa',
		xy(2,4) => '/secure/Dashboard.jspa',
		xy(3,4) => '/secure/Dashboard.jspa',
		xy(0,5) => '/secure/Dashboard.jspa',
		xy(1,5) => '/secure/Dashboard.jspa',
		xy(2,5) => '/secure/Dashboard.jspa',
		xy(3,5) => '/secure/Dashboard.jspa',
	 );
my %jn = (
	"Open"			=> 0,
	"Stalled"		=> 1,
	"Waiting on Reporter"	=> 2,
	"Closed"		=> 3,
);

my %ni = (
		'C-2'  => 0,
		'C#-2' => 1,
		'D-2'  => 2,
		'D#-2' => 3,
		'E-2'  => 4,
		'F-2'  => 5,
		'F#-2' => 6,
		'G-2'  => 7,
		'E-1'  => 16,
		'F-1'  => 17,
		'F#-1' => 18,
		'G-1'  => 19,
		'G#-1' => 20,
		'A-1'  => 21,
		'A#-1' => 22,
		'B-1'  => 23,
		'G#0'  => 32,
		'A0'   => 33,
		'A#0'  => 34,
		'B0'   => 35,
		'C1'   => 36,
		'C#1'  => 37,
		'D1'   => 38,
		'D#1'  => 39,
		'C2'   => 48,
		'C#2'  => 49,
		'D2'   => 50,
		'D#2'  => 51,
		'E2'   => 52,
		'F2'   => 53,
		'F#2'  => 54,
		'G2'   => 55,
		'E3'   => 64,
		'F3'   => 65,
		'F#3'  => 66,
		'G3'   => 67,
		'G#3'  => 68,
		'A3'   => 69,
		'A#3'  => 70,
		'B3'   => 71,
		'G#4'  => 80,
		'A4'   => 81,
		'A#4'  => 82,
		'B4'   => 83,
		'C5'   => 84,
		'C#5'  => 85,
		'D5'   => 86,
		'D#5'  => 87,
		'C6'   => 96,
		'C#6'  => 97,
		'D6'   => 98,
		'D#6'  => 99,
		'E6'   => 100,
		'F6'   => 101,
		'F#6'  => 102,
		'G6'   => 103,
		'E7'   => 112,
		'F7'   => 113,
		'F#7'  => 114,
		'G7'   => 115,
		'G#7'  => 116,
		'A7'   => 117,
		'A#7'  => 118,
		'B7'   => 119,
		'C8'   => 120,
		);

my $user = $ENV{USER};

open($sx, "-|", "sh sysnote-load-notify.sh $user") || die "Could not open Sysnote Notifier: $!";
heat($sx);
$is->add($sx);

open($jx, "-|", "perl", "jira-notify.pl") || warn "Could not open Jira Notifier: $!" && ($JIRA_ENABLED = 0);
my $jira_buffer = '';
if ($JIRA_ENABLED) {
	heat($jx);
	$is->add($jx);
}

ReadMode 'cbreak';
while (1) {
	if ($key = ReadKey(-1)) {
		if ($key eq '`') {
			$SIG{HUP}->();
		} elsif ($kt{$key}) {
			tx("dec on $kt{$key} 63\n");
		}
	} else {
		foreach my $fh ($is->can_read(-1)) {
			if ($fh == $rx) {
				$_ = <$rx>;
				chomp;
				my $raw = $_;
				/      ([A-G]#?-?[0-8])/;
				my $note = $1;
				my ($x, $y) = ($ni{$note} % 16, int ($ni{$note} / 16));
				print "RX: $note $ni{$note} {$x, $y} $mh{$ni{$note}}\n" if $DEBUG;
				if ($y == 7 && $x == 8) {
					$DEBUG = !$DEBUG if $raw =~ /on/;
				} elsif ($y == 7 && $x == 3) {
					system "osascript", "ffnewtab.scpt", "http://sysnoteweb01.be-md.ncbi.nlm.nih.gov/" if $raw =~ /on/;
				} elsif ($y < 2 && $x < 4) {
					system "osascript", "app-activate.scpt", "Outlook" if $raw =~ /on/;
					system "osascript", "app-activate.scpt", "Terminal" if $raw =~ /off/;
				} elsif ($y < 6 && $x < 4) {
					system "osascript", "ffnewtab.scpt", "https://jira.ncbi.nlm.nih.gov".$jh{$ni{$note}} if $raw =~ /on/;
				} elsif ($y < 4 && $x < 4) {
					system "osascript", "app-activate.scpt", "Terminal" if $raw =~ /off/;
				} elsif ($y > 5 || $x > 3) {
					system "osascript", "ffnewtab.scpt", "https://nagios.ncbi.nlm.nih.gov/nagios/cgi/status.cgi?style=overview&hostgroup=".$mh{$ni{$note}} if $raw =~ /on/;
				} else {
					system "osascript", "app-activate.scpt", "Firefox" if $raw =~ /on/;
				}
			} elsif ($fh == $sx) {
				$_ = <$sx>;
				chomp;
				print "$_ sysnotes active\n" if $DEBUG;
				my $color = 46;
				if ($_ == 0) {
					$color = 28;
				} elsif ($_ > 5) {
					$color = 15;
				} elsif ($_ > 0) {
					$color = 13;
				}
				tx("dec on ".xy(3,7)." $color\n");
			} elsif ($fh == $nx) {
				$_ = <$nx>;
				if ($_ eq "CLS\n") {
					cls();
				} else {
					print if $DEBUG;
					chomp;
					my ($host, $bads) = split /\t/;
					my $color = 46;
					if ($bads == 0) {
						$color = 28;
					} elsif ($bads > 50) {
						$color = 15;
					} elsif ($bads > 20) {
						$color = 31;
					} elsif ($bads > 10) {
						$color = 23;
					} elsif ($bads > 0) {
						$color = 13;
					}
					tx("dec on $hm{$host} $color\n");
				}
			} elsif ($fh == $ox) {
				$_ = <$ox>;
				chomp;
				my $BSIZE = 8;
				$_ = 2**$BSIZE - 1 if $_ > 2**$BSIZE - 1;
				my $bin = sprintf "%08b", $_;
				print "Outlook $bin\n" if $DEBUG;
				foreach (reverse 0 .. ($BSIZE - 1)) {
					my @yneos = substr($bin, $_, 1) == 1 ? ("on", " 63") : ("off", " 00");
					tx("dec $yneos[0] " . xy( $_ % 4, int ($_ / 4) ) . "$yneos[1]\n");
				}
			} elsif ($JIRA_ENABLED && $fh == $jx) {
				$jira_buffer .= <$jx>;
				print "JIRA BufLen ". length($jira_buffer) . "\n" if $DEBUG;
				if ($jira_buffer =~ /\n/) {
					my @jira_parts = split /\n/, $jira_buffer;
					$_ = $jira_parts[0];
					print "JIRA Buf $_\n" if $DEBUG;
					$jira_buffer = $jira_parts[1];
				}
				my $BSIZE = 16;
				my $struct = from_json($_);
				my @tickets = sort {$jn{$a->{fields}->{status}->{name}} <=> $jn{$b->{fields}->{status}->{name}}} @{$struct->{issues}};
				my $partition = scalar @{$struct->{issues}} > 16 ? 16 : scalar @{$struct->{issues}};
				for (my $i = 0; $i < $partition; $i++) {
					my $ticket = $tickets[$i];
					$jh{xy( $i % 4, int ($i / 4) + 2 )} = '/browse/' . $ticket->{key};
					my $color = 0;
					if ($ticket->{fields}->{status}->{name} eq "Open") {
						$color = 63;
					} elsif ($ticket->{fields}->{status}->{name} eq "Stalled") {
						$color = 13;
					} elsif ($ticket->{fields}->{status}->{name} eq "Waiting on Reporter") {
						$color = 28;
					} elsif ($ticket->{fields}->{status}->{name} eq "Closed") {
						$color = 44;
					} else {
						$color = 15;
					}
					tx("dec on " . xy( $i % 4, int ($i / 4) + 2 ) . " $color\n");
				}
				foreach ($partition .. ($BSIZE - 1)) {
					$jh{xy( $_ % 4, int ($_ / 4) + 4 )} = '/secure/Dashboard.jspa';
					tx("dec off " . xy( $_ % 4, int ($_ / 4) + 2 ) . " 00\n");
				}
			}
		}
	}
	usleep 10000;
}
END {
	ReadMode 'normal';

	close($tx);
	close($rx);
	close($nx);
	if ($JIRA_ENABLED) {
		close($jx);
	}
}

sub tx {
	$tx->print($_[0]);
	print "TX: ", $_[0] if $DEBUG;
}

sub heat {
	my $ofh = select $_[0];
	$| = 1;
	select $ofh;
}

sub xy {
	return shift() + shift() * 16;
}

# https://stackoverflow.com/a/39801196

sub prompt_for_password {
	ReadMode('noecho');
	print "$_[0]: ";
	my $password = ReadLine(0);
	ReadMode('restore');
	print "\n";

	return $password;
}
