#!/usr/bin/perl

use strict;
use warnings;

use local::lib 'perl5';

use Data::Dumper;
use FindBin ();
use File::Basename ();
use File::Spec::Functions qw( catfile );
use IO::Select;
use JSON;
use Math::Int2Base qw( int2base );
use MIME::Base64;
use POSIX;
use Term::ANSIScreen;
use Time::HiRes qw( usleep );
use Term::ReadKey;

# Launchpad S PRM https://d2xhy469pqj8rc.cloudfront.net/sites/default/files/novation/downloads/4700/launchpad-s-prm.pdf

print("\e[3J\033]0;Intequeo\007\n");

my $DEBUG;
my $JIRA_ENABLED;
my $CLEANED_UP;

my $script = File::Basename::basename($0);
my $SELF  = catfile($FindBin::Bin, $script);

$SIG{HUP} = sub {
	print "SIGHUP: Reloading\n" if $DEBUG;
	exec($SELF, @ARGV) || die "Couldn't restart: $!";
};

my $device = shift @ARGV || 'Launchpad S'; # TODO sanitize

$DEBUG = shift @ARGV || 0;
$JIRA_ENABLED = 1;
$CLEANED_UP = 0;

my $is = IO::Select->new();

my @subprocs;

my($tx, $rx, $nx, $ox, $sx, $jx, $fx);
push @subprocs, open($tx, "|-", "./sendmidi", "dev", $device, '--') || die "Could not open TX pipe: $!";
heat($tx);
push @subprocs, open($rx, "-|", "./receivemidi", "dev", $device, "on", "off") || die "Could not open RX pipe: $!";
heat($rx);
$is->add($rx);

push @subprocs, open($nx, "-|", "sh nagios-notify.sh") || die "Could not open Nagios Notifier: $!";
heat($nx);
$is->add($nx);

push @subprocs, open($ox, "-|", "sh outlook-notify.sh") || die "Could not open Outlook Notifier: $!";
heat($ox);
$is->add($ox);

push @subprocs, open($fx, "-|", "perl firefox-sync.pl") || die "Could not open Firefox Sync: $!";
heat($fx);
$is->add($fx);

tx("hex raw B0 00 01\n"); # X-Y layout
tx("hex raw B0 00 00\n"); # Reset
tx("hex raw B0 1E 05\n"); # Set brighness to low
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
		xy(0,1) => {url => '/secure/Dashboard.jspa', status => 'Unknown'},
		xy(1,1) => {url => '/secure/Dashboard.jspa', status => 'Unknown'},
		xy(2,1) => {url => '/secure/Dashboard.jspa', status => 'Unknown'},
		xy(3,1) => {url => '/secure/Dashboard.jspa', status => 'Unknown'},
		xy(0,2) => {url => '/secure/Dashboard.jspa', status => 'Unknown'},
		xy(1,2) => {url => '/secure/Dashboard.jspa', status => 'Unknown'},
		xy(2,2) => {url => '/secure/Dashboard.jspa', status => 'Unknown'},
		xy(3,2) => {url => '/secure/Dashboard.jspa', status => 'Unknown'},
		xy(0,3) => {url => '/secure/Dashboard.jspa', status => 'Unknown'},
		xy(1,3) => {url => '/secure/Dashboard.jspa', status => 'Unknown'},
		xy(2,3) => {url => '/secure/Dashboard.jspa', status => 'Unknown'},
		xy(3,3) => {url => '/secure/Dashboard.jspa', status => 'Unknown'},
		xy(0,4) => {url => '/secure/Dashboard.jspa', status => 'Unknown'},
		xy(1,4) => {url => '/secure/Dashboard.jspa', status => 'Unknown'},
		xy(2,4) => {url => '/secure/Dashboard.jspa', status => 'Unknown'},
		xy(3,4) => {url => '/secure/Dashboard.jspa', status => 'Unknown'},
		xy(0,5) => {url => '/secure/Dashboard.jspa', status => 'Unknown'},
		xy(1,5) => {url => '/secure/Dashboard.jspa', status => 'Unknown'},
		xy(2,5) => {url => '/secure/Dashboard.jspa', status => 'Unknown'},
		xy(3,5) => {url => '/secure/Dashboard.jspa', status => 'Unknown'},
	 );
my %jn = (
		"Open"			=> 0,
		"Stalled"		=> 2,
		"Waiting on Reporter"	=> 1,
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
		'C4'   => 72,
		'G#4'  => 80,
		'A4'   => 81,
		'A#4'  => 82,
		'B4'   => 83,
		'C5'   => 84,
		'C#5'  => 85,
		'D5'   => 86,
		'D#5'  => 87,
		'E5'   => 88,
		'C6'   => 96,
		'C#6'  => 97,
		'D6'   => 98,
		'D#6'  => 99,
		'E6'   => 100,
		'F6'   => 101,
		'F#6'  => 102,
		'G6'   => 103,
		'G#6'  => 104,
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

my @ft;

my $user = $ENV{USER};

push @subprocs, open($sx, "-|", "sh sysnote-load-notify.sh $user") || die "Could not open Sysnote Notifier: $!";
heat($sx);
$is->add($sx);

push @subprocs, open($jx, "-|", "perl", "jira-notify.pl") || warn "Could not open Jira Notifier: $!" && ($JIRA_ENABLED = 0);
if ($JIRA_ENABLED) {
	heat($jx);
	$is->add($jx);
}

ReadMode 'cbreak';
while (1) {
	if ($key = ReadKey(-1)) {
		if ($key eq '`') {
		} elsif ($key eq 'd') {
			print Dumper(\%jh);
		} elsif ($key eq 'q') {
			tx("hex raw B0 00 00\n"); # Reset
			cleanup();
			exit;
		} elsif ($key eq '9') {
			tx("hex raw B0 1E 05\n");
		} elsif ($key eq '0') {
			tx("hex raw B0 1E 00\n");
		} elsif ($kt{$key}) {
			tx("dec on $kt{$key} 63\n");
		}
	} else {
		while (my @fhs = $is->can_read(-1)) {
			foreach my $fh (@fhs) {
				if ($fh == $rx) {
					print "\b\bRX";
					$_ = <$rx>;
					chomp;
					my $raw = $_;
					/      ([A-G]#?-?[0-8])/;
					my $note = $1;
					my ($x, $y) = ($ni{$note} % 16, int ($ni{$note} / 16));
					{
						no warnings;
						print "RX: $note $ni{$note} {$x, $y} $mh{$ni{$note}}\n" if $DEBUG;
					}
# NoteOn/NoteOff toggle behavior implicitly relies on the slowness of Systems Events (AppleScript) in resoponding to tasks
					     if ($y == 7 && $x == 8) {
						$DEBUG = !$DEBUG if $raw =~ /on/;
					} elsif ($y == 6 && $x == 8 && $raw =~ /on/) {
						print "\b\bCO";
						$_ = `osascript fetchDialog.scpt`;
						chomp;
						s/ /%20/g;
						system "osascript", "ffnewtab.scpt", "https://confluence.ncbi.nlm.nih.gov/dosearchsite.action?cql=siteSearch+~+%22$_%22+and+space.type+%3D+%22favourite%22&queryString=$_" if $_;
					} elsif ($y == 5 && $x == 8 && $raw =~ /on/) {
						print "\b\bSP";
						$_ = `osascript fetchSelection.scpt`;
						chomp;
						system "osascript", "ffnewtab.scpt", "https://splunk.ncbi.nlm.nih.gov/en-US/app/search/search?q=search%20$_&display.page.search.mode=smart&dispatch.sample_ratio=1&earliest=rt-1h&latest=rt&sid=rt_1530281791.675292";
					} elsif ($y == 4 && $x == 8 && $raw =~ /on/) {
						print "\b\bJT";
						$_ = `osascript fetchSelection.scpt`;
						chomp;
						if (/^\s*(?:SYS-)?(\d+)\s*$/) {
							system "osascript", "ffnewtab.scpt", "https://jira.ncbi.nlm.nih.gov/browse/SYS-$1";
						} elsif ($_) {
							print "\b\bJS";
							system "osascript", "ffnewtab.scpt", "https://jira.ncbi.nlm.nih.gov/issues/?jql=summary%20~%20%22$_%22%20OR%20description%20~%20%22$_%22%20ORDER%20BY%20updated%20DESC";
						}
					} elsif ($y == 7 && $x == 3) {
						print "\b\bSN";
						system "osascript", "ffnewtab.scpt", "http://sysnoteweb01.be-md.ncbi.nlm.nih.gov/" if $raw =~ /on/;
					} elsif ($y < 1 && $x < 4) {
						print "\b\bMX";
						system "osascript", "app-activate.scpt", "Outlook" if $raw =~ /on/;
						system "osascript", "app-activate.scpt", "Terminal" if $raw =~ /off/;
					} elsif ($y < 6 && $x < 4) {
						print "\b\bJ#";
						my $xy_pack = xy( $x, $y );
						my $ticket = $jh{$xy_pack};
						my $color = 28;
						print "$ticket->{key} ($ticket->{status})\n" if $DEBUG;
						tx("dec on " . $xy_pack . " $color\n");
						system "osascript", "ffnewtab.scpt", "https://jira.ncbi.nlm.nih.gov".$jh{$ni{$note}}{url} if $raw =~ /on/;
					} elsif ($y < 4 && $x < 4) {
						print "\b\bJ!";
						system "osascript", "app-activate.scpt", "Terminal" if $raw =~ /off/;
					} elsif ($y > 5 || $x > 3) {
						print "\b\bNS";
						system "osascript", "ffnewtab.scpt", "https://nagios.ncbi.nlm.nih.gov/nagios/cgi/status.cgi?style=overview&hostgroup=".$mh{$ni{$note}} if $raw =~ /on/;
						my $xy_pack = xy( $x, $y );
						my $color = 28;
						print "$mh{$ni{$note}}\n" if $DEBUG;
						tx("dec on " . $xy_pack . " $color\n");
					} else {
						print "\b\bFF";
						system "osascript", "app-activate.scpt", "Firefox" if $raw =~ /on/;
					}
				} elsif ($fh == $sx) {
					print "\b\bSX";
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
					print "\b\bNX";
					$_ = <$nx>;
					if ($_ eq "CLS\n") {
						cls();
					} else {
						print if $DEBUG;
						chomp;
						my ($host, $bads) = split /\t/;
						next unless $hm{$host};
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
					print "\b\bOX";
					$_ = <$ox>;
					chomp;
					my $BSIZE = 4;
					$_ = 4**$BSIZE - 1 if $_ > 4**$BSIZE - 1;
					my $bin = int2base($_, 4);
					$bin = 0 x ($BSIZE - length $bin) . $bin;
					print "Outlook $bin\n" if $DEBUG;
					my @numeric_code = (
							["off", " 00"],
							["on", " 28"],
							["on", " 31"],
							["on", " 15"],
					);
					foreach (reverse 0 .. ($BSIZE - 1)) {
						my @yneos = @{$numeric_code[$_ < length $bin ? substr($bin, $_, 1) : 0]};
						tx("dec $yneos[0] " . xy( $_ % 4, int ($_ / 4) ) . "$yneos[1]\n");
					}
				} elsif ($fh == $fx) {
					print "\b\bFX";
					$_ = <$fx>;
					print "FFX $_" if $DEBUG;
					next unless $_;
					my $ftab;
					eval $_;
					my @tab_urls;
					foreach (@{$ftab->{windows}}) {
						foreach (@{$_->{tabs}}) {
							push @tab_urls, @{$_->{entries}}[-1]->{url} if @{$_->{entries}}[-1];
						}
					}
					@ft = @tab_urls;
					if ($JIRA_ENABLED) {
						my @jm = keys %jh;
						foreach my $xy_pack (@jm) {
							my $ticket = $jh{$xy_pack};
							my $color = 0;
							print "$ticket->{key} ($ticket->{status})\n" if $DEBUG;
							if (grep {/jira.ncbi/ && /$ticket->{url}/} @ft) {
								$color = 28;
							} elsif ($ticket->{status} eq "Open") {
								$color = 63;
							} elsif ($ticket->{status} eq "Stalled") {
								$color = 32;
							} elsif ($ticket->{status} eq "Waiting on Reporter") {
								$color = 13;
							} elsif ($ticket->{status} eq "Closed") {
								$color = 28;
							} else {
								$color = 15;
							}
							tx("dec on " . $xy_pack . " $color\n");
						}
					}
				} elsif ($JIRA_ENABLED && $fh == $jx) {
					print "\b\bJX";
					$_ = <$jx>;
					$_ .= <$jx>; # Two lines required for a proper parsing, this will hang for up to 60 seconds if desynced
						print "JIRA Buf $_" if $DEBUG;
					my @jparts = split /\t|\n/;
					my $BSIZE = 20;
					my ($ostruct, $cstruct);
					eval {
						$ostruct = from_json($jparts[1]);
						$cstruct = from_json($jparts[3]);
					} ; if ($@) {
						next;
					}
					my @tickets;
					{
						no warnings;
						@tickets = sort {$jn{$a->{fields}->{status}->{name}} <=> $jn{$b->{fields}->{status}->{name}}} @{$ostruct->{issues}};
						push @tickets, sort {$jn{$a->{fields}->{status}->{name}} <=> $jn{$b->{fields}->{status}->{name}}} @{$cstruct->{issues}};
					}
					my $sharp_tickets = $#tickets > $BSIZE ? $BSIZE : $#tickets;
					for (my $i = 0; $i < $sharp_tickets; $i++) {
						my $xy_pack = xy( $i % 4, int ($i / 4) + 1 );
						my $ticket = $jh{$xy_pack};
						$ticket->{key} = $tickets[$i]->{key};
						$ticket->{url} = '/browse/' . $tickets[$i]->{key};
						$ticket->{status} = $tickets[$i]->{fields}->{status}->{name};
						my $color = 0;
						print "$ticket->{key} ($ticket->{status})\n" if $DEBUG;
						if (grep {/jira.ncbi/ && /$ticket->{url}/} @ft) {
							$color = 28;
						} elsif ($ticket->{status} eq "Open") {
							$color = 63;
						} elsif ($ticket->{status} eq "Stalled") {
							$color = 32;
						} elsif ($ticket->{status} eq "Waiting on Reporter") {
							$color = 13;
						} elsif ($ticket->{status} eq "Closed") {
							$color = 28;
						} else {
							$color = 15;
						}
						tx("dec on " . $xy_pack . " $color\n");
					}
					foreach my $i ($sharp_tickets .. ($BSIZE - 1)) {
						my $xy_pack = xy( $i % 4, int ($i / 4) + 1 );
						my $ticket = $jh{$xy_pack};
						$ticket->{url} = '/secure/Dashboard.jspa';
						$ticket->{status} = 'Unknown';
						tx("dec off " . $xy_pack . " 00\n");
					}
				}
			}
		}
	}
	usleep 100000;
}

sub cleanup {
	return if $CLEANED_UP++;
	ReadMode 'normal';

	if (!$DEBUG) {
		tx("hex raw B0 00 00\n");
	}

	print "Killing data sources: @subprocs\n" if $DEBUG;
	kill TERM => $_ foreach @subprocs;
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

END {
	cleanup();
}

