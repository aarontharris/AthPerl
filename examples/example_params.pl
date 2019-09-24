#!/usr/bin/perl

die "ENV{DEV_BIN} not defined!" unless defined $ENV{DEV_BIN};
BEGIN { push @INC, "$ENV{DEV_BIN}/ATH"; }

use Params;
use Logger;

my $log = Logger->new({loglevel=>$Logger::LOG_LEVEL_DEBUG});


#
# EXAMPLE CSV USAGE
#  --n3=a,b,c'
#  --n3="a","b","c"
#  --n3="a,b,c"
#  --n3='a,b,c'
#  --n3='a','b','c'
#

my $params = Params->new();
$params->add({id=>'param1', type=>Params::STRING, req=>1, desc=>'Example Required Unnamed Param - order matters'});
$params->add({id=>'param2', type=>Params::BOOL, req=>0, desc=>'Example Optional Unnamed Param - order matters'});
$params->add({id=>'param3', type=>Params::STRING, req=>0, desc=>'Example Optional Unnamed Param - order matters'});
$params->add({long=>'namedParam1', short=>'n1', type=>Params::INT, req=>1, desc=>'Example Required Named Param'});
$params->add({long=>'namedParam2', short=>'n2', type=>Params::FLOAT, req=>0, desc=>'Example Required Named Param'});
$params->add({long=>'namedParam3', short=>'n3', type=>Params::CSV, req=>0, desc=>'Example Required Named Param'});
$params->add({long=>'namedParam4', short=>'n4', type=>Params::DATE, req=>0, desc=>'Example Required Named Param'});
$params->addHelp('help');
$params->build(\@ARGV);

# How do I get my params?
my $param1 = $params->get('param1');
$log->d("Param1: $param1");

my $param3 = $params->getCsv('namedParam3');
foreach my $item ( @{$param3} ) {
    $log->d("n3: $item");
}

my $date = $params->getDate('namedParam4');
$log->d("date   MM: $date->[0]");
$log->d("date   DD: $date->[1]");
$log->d("date YYYY: $date->[2]");

# Debugging shortcut to display all entered values
$params->printParams();

