package Test::Lystyng::Schema;

use base 'Test::Class';
use Test::More;

use lib 'lib';

sub check_connect : Test(2) {
  my @errors;
  foreach (qw[LYSTYNG_DB_SERVER LYSTYNG_DB_NAME
              LYSTYNG_DB_USER LYSTYNG_DB_PASS]) {
    push @errors, $_ unless defined $ENV{$_};
  }

  if (@errors) {
    BAIL_OUT("Missing connection info: @errors");
  }

  use_ok('Lystyng::Schema');

  my $sch = Lystyng::Schema->connect(
    "dbi:mysql:hostname=$ENV{LYSTYNG_DB_SERVER};database=$ENV{LYSTYNG_DB_NAME}",
    $ENV{LYSTYNG_DB_USER}, $ENV{LYSTYNG_DB_PASS}
  );

  ok($sch);
}

1;
