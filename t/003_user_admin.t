use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use JSON;

use lib 'lib';
use Lystyng;
use Lystyng::Schema;

my $app = Lystyng->to_app;
my $test = Plack::Test->create($app);

my $sch = eval { Lystyng::Schema->get_schema };
BAIL_OUT($@) if $@;

my $test_user_data = {
  username  => 'test',
  name      => 'Test User',
  email     => 'test@example.com',
  password  => 'TEST',
};

# Ensure test user doesn't exist
my $test_user = $sch->resultset('User')->find({
  username => $test_user_data->{username},
});
$test_user->delete if $test_user;

my %route = (
  register => 200,
  login    => 200,
  logout   => 200,
);

for (keys %route) {
  my $res = $test->request( GET "/$_");
  is( $res->code, $route{$_}, "response status is $route{$_} for /$_" );
}

my $res = $test->request(POST '/register',
  Content_type => 'application/json',
  Content => encode_json($test_user_data),
);

ok $res, 'Got a response from /register';
is $res->code, 200, 'Response is 200';
like $res->content, qr[is missing], 'Password2 is missing';

$test_user_data->{password2} = 'Something else';

$res = $test->request(POST '/register',
  Content_type => 'application/json',
  Content => encode_json($test_user_data),
);

ok $res, 'Got a response from /register';
is $res->code, 200, 'Response is 200';
like $res->content, qr[do not match], 'Passwords do not match'
  or diag $res->content;

$test_user_data->{password2} = 'TEST';
$res = $test->request(POST '/register', 
  Content_type => 'application/json',
  Content => encode_json($test_user_data),
);

ok $res, 'Got a response from /register';
is $res->code, 200, 'Response is 200';

$res = $test->request(POST '/password',
  Content_type => 'application/json',
  Content => encode_json({ email => $test_user_data->{email} }),
);

ok $res, 'Got a response from /password';
is $res->code, 200, 'Response is 200';

my $user = $sch->resultset('User')->find({
  username => $test_user_data->{username},
});

my $code = $user->password_resets->first->code;

$res = $test->request(POST '/passreset',
  Content_type => 'application/json',
  Content => encode_json({ 
    code      => $code,
    password1 => 'Newpass',
    password2 => 'Newpass',
  }),
);

ok $res, 'Got a response from /passreset';
is $res->code, 200, 'Response is 200'
  or diag $res->content;

# Clean up after ourselves
$test = $sch->resultset('User')->find({
  username => $test_user_data->{username},
});
$test->password_resets->delete;
$test->delete;

done_testing;
