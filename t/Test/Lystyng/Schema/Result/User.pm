package Test::Lystyng::Schema::Result::User;

use base qw(Test::Class);
use Test::More;
use Moose;

with 'Test::Role::WithSchema';

sub basic : Tests {
  my $self = shift;

  my $user_rs = $self->schema->resultset('User');
  my $user = $user_rs->create({
    name     => 'Test User',
    username => 'user',
    password => 'pass',
    email    => 'user@example.com',
  });

  ok($user, 'Got a user');
  isa_ok($user, 'Lystyng::Schema::Result::User');

  my ($user2) = $user_rs->search({
    username => 'user',
  });

  ok($user, 'Got another user');
  isa_ok($user, 'Lystyng::Schema::Result::User');

  foreach (qw[username email]) {
    is($user->$_, $user2->$_, "$_ is correct");
  }
  ok($user->check_password('pass'), 'password is correct');

  $user2->password('another password');
  $user2->update;
  # re-read from db
  $user2->discard_changes;
  ok($user2->check_password('another password'), 'Updated password is correct');

  $user_rs->delete;
}

1;
