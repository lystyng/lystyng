use Test::More;
use strict;
use warnings;

use lib 'lib';

# the order is important
use Lystyng;
use Dancer::Test;

use Lystyng::Schema;
my $sch = Lystyng::Schema->connect(
  "dbi:mysql:database=$ENV{LYSTYNG_DB_NAME}",
  $ENV{LYSTYNG_DB_USER}, $ENV{LYSTYNG_DB_PASS},
);

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

my $user_hash = {
  username  => 'test',
  name      => 'Test User',
  email     => 'test@example.com',
  password  => 'TEST',
};

my $response = dancer_response POST => '/register', {
  params => $user_hash,
};

ok $response, 'Got a response from /register';
is $response->status, 200, 'Response is 200';
like $response->content, qr[is missing], 'Password2 is missing';

$user_hash->{password2} = 'Something else';
$response = dancer_response POST => '/register', {
  params => $user_hash,
};

ok $response, 'Got a response from /register';
is $response->status, 200, 'Response is 200';
like $response->content, qr[do not match], 'Passwords do not match';

$user_hash->{password2} = 'TEST';
$response = dancer_response POST => '/register', {
  params => $user_hash,
};

ok $response, 'Got a response from /register';
is $response->status, 302, 'Response is 302';

$sch->resultset('User')->delete;

done_testing;
