use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use lib 'lib';

use Lystyng;

use Lystyng::Schema;

my $app = Lystyng->to_app;
my $test = Plack::Test->create($app);

my %route = (
  ''       => 200,
  'user'   => 200,
  'user/test' => 404,
  'user/test/list/test' => 404,
);

for (keys %route) {
  my $res = $test->request( GET "/$_" );
  is $res->code, $route{$_},
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

my $res = $test->request(GET '/user/test');
is $res->code, 200, 'response status is 200 for /user/test';

$user->delete;

done_testing;
