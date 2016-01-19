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

my $hal_app = Plack::App::File->new(
  root => Alien::Web::HalBrowser->dir
)->to_app;

$ENV{WEBAPI_DBIC_HTTP_AUTH_TYPE} //= 'none';

my $schema = Lystyng::Schema->get_schema;

my $app = WebAPI::DBIC::WebApp->new({
    routes => [ map( $schema->source($_), $schema->sources) ]
})->to_psgi_app;

my $app_prefix = "/webapi-dbic";

builder {
    enable "SimpleLogger";  # show on STDERR

    mount "$app_prefix/" => builder {
        mount "/browser" => $hal_app;
        mount "/" => $app;
    };

    # root redirect for discovery - redirect to API
    mount "/" => sub { [ 302, [ Location => "$app_prefix/" ], [ ] ] };
};
