
package Logger;

use ATH;
use Data::Dumper;

our $LOG_LEVEL_DEBUG = 0;
our $LOG_LEVEL_INFO  = 1;
our $LOG_LEVEL_WARN  = 2;
our $LOG_LEVEL_ERROR = 3;

our $ANSI_COLOR_16 = 0;
our $ANSI_COLOR_NONE = 1;

sub new {
    my $class = shift;
    my $self = &ATH::mergeHash( shift || {}, {
        loglevel => $LOG_LEVEL_DEBUG,
        eol => "\n",
        color => $ANSI_COLOR_16
    });
    bless $self, $class;
    return $self;
}

sub out {
    my $self = shift;
    my $msg = shift;
    my $args = @_;
    print $msg;
}

sub d {
    my $self = shift;
    my $msg = shift;
    my $args = @_;
    return if ( $self->{loglevel} > $LOG_LEVEL_DEBUG );
    print $self->white("D: " . $msg . $self->{eol});
}

sub i {
    my $self = shift;
    my $msg = shift;
    my $args = @_;
    return if ( $self->{loglevel} > $LOG_LEVEL_INFO );
    print $self->green("I: " . $msg . $self->{eol});
}

sub w {
    my $self = shift;
    my $msg = shift;
    my $args = @_;
    return if ( $self->{loglevel} > $LOG_LEVEL_WARN );
    print $self->yellow("W: " . $msg . $self->{eol});
}

sub e {
    my $self = shift;
    my $msg = shift;
    my $args = @_;
    return if ( $self->{loglevel} > $LOG_LEVEL_ERROR );
    print $self->RED("E: " . $msg . $self->{eol});
}

sub black {
    my $self = shift; my $msg = shift;
    return "\033[0;30m$msg\033[0m" if ( $self->{color} == $ANSI_COLOR_16 );
    return $msg;
}
sub BLACK {
    my $self = shift; my $msg = shift;
    return "\033[0;30;1m$msg\033[0m" if ( $self->{color} == $ANSI_COLOR_16 );
    return $msg;
}
sub red {
    my $self = shift; my $msg = shift;
    return "\033[0;31m$msg\033[0m" if ( $self->{color} == $ANSI_COLOR_16 );
    return $msg;
}
sub RED {
    my $self = shift; my $msg = shift;
    return "\033[0;31;1m$msg\033[0m" if ( $self->{color} == $ANSI_COLOR_16 );
    return $msg;
}
sub green {
    my $self = shift; my $msg = shift;
    return "\033[0;32m$msg\033[0m" if ( $self->{color} == $ANSI_COLOR_16 );
    return $msg;
}
sub GREEN {
    my $self = shift; my $msg = shift;
    return "\033[0;32;1m$msg\033[0m" if ( $self->{color} == $ANSI_COLOR_16 );
    return $msg;
}
sub yellow {
    my $self = shift; my $msg = shift;
    return "\033[0;33m$msg\033[0m" if ( $self->{color} == $ANSI_COLOR_16 );
    return $msg;
}
sub YELLOW {
    my $self = shift; my $msg = shift;
    return "\033[0;33;1m$msg\033[0m" if ( $self->{color} == $ANSI_COLOR_16 );
    return $msg;
}
sub blue {
    my $self = shift; my $msg = shift;
    return "\033[0;34m$msg\033[0m" if ( $self->{color} == $ANSI_COLOR_16 );
    return $msg;
}
sub BLUE {
    my $self = shift; my $msg = shift;
    return "\033[0;34;1m$msg\033[0m" if ( $self->{color} == $ANSI_COLOR_16 );
    return $msg;
}
sub magenta {
    my $self = shift; my $msg = shift;
    return "\033[0;35m$msg\033[0m" if ( $self->{color} == $ANSI_COLOR_16 );
    return $msg;
}
sub MAGENTA {
    my $self = shift; my $msg = shift;
    return "\033[0;35;1m$msg\033[0m" if ( $self->{color} == $ANSI_COLOR_16 );
    return $msg;
}
sub cyan {
    my $self = shift; my $msg = shift;
    return "\033[0;36m$msg\033[0m" if ( $self->{color} == $ANSI_COLOR_16 );
    return $msg;
}
sub CYAN {
    my $self = shift; my $msg = shift;
    return "\033[0;36;1m$msg\033[0m" if ( $self->{color} == $ANSI_COLOR_16 );
    return $msg;
}
sub white {
    my $self = shift; my $msg = shift;
    return "\033[0;37m$msg\033[0m" if ( $self->{color} == $ANSI_COLOR_16 );
    return $msg;
}
sub WHITE {
    my $self = shift; my $msg = shift;
    return "\033[0;37;1m$msg\033[0m" if ( $self->{color} == $ANSI_COLOR_16 );
    return $msg;
}

1;
