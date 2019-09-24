#!/usr/bin/perl

package Params;

#
# USAGE:
# Named Params appear as: --<name>=<value>
# NonNamed Params as: <value>
#
# RULES:
# - All NonNamed Params must precede Named Params
#
# scriptName.pl <NonNamedParam1> <NonNamedParam2> --<Name1>=<Value1> --<Name2>=<Value2>
#
# my $params = Params->new();
# $params->add({ id=>'diff', type=>Params::STRING, req=>1, desc=>"The diff number in Phabricator" });
# $params->add({ id=>'branch', type=>Params::STRING, req=>0, desc=>"The branch to contain the pulled diff" });
# $params->add({ long=>'namedValue1', short=>'n', type=>Params::STRING, req=>0, desc=>"A Sample Named Value" });
# $params->build(\@ARGV)
# my $diff = $params->get('diff');
# my $branch = $params->get('branch');
#

use ATH;
use Logger;
use Data::Dumper;

use constant {
    STRING => "string",
    BOOL => "bool",
    CSV => "csv",
    INT => "int",
    FLOAT => "float",
    DATE => "MM-DD-YYYY"
};

my $TYPES = [
    STRING, BOOL, CSV, INT, FLOAT, DATE
];

my $log = Logger->new({loglevel=>$Logger::LOG_LEVEL_DEBUG});

# @param cmd => program name
sub new {
    my $class = shift;
    my $self = &ATH::mergeHash( shift || {}, {
        # defaults go here
        definitions => [],
        firstNamedParamIdx => -1
    });
    bless $self, $class;
    return $self;
}

#
# NonNamed Params
# - - DEFINE KEY 'id'
# - - NOT DEFINED KEY 'long' or 'short'
# - - Obtained via 'id'
# Named Params
# - - DEFINE KEY 'long' and/or 'short'
# - - OPTIONAL DEFINED KEY 'id'
# - - Obtained via 'id' else 'long'
# 
# NonNamed Params must be defined before Named Params
#
# NonNamed Params that are REQUIRED must precede OPTIONAL NonNamed Params (duh)
# 
# EXAMPLE
#    $params->add({ id=>'u1', type=>Params::STRING, req=>1, desc=>"Unnamed 1" });
#    $params->add({ id=>'u2', type=>Params::STRING, req=>0, desc=>"Unnamed 2", value="asdf" });
#    $params->add({ long=>'diff', short=>'d', type=>Params::STRING, req=>1, desc=>"The diff number in Phabricator" });
#    $params->add({ long=>'branch', short=>'b', type=>Params::STRING, req=>0, desc=>"The branch to contain the pulled diff" });
#
sub add {
    my $self = shift;
    my $def = shift;

    if ( ! defined $def->{id} && ! defined $def->{long} ) {
        print Dumper($def);
        die "ERR: Missing id or long\n";
    }

    if ( !&ATH::arrayContainsString($TYPES, $def->{type}) ) {
        die "ERR: Invalid Type: '$def->{type}'";
    }

    if ( ! defined $def->{id} ) {
        $def->{id} = $def->{long};
    }

    push(@{$self->{definitions}}, {
        id => $def->{id},
        long => $def->{long},
        short => $def->{short},
        type => $def->{type},
        req => $def->{req},
        desc => $def->{desc},
        value => $def->{value},
        help => $def->{help}
    });

    if ( $self->{firstNamedParamIdx} == -1 && (defined $def->{long}) ) {
        $self->{firstNamedParamIdx} = &ATH::arraySize($self->{definitions}) - 1;
    }
}

sub addHelp {
    my $self = shift;
    my $long = shift;
    $self->add({'long'=>$long, 'help'=>1, type=>BOOL, req=>0, desc=>'Help'});
}

#
# EXAMPLE:
#   $params->build( \@ARGV, 0 )
#
# @param \ARRAY argv # @ARGV command line args
# @param INT?   die # Default = 0
#                   - 0: Meaningful error + usage + exit
#                   - 1: Die w/ Meaningful error
#
sub build {
    my $self = shift;
    my $argv = shift;
    my $die = shift || 0; # shows usage by default, else die with meaningful error

    my $params = {};

    { # reorder help to the end of definitions
        my $help = undef;
        my $tmp = undef;
        foreach my $def ( @{$self->{definitions}} ) {
            if ( $def->{help} ) {
                $help = $def;
            } else {
                push( @$tmp, $def );
            }
        }
        if ( defined $help ) {
            push( @$tmp, $help );
        }
        $self->{definitions} = $tmp;
    }

    { # make sure all args map to a definitions
        my $pos = 0;
        my $nonNameAllowed = 1;
        foreach my $arg (@$argv) {
            my $def = $self->__findDef($arg, $pos, $nonNameAllowed);
            if ( defined $def ) {
                if ( $def->{help} ) {
                    $self->usage();
                    exit(0);
                }
                if ( defined $def->{long} ) {
                    $nonNameAllowed = 0;
                }
                $params->{$def->{id}} = $def;
            } else {
                my $err = "Unrecognized argument: '$arg'";
                &ATH::usageFail($err, $die, sub{$self->usage()});
            }

            $def->{value} = $self->__parseValue($def, $arg);

            $pos += 1;
        }
    }

    { # make sure all required definitions have values
        foreach my $def ( @{$self->{definitions}} ) {
            if ( defined $def->{req} && $def->{req} ) {
                if ( defined $params->{$def->{id}} ) {
                    # great
                } else {
                    my $err = "Missing $def->{desc}";
                    &ATH::usageFail($err, $die, sub{$self->usage()});
                }
            }
        }
    }

    { # we made it, lets provide a lookup
        foreach my $def ( @{$self->{definitions}} ) {
            $self->{lookup}->{$def->{id}} = $def;
        }
    }
}

sub get {
    my $self = shift;
    my $id = shift; # OR 'long'
    return $self->{lookup}->{$id}->{value};
}

sub getCsv {
    my $self = shift;
    my $id = shift; # OR 'long'
    my @result = undef;
    my $value = $self->get($id);
    die "$id is not a " . CSV if ( CSV ne $self->getDef($id)->{type} );
    if ( $value =~ /,/ ) {
        @result = split(',', $value);
    } else {
        @result = ( $value );
    }
    return \@result;
}

sub getDate {
    my $self = shift;
    my $id = shift; # OR 'long'
    my $value = $self->get($id);
    die "$id is not a " . DATE if ( DATE ne $self->getDef($id)->{type} );
    my @result = split('-', $value);
    return \@result;
}

sub getDef {
    my $self = shift;
    my $id = shift; # OR 'long'
    return $self->{lookup}->{$id};
}

sub getAllHash {
    my $self = shift;
    my $out = {};
    foreach my $def ( @{$self->{definitions}} ) {
        $out->{$def->{id}} = $def->{value};
    }
    return $out;
}

# Be careful, if you have unordered values such as --named values
# this may not give you predictable results
sub getAllArray {
    my $self = shift;
    my @out;
    foreach my $def ( @{$self->{definitions}} ) {
        push @out, $def->{value};
    }
    return @out
}

sub __parseValue {
    my $self = shift;
    my $def = shift;
    my $arg = shift;

    my ($hyphenated, $name, $value) = $self->__splitArg($arg);

    if ( BOOL eq $def->{type} ) {
        # $log->d("bool: a='$arg', h='$hyphenated', n='$name', v='$value'");
        if ( ! defined $value ) {
            $value = 1;
        } elsif ( lc($value) eq "f" || lc($value) eq "false" ) {
            $value = 0;
        } elsif ( $value eq "0" ) {
            $value = 0;
        } elsif ( $value eq "1" ) {
            $value = 1;
        } elsif ( lc($value) eq "t" || lc($value) eq "true" ) {
            $value = 1;
        } else {
            &ATH::usageFail("Unrecognized " . $def->{type} . " value: '$value'", 0, sub{$self->usage()} );
        }
    }

    elsif ( INT eq $def->{type} ) {
        if ( $value =~ /^[0-9]+$/ ) {
            # NO OP
        } else {
            &ATH::usageFail("Unrecognized " . $def->{type} . " value: '$value'", 0, sub{$self->usage()} );
        }
    }

    elsif ( FLOAT eq $def->{type} ) {
        if ( $value =~ /^[0-9]+$/ || $value =~ /^[0-9]*\.[0-9]+$/ ) {
            # NO OP
        } else {
            &ATH::usageFail("Unrecognized " . $def->{type} . " value: '$value'", 0, sub{$self->usage()} );
        }
    }

    elsif ( CSV eq $def->{type} ) {
        # NO OP - stored as string, parsed into array upon $params->getCsv()
    }

    elsif ( DATE eq $def->{type} ) {
        if ( $value =~ /^\d{1,2}-\d{1,2}-\d{4}$/ ) {
            # NO OP - stored as string, parsed into array upon $params->getDate()
        } else {
            &ATH::usageFail("Unrecognized " . $def->{type} . " value: '$value'", 0, sub{$self->usage()} );
        }
    }

    return $value;
}

sub usage {
    my $self = shift;
    my $idx = 0;
    my $maxWidth = 0;
    my $output = undef;

    my $comput = {};
    my $widths = {};
    foreach my $def ( @{$self->{definitions}} ) {
        my $id = $def->{id};
        my $c = {};

        my $item = undef;
        if ( $def->{help} ) {
            $item = $def->{long};
            $c->{abbr} = $def->{long};
        } elsif ( defined $def->{long} ) {
            my $name = $def->{long};
            my $type = $def->{type};
            $item = "--$name=<$type>";
            $c->{abbr} = $item;
        } else {
            my $type = $def->{type};
            $item = "arg[$idx]:<$type>";
            $c->{abbr} = "<$type>";
        }
        $c->{item} = $item;

        my $width = length($item);
        $c->{width} = $width;
        if ( $width > $maxWidth ) {
            $maxWidth = $width;
        }

        $c->{req} = $log->WHITE("Optional");
        if ( $def->{req} ) {
            $c->{req} = $log->RED("Required");
        }

        $c->{desc} = $def->{desc};

        $comput->{$id} = $c;

        $idx += 1;
    }

    print "Usage: ";
    foreach my $def ( @{$self->{definitions}} ) {
        if ( $def->{help} ) {
            next;
        }
        my $c = $comput->{$def->{id}};
        print $c->{abbr} . " ";
    }
    print "\n";

    foreach my $def ( @{$self->{definitions}} ) {
        my $c = $comput->{$def->{id}};
        my $padWidth = $maxWidth - $c->{width};
        my $pad = " " x $padWidth;
        print "   " . $c->{item} . $pad . "   # " . $c->{req} . " # " . $c->{desc} . "\n";
        if ( defined $def->{short} ) {
            print "   --" . sprintf('%-'.$maxWidth.'s', $def->{short}) . " # ALIAS OF # --". $def->{long} ."\n";
        }
    }

}

# $self->__findDef( arg, 2 ) # name based
# arg may be the value OR arg may be --name=value, we'll figure that out here
sub __findDef {
    my $self = shift;
    my $arg = shift;
    my $pos = shift;
    my $nonNameAllowed = shift;

    # Named
    # If arg ^--
    #   It is probably a --name=value
    #   However if name does not match && position matches a NonNamed field
    #   Then treat it as NonNamed

    # NonNamed
    # If arg ! ^--
    # OR --name does not match AND pos matches a NonNamed

    # NOTE
    # If we've encountered a Named Param, we can no longer find a NonNamed
    # So nonNameAllowed is a hack to support this

    my ($hyphenated, $name, $value) = $self->__splitArg($arg);

    my $def = $self->__findByName($name);
    if ( $hyphenated && defined $def ) {
        return $def;
    }

    $def = $self->{definitions}->[$pos];
    if ( $nonNameAllowed && ! defined $def->{long} ) {
        return $def;
    }

    # FAIL
    return undef;
}

sub __splitArg {
    my $self = shift;
    my $arg = shift;

    my $hyphenated = undef;
    my $name = undef;
    my $value = undef;
    if ( $arg =~ m/^--(.*)/ ) {
        $hyphenated = 1;
        my $tmp = $1;
        if ( $tmp =~ /=/ ) {
            ($name,$value) = split('=', $tmp);
        } else {
            $name = $tmp;
            $value = undef;
        }
    } else {
        $value = $arg;
    }
    return ($hyphenated, $name, $value);
}

sub __findByName {
    my $self = shift;
    my $name = shift; # short or long
    if ( defined $name && $name ne "" ) {
        foreach my $d ( @{$self->{definitions}} ) {
            if ( $d->{long} eq $name || $d->{short} eq $name ) {
                return $d;
            }
        }
    }
    return undef;
}

sub printParams {
    my $self = shift;
    foreach my $def ( @{$self->{definitions}} ) {
        if ( defined $def->{value} ) {
            print "$def->{id}='$def->{value}'\n";
        }
    }
}

sub printDefinitions {
    my $self = shift;
    print Dumper($self->{definitions});
}

1;