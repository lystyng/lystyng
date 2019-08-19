use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use lib 'lib';
use Lystyng;

my $app = Lystyng->to_app;
my $test = Plack::Test->create($app);

my $res = $test->request( GET '/' );

is( $res->code, 200, '[GET /] Request successful' )
  or diag 'HTTP error: ' . $res->status_line;

done_testing;
