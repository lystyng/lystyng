use utf8;
package Lystyng::Schema::Result::Friendship;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Lystyng::Schema::Result::Friendship

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<friendship>

=cut

__PACKAGE__->table("friendship");

=head1 ACCESSORS

=head2 user1

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 user2

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "user1",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "user2",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</user1>

=item * L</user2>

=back

=cut

__PACKAGE__->set_primary_key("user1", "user2");

=head1 RELATIONS

=head2 user1

Type: belongs_to

Related object: L<Lystyng::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user1",
  "Lystyng::Schema::Result::User",
  { id => "user1" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 user2

Type: belongs_to

Related object: L<Lystyng::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user2",
  "Lystyng::Schema::Result::User",
  { id => "user2" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-08-06 09:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PVeBTsidgQW9+3+6IIFo4Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
