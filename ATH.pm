#!/usr/bin/perl

package ATH;

use strict;
use Data::Dumper;

our $EXECONLY = 0;
our $PRINTONLY = 1;
our $EXECPRINT = 2;

=cut
use Exporter qw(import);

our @EXPORT_OK = qw(
  startsWith endsWith contains
  ltrim rtrim trim
  subStringBetween subStringNumber
  findMatchingBracket
  size
);
=cut


sub requireInternal {
  my $dir = shift;
  my $pm = shift;

  if ( $ENV{PWD} =~ /$dir$/ ) {
    require "./$pm";
  } else {
    require "./$dir/$pm";
  }
}

sub size {
  my $value = shift;
  my $out = 0;
  if ( ref $value eq "HASH" ) {
    my @keys = keys %$value;
    $out = $#keys + 1;
  }
  elsif ( ref $value eq "ARRAY" ) {
    $out = $#{$value} + 1;
  }
  else {
    $out = 0;
  }
  return $out;
}

sub subStringFloat {
  my $string = shift;
  my $out = undef;

  $string =~ m/^([0-9]*\.[0-9]+)/;
  $out = $1;

  return $out;
}

sub subStringInteger {
  my $string = shift;
  my $out = undef;

  $string =~ m/^([0-9]+)/;
  $out = $1;

  return $out;
}

sub subStringNumeric {
  my $string = shift;
  my $out = undef;

  $string =~ m/^([0-9]+\.?[0-9]*)/;
  $out = $1;

  return $out;
}

# seeks to the first instance of $l then returns everything from $l to the next $r
# if $l is not found or $r is not found after $l, then nothing is returned
sub subStringBetween {
  my $string = shift;
  my $l = shift;
  my $r = shift;
  my $out = undef;

  my $lpos = index( $string, $l );
  if ( $lpos >= 0 ) {
    my $rpos = index( $string, $r, $lpos + 1 );
    if ( $rpos >= 0 ) {
      my $offset = $lpos + 1;
      my $len = $rpos - $offset;
      if ( $len > 0 ) {
        $out = substr( $string, $offset, $len );
      }
    }
  }

  return $out;
}

# obeys nesting
# assumes we're reading left to right
# assumes the first character is the left symbol
# assumes left symbol and right symbol are different
# returns position of matching symbol
sub findMatchingBracket {
  my $string = shift;
  my $l = shift; # left symbol  {
  my $r = shift; # right symbol }

  # 0123456789A
  # {.{.}.}.{.}
  # {     }

  my $pos = 0;
  my $lCount = 1;

  while ( $lCount > 0 ) {
    my $rpos = index( $string, $r, $pos + 1 );
    my $lpos = index( $string, $l, $pos + 1 );

    if ( $lpos != -1 && $lpos < $rpos ) {
      $lCount += 1;
      $pos = $lpos;
    } else {
      $lCount -= 1;
      $pos = $rpos;
    }

    if ( $pos == -1 ) {
      last;
    }
  }
  
  return $pos; 
}

sub startsWith {
  my $string = shift;
  my $pattern = shift;
  return $string =~ /^$pattern/;
}

sub endsWith {
  my $string = shift;
  my $pattern = shift;
  return $string =~ /$pattern$/g;
}

sub contains {
  my $string = shift;
  my $pattern = shift;
  return $string =~ /$pattern/g;
}

sub ltrim { my $s = shift; $s =~ s/^\s+//;       return $s };
sub rtrim { my $s = shift; $s =~ s/\s+$//;       return $s };
sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

# Contents of A and B will merge and return as C
# @param a     - hashref
# @param b     - hashref
# @param flags ? hashref
#         - 'col' # Key Collision Handling
#                 => string - undef = A overwrite B
#                 => string - <token> = A new key will be created as "<token><originalKey>"
#         - 'out' # Output Hash
#                 => hashref - undef = A new hashref will be created and returned.
#                 => hashref - Contents will be placed into the provided hashref and returned.
# @return a new hash 
sub mergeHash {
    my $src = shift || {};
    my $dst = shift || {};
    my $flags = shift || {};

    my $col = $flags->{col} || undef;
    my $out = $flags->{out} || {};

    if ( $out != $dst ) {
        foreach my $key ( keys %$dst ) { $out->{$key} = $dst->{$key}; }
    }

    foreach my $key ( keys %$src ) { 
        if ( defined $col && defined $out->{$key} ) {
            $out->{$col.$key} = $src->{$key};
        } else {
            $out->{$key} = $src->{$key};
        }
    }

    return $out;
}

# @param cmd   - string - command to execute
# @param flags ? hashref
#         - 'debug'  - int
#                   => $ATH::EXECONLY  = EXECUTE ONLY (default)
#                   => $ATH::PRINTONLY = PRINT ONLY
#                   => $ATH::EXECPRINT = EXECUTE AND PRINT
#         - 'mock'   - string - when defined, this value is always returned
#         - 'stderr' - 1 = include stderr in the returned output
# @return chomp(output) of the command.
sub execute {
    my $cmd = shift;
    my $flags = &mergeHash( shift || {}, {
        debug => 0,
        mock => undef,
        stderr => 0, # capture stderr as well?
    } );

    if ( $flags->{stderr} ) {
        $cmd .= " 2>&1";
    }

    my $debug = $flags->{debug};
    
    if ( $debug == $ATH::PRINTONLY ) {
        print "DEBUG: CMD='$cmd'\n";
        exit();
    } 

    my $out = `$cmd`;
    chomp($out);

    if ( defined $flags->{mock} ) {
        $out = $flags->{mock};
    }

    if ( $debug == $ATH::EXECPRINT ) {
        print "DEBUG: CMD='$cmd'\n";
        print "     : OUT='$out'\n";
    }

    return $out;
}


1;
