use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Cookies;

use lib 'lib';

use Lystyng;
use Lystyng::Schema;

sub test_routes {
  my ($routes, $state) = @_;

  for (keys %$routes) {
    my $req = GET "$url/$_";
    $jar->add_cookie_header($req);
    my $res = $test->request( $req );
    is $res->code, $routes->{$_}{$state}{code},
      "response status is $routes->{$_}{$state}{code} for /$_";
    like $res->content, qr/$routes->{$_}{$state}{content}/,
      "content for /$_ looks correct";
  }
}

my $sch = eval { Lystyng::Schema->get_schema };
BAIL_OUT("Can't connect to database: $@") if $@;

my $test_user_data = {
  username => 'test',
  name     => 'Test User',
  email    => 'test@example.com',
  password => 'TEST',
};

# Ensure the test user doesn't already exist
my $test_user = $sch->resultset('User')->find({
  username => $test_user_data->{username},
});
$test_user->delete if $test_user;

my $jar = HTTP::Cookies->new;
my $app = Lystyng->to_app;
my $test = Plack::Test->create($app);

my $url = 'http://localhost';
my %routes = (
  'list/add' => {
    out => {
      code    => 302,
      content => '/login',
    },
    in => {
      code    => 200,
      content => 'Add',
    },
  },
);

diag('Testing logged out');
test_routes(\%routes, 'out');

my $user = $sch->resultset('User')->create( $test_user_data );

BAIL_OUT('User not created, no point in continuing') unless $user;

my $res = $test->request(POST "$url/login", [
  username => $test_user_data->{username},
  password => $test_user_data->{password},
]);

diag('Login response code: ', $res->code);

$jar->extract_cookies($res);

diag('Testing logged in');
test_routes(\%routes, 'in');

$user->delete;

done_testing;
