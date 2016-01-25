#!/usr/bin/perl

use strict;
use warnings;

use local::lib 'perl5';

use MIDI::ALSA(':CONSTS');

MIDI::ALSA::client('launchpad-perl', 1, 1, 1);
MIDI::ALSA::connectfrom(0, 24, 0) or die "Can't connect from Launchpad S: $!";
MIDI::ALSA::connectto(1, 24, 0) or die "Can't connect to Launchpad S: $!";
MIDI::ALSA::start() or die "Can't start MIDIing: $!";

MIDI::ALSA::output(MIDI::ALSA::noteonevent(0xB0, 0x00, 0x00));

while (1) {
    my @alsaevent = MIDI::ALSA::input();
    my @data = @{$alsaevent[7]};
    if ($#data == 5 && $data[5] == 3) {
        print "Text looped\n";
    } elsif ($data[2] == 0x7F) {
        printf "KeyDown %08B\n", $data[1];
        MIDI::ALSA::output(MIDI::ALSA::noteevent(0, $data[1], 0x0F, 0, 1));
    } elsif ($data[2] == 0x00) {
        printf "KeyUp   %08B\n", $data[1];
    } else {
        print "@data\n";
    }
    print MIDI::ALSA::status();
}
