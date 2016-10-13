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

sub get_all_users {
  my $self = shift;
  return $self->user_rs->all;
}

sub get_user_by_username {
  my $self = shift;
  my $username = (@_);

  return $self->user_rs->find({
    username => $username,
  }, {
    prefetch => 'lists',
  });
}

sub get_user_list_by_slug {
  my $self = shift;
  my ($user, $slug) = @_;
  
  return $user->lists->find({
    slug => $slug,
  });
}

sub add_user_list {
  my $self = shift;
  my ($user, $list_data) = @_;
  
  $user->add_to_lists($list_data);
}

sub add_user {
  my $self = shift;
  my ($user_data) = @_;
  
  $self->user_rs->create($user_data);
}

1;
