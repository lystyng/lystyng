package Test::Lystyng::Schema;

use base 'Test::Class';
use Test::More;
use Moose;

use lib 'lib';

with 'Test::Role::WithSchema';

sub check_connect : Tests {

  use_ok('Lystyng::Schema');

  ok(my $sch = shift->schema);
  isa_ok($sch, 'Lystyng::Schema');
}

1;
