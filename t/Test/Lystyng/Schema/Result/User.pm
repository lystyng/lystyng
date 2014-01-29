package Test::Lystyng::Schema::Result::User;

use base qw(Test::Class);
use Test::More;
use Moose;

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

sub create : Tests {
  my $self = shift;

  my $user_rs = $self->schema->resultset('User');
  my $user = $user_rs->create({
    username => 'user',
    password => 'pass',
    email    => 'user@example.com',
  });

  ok($user, 'Got a user');
  isa_ok($user, 'Lystyng::Schema::Result::User');
}

1;
