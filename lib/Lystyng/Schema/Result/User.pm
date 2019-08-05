use utf8;
package Lystyng::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Lystyng::Schema::Result::User

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::EncodedColumn>

=back

=cut

__PACKAGE__->load_components("EncodedColumn");

=head1 TABLE: C<user>

=cut

__PACKAGE__->table("user");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 username

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 email

  data_type: 'varchar'
  is_nullable: 0
  size: 200

=head2 password

  data_type: 'char'
  encode_args: {algorithm => "SHA-1",format => "hex",salt_length => 10}
  encode_check_method: 'check_password'
  encode_class: 'Digest'
  encode_column: 1
  is_nullable: 0
  size: 64

=head2 verify

  data_type: 'char'
  is_nullable: 1
  size: 32

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "username",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "email",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "password",
  {
    data_type           => "char",
    encode_args         => { algorithm => "SHA-1", format => "hex", salt_length => 10 },
    encode_check_method => "check_password",
    encode_class        => "Digest",
    encode_column       => 1,
    is_nullable         => 0,
    size                => 64,
  },
  "verify",
  { data_type => "char", is_nullable => 1, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 friendship_user1s

Type: has_many

Related object: L<Lystyng::Schema::Result::Friendship>

=cut

__PACKAGE__->has_many(
  "friendship_user1s",
  "Lystyng::Schema::Result::Friendship",
  { "foreign.user1" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 friendship_user2s

Type: has_many

Related object: L<Lystyng::Schema::Result::Friendship>

=cut

__PACKAGE__->has_many(
  "friendship_user2s",
  "Lystyng::Schema::Result::Friendship",
  { "foreign.user2" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 lists

Type: has_many

Related object: L<Lystyng::Schema::Result::List>

=cut

__PACKAGE__->has_many(
  "lists",
  "Lystyng::Schema::Result::List",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 password_resets

Type: has_many

Related object: L<Lystyng::Schema::Result::PasswordReset>

=cut

__PACKAGE__->has_many(
  "password_resets",
  "Lystyng::Schema::Result::PasswordReset",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user1s

Type: many_to_many

Composing rels: L</friendship_user2s> -> user1

=cut

__PACKAGE__->many_to_many("user1s", "friendship_user2s", "user1");

=head2 user2s

Type: many_to_many

Composing rels: L</friendship_user1s> -> user2

=cut

__PACKAGE__->many_to_many("user2s", "friendship_user1s", "user2");


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2016-12-13 17:02:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KIsKKbvNVcgIyw6ztSET0g

use Email::Stuffer;

sub json_data {
  my $self = shift;
  
  return {
    name => $self->name,
    username => $self->username,
    url => $self->url,
    email => $self->email,
  };
}

sub url {
  my $self = shift;
  
  return '/user/' . $self->username;
}

sub send_verify {
  my $self = shift;
  my ($url) = @_;

  my $name   = $self->name;
  my $verify = $self->verify;

  my $body = <<EO_EMAIL;

Dear $name,

Thank you for registering for Lystyng.

Please click on the link below to verify your email address.

  $url/$verify

EO_EMAIL

  Email::Stuffer->from('admin@lystyng.com')
                ->to($self->email)
                ->subject('Lystyng: Verify Your Email Address')
                ->text_body($body)
                ->send;
}

sub send_forgot_password {
  my $self = shift;
  my ($url, $pass_code) = @_;

  my $name = $self->name;

  my $body = <<EO_EMAIL;

Dear $name,

Here is your password reset link.

Please click on the link below to set a new password.

* $url/$pass_code

EO_EMAIL

  Email::Stuffer->from('admin@lystyng.com')
                ->to($self->email)
		->subject('Lystyng: Password Reset')
		->text_body($body)
		->send;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
