#!/usr/bin/perl
use File::Basename;
use File::Spec;
my $dirname = File::Spec->rel2abs(dirname(__FILE__));
system "nohup sh $dirname/../nagios-notify.sh >/dev/null &" unless `ps | grep 'nagios-notify\\.sh'`;
my $max_length = 0;
my $icon_length = 0;
my $menu = "";
# TODO Rewrite this using GD to create a bas64 encoded png with smooth color scalinga a lot smaller
my @hostgroups = split /\n/, `fgrep -vf $dirname/../nagios-exclude.list $dirname/../nagios-status.tsv`;
foreach (@hostgroups) {
	chomp;
	/^(.*)\t(\d+)/;
	$max_length = $max_length > length $1 ? $max_length : length $1;
	my $bads = $2;
	if ($bads == 0) {
		$_ .= "\t color=green";
	} elsif ($bads > 20) {
		$icon_length++;
		print ":red_circle: ";
		$_ .= "\t color=red";
	} elsif ($bads > 10) {
		$icon_length++;
		print ":large_orange_diamond: ";
		$_ .= "\t color=orange";
	} elsif ($bads > 0) {
		$icon_length++;
		print ":small_orange_diamond: ";
		$_ .= "\t color=yellow";
	}
}
$max_length = $max_length > $icon_length * 2.28 ? $max_length : int ($icon_length * 2.28);
print "\n---\n";
print map {chomp; /^(.*)\t(.*)\t(.*)/; sprintf "%-${max_length}s %03d| font=Courier href=https://nagios.ncbi.nlm.nih.gov/nagios/cgi/status.cgi?style=overview&hostgroup=%s%s\n", $1, $2, $1, $3} @hostgroups;
