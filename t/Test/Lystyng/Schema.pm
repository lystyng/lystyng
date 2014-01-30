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

sub check_rs : Tests {
  my $sch = shift->schema;

  foreach (qw[User List ListItem]) {
    ok(my $rs = $sch->resultset($_), "Got resultset for $_");
  }
}

1;
