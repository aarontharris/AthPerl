#!/usr/bin/perl

#
# USAGE:
#

# @param STRING method
# @param ARRAYREF<STRING>? params - while each elem must be within quotes, the values themselves will be evaluated

# @example1 ./testATH.pl strJoin "['a','b','c']" "'.'"
# @results1 > 'a.b.c'

die "ENV{DEV_BIN} not defined!" unless defined $ENV{DEV_BIN};
BEGIN { push @INC, "$ENV{DEV_BIN}/ATH"; }

use ATH;

&main();
sub main {
  my $method = shift @ARGV;
  my @params = @ARGV;

  print "Method: '$method'\n";
  foreach my $param ( @params ) {
    print "PARAM:  '$param'\n";
  }

  my $paramStr = &ATH::strJoin(\@params);
  print "Params: '$paramStr'\n";

  our $result = undef;
  my $cmd = "\$result = &ATH::$method( $paramStr );";
  print "CMD: '$cmd'\n";
  eval $cmd;
  print "RESULT: '$result'\n";
  
}