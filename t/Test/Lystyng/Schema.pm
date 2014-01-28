package Test::Lystyng::Schema;

use base 'Test::Class';
use Test::More;

use lib 'lib';

sub check_connect : Test(2) {
  BAIL_OUT('Missing connection info')
    unless $ENV{LYSTYNG_DB_SERVER} && $ENV{LYSTYNG_DB_NAME} &&
           $ENV{LYSTYNG_DB_USER}   && $ENV{LYSTYNG_DB_PASS};

  use_ok('Lystyng::Schema');

  my $sch = Lystyng::Schema->connect(
    "dbi:mysql:hostname=$ENV{LYSTYNG_DB_SERVER};database=$ENV{LYSTYNG_DB_NAME}",
    $ENV{LYSTYNG_DB_USER}, $ENV{LYSTYNG_DB_PASS}
  );

  ok($sch);
}

1;
