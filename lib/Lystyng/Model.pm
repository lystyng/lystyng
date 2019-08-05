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

has passreset_rs => (
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

sub _build_passreset_rs {
  return $_[0]->schema->resultset('PasswordReset');
}

sub get_all_users {
  my $self = shift;
  return $self->user_rs->all;
}

sub get_user_by_attribute {
  my $self = shift;
  my ($attribute, $value) = @_;

  return $self->user_rs->find({
    $attribute => $value,
  });
}

sub get_user_by_username {
  my $self = shift;
  my ($username) = @_;

  return $self->get_user_by_attribute(
    username => $username,
  );
}

sub get_user_by_email {
  my $self = shift;
  my ($email) = @_;

  return $self->get_user_by_attribute(
    email => $email,
  )
}

sub get_user_list_by_slug {
  my $self = shift;
  my ($user, $slug) = @_;

  return $user->lists->find({
    slug => $slug,
  });
}

sub get_users_lists {
  my $self = shift;
  my ($user) = @_;
  
  return $user->lists;
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

sub update_user_password {
  my $self = shift;
  my ($user, $password) = @_;
  $user->update({ password => $password });
}

sub verify_user {
  my $self = shift;
  
  my ($user) = @_;
  
  $user->update({ verify => undef });
}

sub add_password_reset {
  my $self = shift;
  my ($user, $code) = @_;
  
  $user->add_to_password_resets({ code => $code });
}

sub get_passreset_from_code {
  my $self = shift;
  my ($code) = @_;

  return $self->passreset_rs->find({
    code => $code,
    expires => { '>=' => \'now()' },
  });
}

sub clear_passreset {
  my $self = shift;
  my ($passreset) = @_;
  $passreset->delete;
}

sub add_item_to_user_list {
  my $self = shift;
  my ($username, $list_slug, $item) = @_;

  my $user = $self->get_user_by_username($username);

  my $list = $self->get_user_list_by_slug($user, $list_slug);

  return $list->add_to_list_items($item);
}

1;
