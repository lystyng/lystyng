use utf8;
package Lystyng::Schema::Result::List;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Lystyng::Schema::Result::List

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<list>

=cut

__PACKAGE__->table("list");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 200

=head2 slug

  data_type: 'varchar'
  is_nullable: 0
  size: 200

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 is_todo

  data_type: 'tinyint'
  is_nullable: 1

=head2 privacy

  data_type: 'enum'
  extra: {list => ["private","friends","public"]}
  is_nullable: 1

=head2 user

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "slug",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "is_todo",
  { data_type => "tinyint", is_nullable => 1 },
  "privacy",
  {
    data_type => "enum",
    extra => { list => ["private", "friends", "public"] },
    is_nullable => 1,
  },
  "user",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 list_items

Type: has_many

Related object: L<Lystyng::Schema::Result::ListItem>

=cut

__PACKAGE__->has_many(
  "list_items",
  "Lystyng::Schema::Result::ListItem",
  { "foreign.list" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 list_tags

Type: has_many

Related object: L<Lystyng::Schema::Result::ListTag>

=cut

__PACKAGE__->has_many(
  "list_tags",
  "Lystyng::Schema::Result::ListTag",
  { "foreign.list" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user

Type: belongs_to

Related object: L<Lystyng::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "Lystyng::Schema::Result::User",
  { id => "user" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-08-06 09:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lG+2JCixiWj5hv1Z2u1ilw

sub json_data {
  my $self = shift;
  my ($include) = @_;

  my $data = {
    title => $self->title,
    slug => $self->slug,
    url => $self->url,
  };

  if ($include->{items}) {
    $data->{items} = [
      map { $_->json_data } $self->list_items,
    ];
  }

use Data::Dumper;
warn Dumper $data;

  return $data;
}

sub url {
  my $self = shift;

  return $self->user->url . '/list/' . $self->slug;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
