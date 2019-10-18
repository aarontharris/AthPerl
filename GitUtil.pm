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

# Return an ordered list of {hash, msg} since master -- NOT including master by default
# Ordered such that master is last, and most recent commit is first (you know, like a stack).
# PARAM includeMaster BOOL - defaults to true
sub getStackCommits {
  my $includeMaster = shift || 0;
  my $master = &getHashOfBranch("master") || die "cannot find master";
  my $pageSize = 10;
  my $foundMaster = 0;

  print "master: '$master'\n";

  my $try = 1;
  my @output = undef;
  while ($try <= 4 && !$foundMaster) {
    @output = ();
    my $count = $try * $pageSize;
    my $cmd = "git log --oneline -n$count";
    my $result = &ATH::execute($cmd, {stderr=>1});
    my @lines = split("\n", $result);
    my $isMaster = 0;
    foreach my $line ( @lines ) {
      my $lineHash = substr($line, 0, 10);
      $isMaster = 1 if ( $lineHash eq $master );

      if ( $line =~ /^([a-z0-9]{10}) (.*)/ && (!$isMaster || $includeMaster) ) {
        my $hash = $1;
        my $msg = $2;
        push @output, {hash=>$hash, msg=>$msg, master=>$isMaster};
      }

      if ( $isMaster ) {
        $foundMaster = 1;
        last;
      }
    }
    $try++;
  }

  if ( !$foundMaster ) {
    return [];
  }
  return \@output;
}

# Get the 10 char hash of the given branch or undef
sub getHashOfBranch {
  my $branch = shift || die "Missing branch";
  my $cmd = "git show --oneline --name-only $branch";
  my $result = &ATH::execute($cmd, {stderr=>1});
  if ( $result =~ /^([a-z0-9]{10})/ ) {
    return $1;
  }
  return undef;
}

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
