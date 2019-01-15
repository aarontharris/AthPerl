#!/usr/bin/perl

package Exec;

use ATH;
use Data::Dumper;

sub new {
    my $class = shift;
    my $params = shift;

    my $self = {
        debug  => undef, # inherit default from ATH::execute
        select => undef
    };
    $self = &ATH::mergeHash( $params, $self ); # params overwrites self

    bless $self, $class;
    return $self;
}

sub ex {
    my $self = shift;
    my $cmd = shift;
    my $flags = shift || {};
    return &ATH::execute($cmd, {debug=>$self->{debug}, stderr=>$flags->{stderr}});
}

# Confirmation Options for executing commands
sub exConfirm {
    my $self = shift;
    my $cmd = shift;
    my $flags = shift || {};
    my $out = undef;

    my $exFlags = {
        debug=>$self->{debug},
        stderr=>$flags->{stderr}
    };

    if ( $self->{select} eq "a" ) {
        $out = $self->ex($cmd, $exFlags);
    } elsif ( $self->{select} eq "c" ) {
        # no-op - canceled
    } else {
        print "'$cmd'\n";
        print "Are you sure? [y|n|a|c] (y=default): ";
        my $input = <main::stdin>;
        chomp($input);

        $input = lc($input);

        if ( $input eq "n" ) {
            print "Skipped '$cmd'\n";
        } elsif ( $input eq "a" ) {
            $out = $self->ex($cmd, $exFlags);
            $self->{select} = "a";
        } elsif ( $input eq "c" ) {
            $self->{select} = "c";
            print "Cancelling all remaining...";
        } else { # 'y' is default
            $out = $self->ex($cmd, $exFlags);
        }
    }

    return $out;
}



1;
