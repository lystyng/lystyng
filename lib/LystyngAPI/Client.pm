package LystyngAPI::Client;

use Moose;
use URI;
use LWP::UserAgent;
use JSON;

has api_uri => (
  isa => 'URI',
  is => 'ro',
  lazy_build => 1,
);

sub _build_api_uri {
  my $api_str = sprintf(
    "%s://%s:%d",
    ($ENV{LYSTYNG_API_HTTP} // 'https'),
    ($ENV{LYSTYNG_API_HOST} // 'localhost'),
    ($ENV{LYSTYNG_API_PORT} // 80),
  );

  return URI->new($api_str);
}

has ua => (
  isa => 'LWP::UserAgent',
  is => 'ro',
  lazy_build => 1,
);

sub _build_ua {
  return LWP::UserAgent->new;
}

has json => (
  isa => 'JSON',
  is => 'ro',
  lazy_build => 1,
);

sub _build_json {
  return JSON->new;
}

sub get {
  my $self = shift;
  my ($path) = @_;

  my $resp = $self->ua->get($self->api_uri . $path);

  return $self->json->decode($resp->content);
}

sub post {
  my $self = shift;
  my ($path, $args) = @_;

  my $content = $self->json->encode($args);

  my $resp =  $self->ua->post($self->api_uri . $path, Content => $content);

  return $self->json->decode($resp->content);
}

1;
