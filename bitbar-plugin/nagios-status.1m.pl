#!/usr/bin/perl
use File::Basename;
use File::Spec;
my $dirname = File::Spec->rel2abs(dirname(__FILE__));
system "nohup sh $dirname/../nagios-notify.sh >/dev/null &" unless `ps | grep 'nagios-notify\\.sh'`;
my $max_length = 0;
my @hostgroups = split /\n/, `fgrep -vf $dirname/../nagios-exclude.list $dirname/../nagios-status.tsv`;
foreach (@hostgroups) {
	/^(.*)\t(\d+)/;
	$max_length = $max_length > length $1 ? $max_length : length $1;
	my $bads = $2;
	if ($bads == 0) {
		print ":ballot_box_with_check: ";
	} elsif ($bads > 50) {
		print ":warning: ";
	} elsif ($bads > 20) {
		print ":red_circle: ";
	} elsif ($bads > 10) {
		print ":large_orange_diamond: ";
	} elsif ($bads > 0) {
		print ":small_orange_diamond: ";
	}
}
print "\n---\n";
print map {chomp; /^(.*)\t(.*)/; sprintf "%-${max_length}s %03d | font=Courier href=https://nagios.ncbi.nlm.nih.gov/nagios/cgi/status.cgi?style=overview&hostgroup=%s\n", $1, $2, $1} @hostgroups;
