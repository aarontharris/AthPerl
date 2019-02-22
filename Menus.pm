#!/usr/bin/perl

###
### Menus
###

package Menus;

use Data::Dumper;
use ATH;

# Prompt the user to choose one of the list items.
# @param ARRAYREF list - items to be displayed
# @return item selected or undef upon invalid selection
sub promptUserPickOne {
  my $list = shift;

  my $count = 1;
  foreach my $item ( @$list ) {
    print sprintf("%2s: %s\n", $count, $item);
    $count++;
  }

  print "Pick #: ";
  my $selection = &getStdInNum();
  if ( ! defined $selection ) {
    return undef;
  }

  my $numItems = &ATH::size($list);
  if ( ! &ATH::numBetweenii($selection, 1, $numItems) ) {
    return undef;
  }

  print "Selection: '$selection'\n";
  return $list->[$selection-1];
}

sub getStdInNum {
  my $input = <main::stdin>;
  chomp($input);
  if ( $input !~ m/^[0-9]+$/ ) {
    return undef;
  }
  return $input;
}

1;
