package Test::Role::WithSchema;

use strict;
use warnings;
use 5.010;

use Moose::Role;
use Test::More;

use Lystyng::Schema;

has schema => (
  is      => 'rw',
  isa     => 'Lystyng::Schema',
  lazy    => 1,
  builder => '_build_schema',
);

sub _build_schema {
  my $schema = eval { Lystyng::Schema->get_schema };
  BAIL_OUT($@) if $@;
  return $schema;
}

1;
