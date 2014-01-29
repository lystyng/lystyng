package Test::Role::WithSchema;

use strict;
use warnings;
use 5.010;

use Moose::Role;

use Lystyng::Schema;

has schema => (
  is      => 'rw',
  isa     => 'Lystyng::Schema',
  lazy    => 1,
  builder => '_build_schema',
);

sub _build_schema {
  my @errors;
  foreach (qw[LYSTYNG_DB_SERVER LYSTYNG_DB_NAME
              LYSTYNG_DB_USER LYSTYNG_DB_PASS]) {
    push @errors, $_ unless defined $ENV{$_};
  }

  if (@errors) {
    BAIL_OUT("Missing connection info: @errors");
  }

  return Lystyng::Schema->connect(
    "dbi:mysql:hostname=$ENV{LYSTYNG_DB_SERVER};database=$ENV{LYSTYNG_DB_NAME}",
    $ENV{LYSTYNG_DB_USER}, $ENV{LYSTYNG_DB_PASS}
  );
}

1;