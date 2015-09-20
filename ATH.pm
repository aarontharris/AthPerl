#!/usr/bin/perl

package ATH;

use strict;
use Data::Dumper;
use Scalar::Util qw(looks_like_number);
use Exporter qw(import);

our @EXPORT_OK = qw(
  startsWith endsWith contains
  ltrim rtrim trim
  subStringBetween subStringNumber
  findMatchingBracket
  size
);

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

1;
