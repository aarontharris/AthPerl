#!/usr/bin/perl

require "ATH.pm";
require "JsonParser.pm";
use Data::Dumper;

my $data = {
  key=>"value",
  tf=>"true",
  ft=>"false",
  thing=>[1,2,3],
  blah=>{a=>"b"},
  another=>[
    {a=>1},{b=>2},{c=>3},
    {d=>[5,4,3]}
  ],
  outer=>{inner=>"value"}
};

my $json = new JsonParser();
my $jsonStr = $json->toJsonString($data);
print $jsonStr . "\n";

my $stringData = <<'END_MESSAGE';
{  
   "another":[  
      {  
         "a":1
      },
      {  
         "b":2
      },
      {  
         "c":3
      },
      {  
         "d":[  
            5,
            4,
            3
         ]
      }
   ],
   "blah":{  
      "a":"b"
   },
   "ft":false,
   "key":"value",
   "outer":{  
      "inner":"value"
   },
   "tf":true,
   "thing":[  
      1,
      2,
      3
   ]
}

END_MESSAGE


my $jsonValue = $json->fromJsonString($stringData);
print $stringData . "\n";
print Dumper($jsonValue);

