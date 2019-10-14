#!/usr/bin/perl

package GitUtil;

use strict;
use ATH;
use Logger;
use Data::Dumper;

my $log = Logger->new({loglevel=>$Logger::LOG_LEVEL_DEBUG});

#
# return: { 
#       <mode> => [ files... ],  # files for a given mode
#       all => [ files... ],     # all files for all modes
#       unadded => [ files... ], # all files that are not added
#       added => [ files... ], # all files that are added
#   }
#
# Modes: The two character code you get when you do a 'git status -s'
# - |A | - Newly Added And Staged
# - |??| - Untracked or Newly Added And Unstaged
# - |M | - Modified and Staged
# - | M| - Modified and Unstaged
# - etc...
# - |12|
# - - - - 1: Is Added
# - - - - 2: Is Not Added
# - - - - M: Modified
# - - - - A: Added
# - - - - D: Deleted
# - - - - ?: Untracked
#
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
        #$mode =~ s/^\ +//;
        #$mode =~ s/\ +$//;
        push @{$out->{$mode}}, $line;
        push @{$out->{'all'}}, $line;
        if ( $mode =~ /.\S/ ) {
            push @{$out->{'unadded'}}, $line;
        }
        if ( $mode =~ /[^? ]./ ) {
            push @{$out->{'added'}}, $line;
        }
    }

    return $out;
}

sub colorizeStatus {
    my $input = shift; # git status
    my $colorized = undef;

    my $MODE_ADDED = 1;
    my $MODE_UNSTAGED = 2;
    my $MODE_UNTRACKED = 3;

    my $mode = undef;

    my @lines = split("\n", $input);
    foreach my $line ( @lines ) {
        $mode = $MODE_ADDED if ( $line =~ /^Changes to be committed:/ );
        $mode = $MODE_UNSTAGED if ( $line =~ /^Changes not staged for commit:/ );
        $mode = $MODE_UNTRACKED if ( $line =~ /^Untracked files:/ );

        if ( $line =~ /^(\tmodified:\s+[^(]+)(.*)/ ) {
            $line = (( $MODE_ADDED == $mode ) ? $log->green($1) : $log->red($1)) . $2;
        } elsif ( $line =~ /^\t/ ) {
            $line = (( $MODE_ADDED == $mode ) ? $log->green($line) : $log->red($line));
        }
        $colorized .= $line . "\n";
    }

    return $colorized;
}

sub colorizeDiff {
    my $diff = shift;
    my $colorized = undef;

    my @lines = split("\n", $diff);
    foreach my $line ( @lines ) {
        if ( $line =~ /^ / ) {
            # no-op - these are not gitified
        } elsif ( $line =~ /^diff --/ ) {
            $line = $log->WHITE($line);
        } elsif ( $line =~ /^index [a-z0-9]{10}\.\.[a-z0-9]{10} [0-9]+$/ ) {
            $line = $log->WHITE($line);
        } elsif ( $line =~ /^--- [ab]/ ) {
            $line = $log->WHITE($line);
        } elsif ( $line =~ /^\+\+\+ [ab]/ ) {
            $line = $log->WHITE($line);
        } elsif ( $line =~ /^(@@.*@@)(.*)$/ ) {
            $line = $log->cyan($1) . $2;
        } elsif ( $line =~ /^\+/ ) {
            $line = $log->green($line);
        } elsif ( $line =~ /^-/ ) {
            $line = $log->red($line);
        }
        $colorized .= $line . "\n";
    }

    return $colorized;
}

# return 1 if has changes
# return 0 if no changes
sub hasUncommittedChanges {
    my $changes = &getGitStatus();
    my @keys = keys(%$changes);
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
    my $result = &ATH::execute("git branch", {stderr=>1});
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
