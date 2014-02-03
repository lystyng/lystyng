use Test::More;
use strict;
use warnings;

use lib 'lib';

# the order is important
use Lystyng;
use Dancer::Test;

my %route = (
  register => 200,
  login    => 200,
  logout   => 302,
);

for (keys %route) {
  route_exists [ GET => "/$_" ], "a get route handler is defined for /$_";
  response_status_is ['GET' => "/$_"], $route{$_},
    "response status is $route{$_} for /$_";
}

done_testing;
