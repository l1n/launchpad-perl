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

my $color = 0b00010001;

while (1) {
    my @alsaevent = MIDI::ALSA::input();
    my @data = @{$alsaevent[7]};
    my @status = MIDI::ALSA::status();
    if ($#data == 5 && $data[5] == 3) {
        print "Text looped\n";
    } elsif ($alsaevent[0] == SND_SEQ_EVENT_NOTEON() && !is_noteoff(@alsaevent)) {
        print "@data\n";
        printf "KeyDown %08B\n", $data[1];
        if (($data[1] & 0b00001111) == 0b1000) {
            my $byte = ($data[1] & 0b11110000) / 8 + 1;
            $color = ($byte & 0b1100) * 4 + ($byte & 0b0011) + 0x0C;
            printf "Color   %08B\n", $color;
        } else {
            MIDI::ALSA::output(MIDI::ALSA::noteonevent(0, $data[1], $color, $status[1]));
        }
    } elsif ($alsaevent[0] == SND_SEQ_EVENT_NOTEOFF() || $alsaevent[0] == SND_SEQ_EVENT_NOTEON() && is_noteoff(@alsaevent)) {
        printf "KeyUp   %08B\n", $data[1];
        MIDI::ALSA::output(MIDI::ALSA::noteoffevent(0, $data[1], 0x00, $status[1]+1));
    } else {
        print "@data\n";
    }
}

sub is_noteoff { my @alsaevent = @_;
    if ($alsaevent[0] == MIDI::ALSA::SND_SEQ_EVENT_NOTEOFF()) {
        return 1;
    }
    if ($alsaevent[0] == MIDI::ALSA::SND_SEQ_EVENT_NOTEON()
            and $alsaevent[7][2] == 0) {
        return 1;
    }
    return 0;
}
