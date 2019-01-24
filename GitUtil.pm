#!/usr/bin/perl

package GitUtil;

use strict;
use ATH;
use Logger;
use Data::Dumper;

our $MODE_MODIFIED = 'M';
our $MODE_UNTRACKED = '??';
our $MODE_ADDED = 'A';

my $log = Logger->new({loglevel=>$Logger::LOG_LEVEL_DEBUG});

sub getGitStatus {
    my $cmd = "git status -s";
    my $results = &ATH::execute($cmd, {stderr=>1});
    my @lines = split( /(\r\n|\r|\n)/, $results );

    my $out = {};
    
    foreach my $line ( @lines ) {
        chomp($line);
        next if ( length($line) == 0 );
        my $mode = substr($line, 0, 2);
        my $line = substr($line, 3);
        $mode =~ s/^\ +//;
        $mode =~ s/\ +$//;
        push @{$out->{$mode}}, $line;
    }

    return $out;
}

# return 1 if has changes
# return 0 if no changes
sub hasUncommittedChanges {
    my $changes = &getGitStatus();
    my @keys = keys($changes);
    my $numKeys = 1 + $#keys;
    return 1 if ( $numKeys >= 1 );
    return 0;
}

sub getCurrentBranch {
    my $result = &ATH::execute("git branch");
    my @lines = split( /(\r\n|\r|\n)/, $result );
    foreach my $line ( @lines ) {
        chomp($line);
        if ( $line =~ /^\* / ) {
            return substr($line, 2);
        }
    }
    return undef;
}

# @return ARRAYREF of branch names, current branch at index 0
sub getBranches {
    my $result = &ex("git branch");
    my $currentBranch = &GitUtil::getCurrentBranch();

    my @lines = split( /(\r\n|\r|\n)/, $result );
    my @options = ();
    foreach my $line ( @lines ) {
        chomp($line);
        next if ( length($line) == 0 );

        $line = substr($line, 2);
        next if ( $line eq $currentBranch );
        
        push @options, $line;
    }

    my @options = sort { lc($a) cmp lc($b) } @options;
    unshift @options, $currentBranch;
    return \@options;
}



1;
