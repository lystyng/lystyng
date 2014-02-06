use Test::More;
use strict;
use warnings;

use lib 'lib';

# the order is important
use Lystyng;
use Dancer::Test;

my %route = (
  ''       => 200,
  'user'   => 200,
  'user/test' => 404,
  'user/test/list/test' => 404,
);

for (keys %route) {
  route_exists [ GET => "/$_" ], "a get route handler is defined for /$_";
  response_status_is ['GET' => "/$_"], $route{$_},
    "response status is $route{$_} for /$_";
}

done_testing;
