package Test::Lystyng::Schema::Result::List;

use base qw(Test::Class);
use Test::More;
use Moose;

with 'Test::Role::WithSchema';

sub basic : Tests {
  my $self = shift;

  my $user_rs = $self->schema->resultset('User');
  my $list_rs = $self->schema->resultset('List');
  my $user = $user_rs->create({
    name     => 'Test User',
    username => 'user',
    password => 'pass',
    email    => 'user@example.com',
  });

  my $list = $user->add_to_lists({
    title => 'test list',
    slug  => 'test',
  });

  ok($list, 'Got a list');
  isa_ok($list, 'Lystyng::Schema::Result::List');

  is(scalar $user->lists, 1, 'User owns one list');

  my ($list2) = $list_rs->search({
    user => $user->id,
    slug => 'test',
  });

  ok($list2, 'Got a list from the database...');
  is($list2->title, 'test list', '... and it has the correct title');

  $list_rs->delete;
  $user_rs->delete;
}

1;
