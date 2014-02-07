use Test::More;
use strict;
use warnings;

use lib 'lib';

# the order is important
use Lystyng;
use Dancer::Test;

use Lystyng::Schema;

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

my $sch = Lystyng::Schema->connect(
  "dbi:mysql:database=$ENV{LYSTYNG_DB_NAME}",
  $ENV{LYSTYNG_DB_USER},                                 
  $ENV{LYSTYNG_DB_PASS},
) or BAIL_OUT("Can't connect to database");

my $user = $sch->resultset('User')->create({
  username => 'test',
  name     => 'Test User',
  email    => 'test@example.com',
});

route_exists [ GET => '/user/test' ],
             'a get route is now defined for /user/test';
response_status_is [ GET => '/user/test' ], 200,
                   'response status is 200 for /user/test';

$user->delete;

done_testing;
