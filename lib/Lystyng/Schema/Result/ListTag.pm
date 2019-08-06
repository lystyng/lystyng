use utf8;
package Lystyng::Schema::Result::ListTag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Lystyng::Schema::Result::ListTag

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<list_tag>

=cut

__PACKAGE__->table("list_tag");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 list

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 tag

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "list",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "tag",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 list

Type: belongs_to

Related object: L<Lystyng::Schema::Result::List>

=cut

__PACKAGE__->belongs_to(
  "list",
  "Lystyng::Schema::Result::List",
  { id => "list" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 tag

Type: belongs_to

Related object: L<Lystyng::Schema::Result::Tag>

=cut

__PACKAGE__->belongs_to(
  "tag",
  "Lystyng::Schema::Result::Tag",
  { id => "tag" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-08-06 09:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xR4EdyAcegsKKB8j8tY8WA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
