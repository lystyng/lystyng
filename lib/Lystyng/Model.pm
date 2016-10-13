package Lystyng::Model;

use Moose;
use Lystyng::Schema;

has schema => (
  isa => 'Lystyng::Schema',
  lazy_build => 1,
  is => 'ro',
);

has user_rs => (
  isa => 'DBIx::Class::ResultSet',
  lazy_build => 1,
  is => 'ro',
);

sub _build_schema {
  return Lystyng::Schema->get_schema
}

sub _build_user_rs {
  return $_[0]->schema->resultset('User');
}

1;
