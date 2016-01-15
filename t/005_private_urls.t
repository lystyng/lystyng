use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Cookies;

use lib 'lib';

use Lystyng;

use Lystyng::Schema;

my $jar = HTTP::Cookies->new;
my $app = Lystyng->to_app;
my $test = Plack::Test->create($app);

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

test_routes(\%routes, 'out');

my $sch = eval { Lystyng::Schema->get_schema };
BAIL_OUT("Can't connect to database: $@") if $@;

my $user = $sch->resultset('User')->create({
  username => 'test',
  name     => 'Test User',
  email    => 'test@example.com',
  password => 'TEST',
});

my $res = $test->request(POST '/login', [
  username => $user->username,
  password => 'TEST',
]);

$jar->extract_cookies($res);

TODO: {
  local $TODO = "Haven't got the cookie handling working yet";
  test_routes(\%routes, 'in');
}

sub test_routes {
  my ($routes, $state) = @_;

  for (keys %$routes) {
    my $req = GET "/$_";
    $jar->add_cookie_header($req);
    my $res = $test->request( $req );
    is $res->code, $routes->{$_}{$state}{code},
      "response status is $routes->{$_}{$state}{code} for /$_";
    like $res->content, qr/$routes->{$_}{$state}{content}/,
      "content for /$_ looks correct";
  }
}

$user->delete;

done_testing;
