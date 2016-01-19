=head1 NAME

api.psgi - REST API for lystyng.com.

=head1 SYNOPSIS

    $ plackup api.psgi
    ... open a web browser on port 5000 to browse your new API

The API provided by this .psgi file will be read-only unless the
C<WEBAPI_DBIC_WRITABLE> env var is true.

For details on the C<WEBAPI_DBIC_HTTP_AUTH_TYPE> env var and security issues
see C<http_auth_type> in L<WebAPI::DBIC::Resource::Role::DBICAuth>.

=cut

use strict;
use warnings;

use Plack::Builder;
use Plack::App::File;
use WebAPI::DBIC::WebApp;
use Alien::Web::HalBrowser;

use FindBin '$Bin';
use lib "$Bin/../lib";
use Lystyng::Schema;

$ENV{WEBAPI_DBIC_HTTP_AUTH_TYPE} //= 'none';
$ENV{WEBAPI_DBIC_WRITABLE}       //= 0;

my $hal_app = Plack::App::File->new(
  root => Alien::Web::HalBrowser->dir
)->to_app;

my $schema = Lystyng::Schema->get_schema;

my $app = WebAPI::DBIC::WebApp->new({
    routes => [ map( $schema->source($_), $schema->sources) ]
})->to_psgi_app;

builder {
    enable "SimpleLogger";  # show on STDERR

    mount "/browser" => $hal_app;
    mount "/" => $app;
};
