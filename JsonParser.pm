#!/usr/bin/perl

package JsonParser;

die "ENV{DEV_BIN} not defined!" unless defined $ENV{DEV_BIN};
BEGIN { push @INC, "$ENV{DEV_BIN}/ATH"; }

use Data::Dumper;
use ATH;
use GitUtil;
use Logger;
use Exec;
use strict;

my $DEBUG = 0;
my $log = Logger->new({loglevel=>$Logger::LOG_LEVEL_DEBUG});

sub new {
  my $class = shift;
  my $this = {
  };
  bless $this, $class;
  return $this;
}

sub readFromFile {
  my $this = shift;
  my $file = shift; # || "~/.athstates"
  open FH, '<', $file or return undef;

  my $line = <FH>;
  chomp($line);
  my $data = $this->fromJsonString($line);
  return $data;
}

sub writeToFile {
  my $this = shift;
  my $file = shift; # || "~/.athstates"
  my $data = shift;

  my $jsonStr = $this->toJsonString($data);
  open FH, '>', $file or die "File '$file' not found or invalid permission\n";
  print FH $jsonStr;
  close FH;
}

sub fromJsonString {
  my ($this, $value) = @_;
  return &fromJsonStringInternal( $this, \$value );
}

# {"another":[{"a":1},{"b":2},{"c":3},{"d":[5,4,3]}],"blah":{"a":"b"},"ft":false,"key":"value","outer":{"inner":"value"},"tf":true,"thing":[1,2,3]}
# {"a":{"aa":"aa1","ab":"ab1"},"b":{"ba":"ba1","bb":"bb1"}}
# [["a","b","c"],[1,2,3]]

sub fromJsonStringInternal {
  my ($this, $valueRef) = @_;
  my $out;

  $$valueRef = &ATH::trim($$valueRef);

  # Hash
  if ( &ATH::startsWith( $$valueRef, "{" ) ) {
    my $value = $this->subStringBetweenBrackets($$valueRef, "{", "}");
    $$valueRef = substr( $$valueRef, length($value) + 2 ); # +2 for { and }
    do {
      my $pos = index($value, ":");
      my $key = substr($value, 0, $pos);
      $key = &ATH::subStringBetween($key, "\"", "\"");
      $value = substr($value, $pos + 1); # +1 to consume the :
      $out->{$key} = $this->fromJsonStringInternal(\$value);
      $value = &ATH::trim($value);
    } while ( &ATH::startsWith( $value, "," ) );
  }
  
  # Array
  elsif ( &ATH::startsWith( $$valueRef, '\[' ) ) {
    my $value = $this->subStringBetweenBrackets($$valueRef, '[', ']');
    $$valueRef = substr( $$valueRef, length($value) + 2 ); # +2 for [ and ]
    my $idx = 0;
    do {
      if ( index( $value, "," ) == 0 ) {
        $value = substr( $value, 1 ); # remove ,
      }
      $out->[$idx] = $this->fromJsonStringInternal(\$value);
      $value = &ATH::trim($value);
      $idx += 1;
    } while ( &ATH::startsWith( $value, "," ) );
    
  }
  
  # String, Numeric, Boolean
  else {
    my $type = 'unknown';

    # String
    if ( &ATH::startsWith( $$valueRef, "\"" ) ) {
      $type ="String";
      $out = &ATH::subStringBetween($$valueRef, "\"", "\"");
      my $preceeding = index( $$valueRef, "\"" ); # should be zero but just in case
      my $offset = $preceeding + length($out) + 2; # +2 for each "
      $$valueRef = substr( $$valueRef, $offset );
    }

    # Numeric
    elsif ( 0 != length($out = &ATH::subStringNumeric( $$valueRef )) ) {
      $type ="Numeric";
      my $offset = length($out);
      $$valueRef = substr( $$valueRef, $offset );
    }

    # Boolean
    elsif ( $$valueRef =~ /^true|false/ ) {
      $type ="Boolean";
      if ( &ATH::startsWith( $$valueRef, "true" ) ) {
        $out = "true";
      } else {
        $out = "false";
      }
      my $offset = length($out);
      $$valueRef = substr( $$valueRef, $offset );
    }
  }

  return $out;
}

# find the value from { to } or [ to ] or " to " or true|false or number
sub subStringBetweenBrackets {
  my ($this, $value, $l, $r) = @_;
  my $pos = &ATH::findMatchingBracket($value, $l, $r);
  if ( $pos == -1 ) {
    $value = undef;
  } else {
    $value = substr($value, 1, $pos - 1);
  }
  return $value;
}

sub toJsonString {
  my ($this, $root) = @_;
  my $out;

  if ( ref $root eq "HASH" ) {
    my @joined = ();
    foreach my $key ( sort keys( %$root ) ) {
      my $value = $root->{$key};
      my $valueStr;
      if ( defined $value ) {
        $valueStr = $this->toJsonString($value);
      }
      push @joined, qq|"$key":$valueStr|;
    }
    my $csv = join(",",@joined);
    $out .= "{$csv}";
  } elsif ( ref $root eq "ARRAY" ) {
    my @joined = ();
    foreach my $item ( @$root ) {
      my $value = $item;
      my $valueStr;
      if ( defined $value ) {
        $valueStr = $this->toJsonString($value);
      }
      push @joined, $valueStr;
    }
    my $csv = join(",",@joined);
    $out = "[$csv]";
  } elsif ( ref $root eq "" ) {
    if ( !$this->needsQuotes($root) ) {
      $out = $root;
    } else {
      $out = qq|"$root"|;
    }
  }

  return $out;
}

sub needsQuotes {
  my ( $this, $value ) = @_;
  if ( &ATH::subStringNumeric( $value ) ) {
    return 0;
  }
  if ( $value eq "true" || $value eq "false" ) {
    return 0;
  }
  return 1;
}

1;
