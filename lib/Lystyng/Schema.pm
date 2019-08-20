use utf8;
package Lystyng::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-01-07 22:12:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OLU/hcQP/QDNuNZnm+Il/g


# You can replace this text with custom code or comments, and it will be preserved on regeneration

use Carp;

sub check_env {
  my @errors;
  foreach (qw[LYSTYNG_DB_HOST LYSTYNG_DB_NAME
              LYSTYNG_DB_USER LYSTYNG_DB_PASS]) {
    push @errors, $_ unless defined $ENV{$_};
  }

  if (@errors) {
    croak("Missing connection info: @errors");
  }
}

sub get_schema {
  __PACKAGE__->check_env();

  return __PACKAGE__->connect(
    "dbi:mysql:hostname=$ENV{LYSTYNG_DB_HOST};database=$ENV{LYSTYNG_DB_NAME}",
    $ENV{LYSTYNG_DB_USER}, $ENV{LYSTYNG_DB_PASS}
  );
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
