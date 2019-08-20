use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use lib 'lib';

use Lystyng;

use Lystyng::Schema;

my $sch = eval { Lystyng::Schema->get_schema };
BAIL_OUT("Can't connect to database: $@") if $@;

my $test_user_data = {
  username => 'test',
  name     => 'Test User',
  email    => 'test@example.com',
  password => 'TEST',
};

# Ensure the 'test' user doesn't exist
my $test_user = $sch->resultset('User')->find({
  username => $test_user_data->{username},
});
$test_user->delete if $test_user;

my $app = Lystyng->to_app;
my $test = Plack::Test->create($app);

my %route = (
  ''       => 200,
  'users'   => 200,
  'users/test' => 404,
  'users/test/list/test' => 404,
);

for (keys %route) {
  my $res = $test->request( GET "/$_" );
  is $res->code, $route{$_},
    "response status is $route{$_} for /$_" or
    diag $res->content;
}

my $user = $sch->resultset('User')->create( $test_user_data );

my $res = $test->request(GET '/users/test');
is $res->code, 200, 'response status is 200 for /user/test';

$user->delete;

done_testing;
