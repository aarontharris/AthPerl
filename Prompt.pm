#!/usr/bin/perl

package Prompt;

use ATH;
use Logger;
use Data::Dumper;
use Term::ReadKey;

our $log = Logger->new({loglevel=>$Logger::LOG_LEVEL_DEBUG});

# [ { long=>'', short=>'' } ]
sub prompt {
    my $msg = shift;
    my $options = shift || [];
    my $tries = 0;

    while ( $tries < 3 ) {
        $tries++;
        my $outLong = undef;
        my $outShort = undef;
        my $lookup = {};
        foreach my $opt ( @$options ) {
            my $long = $opt->{'long'};
            my $short = $opt->{'short'};
            $lookup->{$short} = $long;
            if ( $opt == $options->[-1] ) {
                $outLong .= $long;
                $outShort .= $log->WHITE($short);
            } else {
                $outLong .= $long . "|";
                $outShort .= $log->WHITE($short) . "|";
            }
        }

        my $out = undef;
        $out = "$msg: ($outLong)[$outShort]: ";
        print $out;
        my $choice = &readKey();
        print $choice;
        print "\n";

        if ( defined $lookup->{$choice} ) {
            return $lookup->{$choice};
        }
        print $log->red("Invalid Option") . " " . $log->WHITE("'$choice'") . "\n";
    }
    return undef;
}

# Read one keystroke without having to hit [enter]
sub readKey {
    my $key;
    ReadMode 4; # Turn off controls keys
    while (not defined ($key = ReadKey(-1))) { }
    ReadMode 0; # Reset tty mode before exiting
    return $key;
}

1;
