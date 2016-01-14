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

my $sch = eval { Lystyng::Schema->get_schema };
BAIL_OUT($@) if $@;

my %route = (
  register => 200,
  login    => 200,
  logout   => 302,
);

for (keys %route) {
  my $res = $test->request( GET "/$_");
  is( $res->code, $route{$_}, "response status is $route{$_} for /$_" );
}


my $user_hash = {
  username  => 'test',
  name      => 'Test User',
  email     => 'test@example.com',
  password  => 'TEST',
};

my $res = $test->request(POST '/register', [ %$user_hash ]);

ok $res, 'Got a response from /register';
is $res->code, 200, 'Response is 200';
like $res->content, qr[is missing], 'Password2 is missing';

$user_hash->{password2} = 'Something else';

$res = $test->request(POST '/register', [ %$user_hash ]);

ok $res, 'Got a response from /register';
is $res->code, 200, 'Response is 200';
like $res->content, qr[do not match], 'Passwords do not match';

$user_hash->{password2} = 'TEST';
$res = $test->request(POST '/register', [ %$user_hash ]);

ok $res, 'Got a response from /register';
is $res->code, 302, 'Response is 302';

$sch->resultset('User')->delete;

done_testing;
