#!/usr/bin/perl

#############################################
# # How to include from another directory
# BEGIN { push @INC, "$ENV{DEV_BIN}/ATH"; }
# use ATH;
#############################################

### PERL DOC STANDARDS:
#
## Data Types:
#
# - ANY - No type constraints
# - HASH<K,V> - K & V are optional descriptors of what the KEY & VALUE type must be respectively
# - HASHREF<K,V> - K & V are optional descriptors of what the KEY & VALUE type must be respectively
# - \HASH<K,V> - Alias "HASHREF<K,V>"
# - ARRAY<T> - T is an optional descriptor of what the type must be
# - ARRAYREF<T> - T is an optional descriptor of what the type must be
# - \ARRAY<T> - Alias "ARRAYREF<T>"
# - SCALAR
# - - NUMBER - Integers and Floats
# - - - INT - Integers
# - - - - BOOLEAN - 0=false, 1=true
# - - STRING~ - When a SCALAR is not a NUMBER. '~' is optional and describes that there is a regex enforced format constraints
# - - - REGEX - A Regex pattern. Not enforceable - only for documentational purposes
# - - CHAR - A SCALAR but constrained to a single character. Not specifically a STRING or NUMBER
#
## METHOD DOCS
#
# PARAM EXAMPLES:
#
# @param <TYPE> <NAME>? - <DESC> # where '?' is optional and denotes nullable / optional value, lack of means nonnull / required
#
# // SCALAR Detailed / Complex
# @param SCALAR <NAME>? - Expects
#               - <OPTION>?
#               - <OPTION>?
#               - ...
#
# // SCALAR Compact / Simple
# @param SCALAR <NAME>? - <DESC> 
#
# // HASHREF Detailed
# @param HASHREF <NAME>? - Expects
#                - <TYPE>? <KEY> => <TYPE>? <DESC> # <CONDITIONS>
#                - <TYPE>? <KEY> => <TYPE>? <DESC> # <CONDITIONS>
#                - HASHREF? <KEY> => Expects
#                  - <TYPE>? <KEY> => <TYPE>? <DESC> # <CONDITIONS>
#                  - ...
#                - ...
#
# // HASHREF Compact - when self explanatory and simple
# @param HASHREF <NAME>? - { 'akey'? => <TYPE>, 'bkey'? => <TYPE> }
#
# // return Detailed
# @return <TYPE>
#         - WHEN <CONDITION> THEN <DESC>
#         - WHEN <CONDITION> THEN <DESC>
#         - ELSE <DESC>
#
# // return Compact
# @return <TYPE> - WHEN <CONDITION> THEN <DESC> ELSE <DEFAULT>
#

package ATH;

use strict;
use File::Copy;
use Data::Dumper;
use Logger;

our $EXECONLY = 0;
our $PRINTONLY = 1;
our $EXECPRINT = 2;

our $log = Logger->new({loglevel=>$Logger::LOG_LEVEL_DEBUG});

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

sub isArrayRef {
  my $value = shift;
  return 1 if ( ref $value eq "ARRAY" );
  return 0;
}

sub isHashRef {
  my $value = shift;
  return 1 if ( ref $value eq "HASH" );
  return 0;
}

# Note: Supertypes: STRING, NUMBER, INT, BOOLEAN
sub isScalar {
  my $value = shift;
  return 1 if ( !&isArrayRef($value) && !&isHashRef($value) );
  return 0; 
}

# Note: A STRING is also a SCALAR, so isScalar() will also be true
sub isString {
  my $value = shift;
  return 0 unless ( &isScalar( $value ) );
  return 0 if ( &isNumber( $value ) );
  return 1;
}

# Note: Supertypes: INT, BOOLEAN
# Note: A NUMBER is also a SCALAR, so isScalar() will also be true
sub isNumber {
  my $value = shift;
  return 0 unless ( &isScalar( $value ) );
  return 0 unless ( $value =~ m/^\d+\.?\d*$/ );
  return 1;
}

# Note: Supertypes: BOOLEAN
# Note: An Int is also a NUMBER, so isNumber() will also be true
sub isInt {
  my $value = shift;
  return 0 unless ( &isNumber( $value ) );
  return 0 unless ( $value =~ /^\d+$/ );
  return 1;
}

# Note: A Boolean is also an INT, so isInt() will also be true
sub isBoolean {
  die "ATH::isBoolean() is Unimplemented"
}

sub containsArray {
  my $array = shift;
  my $value = shift;

  foreach my $i ( 0..(&size($array)-1) ) {
    return 1 if ( $array->[$i] eq $value );
  }
  return 0;
}

# numBetweenii - Number Between Inclusive Inclusive
# @param INT val - Required
# @param INT min - Required inclusive 
# @param INT max - Required inclusive
# @return BOOLEAN
#         - WHEN val is >= min && <= max THEN 1
#         - ELSE 0
sub numBetweenii {
  my $val = shift;
  my $min = shift; # inclusive
  my $max = shift; # inclusive
  return $val >= $min && $val <= $max;
}

# get environment variable with default or fail options
# @param ANY key - Required
# @param ANY default - Optional, if undef, then die if not present
# @return WHEN key is present THEN $ENV{$key}
#         ELSE default if present else die.
sub getEnv {
  my $key = shift;
  my $default = shift;
  my $result = undef;
  if ( defined $ENV{$key} ) {
    $result = $ENV{$key};
  } elsif ( defined $default ) {
    $result = $default;
  } else {
    die "Environment Variable '$key' is not defined";
  }
  return $result;
}

sub requireInternal {
  my $dir = shift;
  my $pm = shift;

  if ( $ENV{PWD} =~ /$dir$/ ) {
    require "./$pm";
  } else {
    require "./$dir/$pm";
  }
}

# When HASHREF, size = # of keys
# When ARRAYREF, size = # of elements
# When SCALAR, size = # of characters in number of string
sub size {
  my $value = shift;
  my $out = 0;

  #if ( ref $value eq "HASH" ) {
  if ( &isHashRef( $value ) ) {
    my @keys = keys %$value;
    $out = $#keys + 1;
  }
  elsif ( &isArrayRef( $value ) ) {
    # $out = $#{$value} + 1;
    $out = scalar @$value;
  }
  elsif ( &isScalar( $value ) ) {
    $out = length( $value );
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

sub containsString {
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

# @param ARRAYREF<STRING> values - values to be joined
# @param STRING? delimiter - used to separate the joined values
# @return STRING - <elem0><delimiter><elem1><delimiter>...
sub strJoin {
  my $values = shift;
  my $delimiter = shift || ',';
  my $joined = "";
  foreach my $value ( @$values ) {
    $joined = $joined . $value . $delimiter;
  }
  return substr($joined, 0, (0 - length($delimiter)));
}

# @param STRING cmd - command to execute
# @param HASHREF? flags - 
#         - BOOLEAN? 'stderr'   - include stderr in the returned output
#         - BOOLEAN? 'verbose'  - EXECUTE AND PRINT - non debug
#         - STRING?  'mock'     - when defined, this value is always returned - cmd is not executed
#         - STRING?  'mockexec' - when defined, this value is always returned - cmd is executed
# @return chomp(output) of the command.
sub execute {
  my $cmd = shift;
  my $flags = &mergeHash( shift || {}, {
    stderr   => 0,
    verbose  => 0,
    mock     => undef,
    mockexec => undef,
  } );

  # Outdated Usages
  die "ATH::execute API has changed" if ( defined $flags->{debug} );

  if ( $flags->{stderr} ) {
    $cmd .= " 2>&1";
  }

  my $debug = $flags->{debug};
  my $exec = 1; $exec = 0 if ( $debug == $ATH::PRINTONLY || $flags->{mock} == 1 );
  my $debugPrint = 0; $debugPrint = 1 if ( $debug == $ATH::PRINTONLY || $debug == $ATH::EXECPRINT );
  my $verbose = $flags->{verbose};

  if ( $debugPrint ) {
    print "DEBUG: CMD='$cmd'\n";
  }





    
    if ( $debug == $ATH::PRINTONLY || $debug == $ATH::EXECPRINT ) {
        print "DEBUG: CMD='$cmd'\n";
        exit() if ( $debug == $ATH::PRINTONLY );
    } elsif ( $flags->{verbose} ) {
        print "CMD='$cmd'\n";
    }

    my $out = `$cmd`;
    chomp($out);

    if ( defined $flags->{mock} ) {
      $out = $flags->{mock};
    }

    if ( $debug == $ATH::EXECPRINT ) {
      print "     : OUT='$out'\n";
    } elsif ( $flags->{verbose} ) {
      print "OUT='$out'\n";
    }

    return $out;
}

sub slurp {
  my $file = shift;
  open FH, '<', $file or return undef;
  my $lineTerminator = $/;
  $/ = undef;
  my $data = <FH>;
  close FH;
  $/ = $lineTerminator;
  return $data;
}

sub readFromDumpFile {
  my $file = shift;
  my $default = shift;
  my $data = &slurp($file);
  my $result = $default;
  return $result if ( length($data) == 0 );
  {
    my $VAR1;
    eval $data;
    $result = $VAR1;
  }
  return $result;
}

sub writeToDumpFile {
  my $file = shift;
  my $data = shift;
  my $back = shift;

  if ( defined $back && -e $file ) {
    my $bakFile = $file . $back;
    copy($file, $bakFile);
  }

  open FH, '>', $file or die "File '$file' not found or invalid permission\n";
  print FH Dumper($data);
  close FH;
}

sub getStringMMDDYYYY {
  my($day, $month, $year) = (localtime)[3,4,5];
  #$month = sprintf '%02d', $month+1;
  #$day   = sprintf '%02d', $day;
  #$year += 1900;
  return sprintf( '%02d%02d%04d', $month+1, $day, $year+1900);
}

sub arrayContainsString {
    my $array = shift;
    my $search = shift;

    if ( ! defined $array ) {
        return 0;
    }
    foreach my $item (@$array) {
        if ( $item eq $search ) {
            return 1;
        }
    }
    return 0;
}

sub arraySize {
    my $array = shift;
    my $size = scalar @$array;
    return $size;
}

#
# EXAMPLE: &ATH::usageFail( "Kapow!", 0, sub{$self->usage()} );
#
# @param STRING msg # Message to be displayed
# @param INT?   die # Default = 0
#                   - 0: Meaningful error + usage + exit
#                   - 1: Die w/ Meaningful error
# @param \SUB? usagePtr # If provided, this method will be called to diplsay usage
#
sub usageFail {
    my $msg = shift;
    my $die = shift || 0;
    my $usagePtr = shift;
    if ( $die ) {
        die $msg;
    } else {
        $log->e($msg);
        if ( defined $usagePtr ) {
            &{$usagePtr}();
        }
        exit(1);
    }
}

sub shortProgramName {
    my @parts = split('/', $0);
    return $parts[-1] . " "
}

1;
