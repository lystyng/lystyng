package Test::Lystyng::Schema::Result::ListItem;

use base qw(Test::Class);
use Test::More;
use Moose;

with 'Test::Role::WithSchema';

sub basic : Tests {
  my $self = shift;

  my $user_rs = $self->schema->resultset('User');
  my $list_rs = $self->schema->resultset('List');
  my $item_rs = $self->schema->resultset('ListItem');
  my $user = $user_rs->create({
    name     => 'Test User',
    username => 'user',
    password => 'pass',
    email    => 'user@example.com',
  });
  $user->add_to_lists({
      title => 'test list',
      slug  => 'test',
  });

  my $list = $user->lists->first;
  my $item = $list->add_to_list_items({
    title => 'test item',
  });

  ok($item, 'Got an item_rs');
  isa_ok($item, 'Lystyng::Schema::Result::ListItem');

  is(scalar $list->list_items, 1, 'List has one item');

  my ($item2) = $item_rs->search({
    list  => $list->id,
    title => 'test item',
  });

  ok($item2, 'Got a list item from the database...');
  is($item2->title, 'test item', '... and it has the correct title');

  $item_rs->delete;
  $list_rs->delete;
  $user_rs->delete;
}

1;
