use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use JSON;

use lib 'lib';
use Lystyng;
use Lystyng::Schema;

my $app = Lystyng->to_app;
my $test = Plack::Test->create($app);

my $sch = eval { Lystyng::Schema->get_schema };
BAIL_OUT($@) if $@;

my $test_user_data = {
  username  => 'test',
  name      => 'Test User',
  email     => 'test@example.com',
  password  => 'TEST',
  password2 => 'TEST',
};

# Ensure test user doesn't exist
my $test_user = $sch->resultset('User')->find({
  username => $test_user_data->{username},
});
$test_user->delete if $test_user;

my $res = $test->request(POST '/register', 
  Content_type => 'application/json',
  Content => encode_json($test_user_data),
);

my $user = $sch->resultset('User')->find({
  username => $test_user_data->{username},
});

$res = $test->request(POST "/users/$test_user_data->{username}/list/add",
  Content_type => 'application/json',
  Content => encode_json({
    title       => 'Test List',
    slug        => 'test_list',
    description => 'A test list',
  }),
);

ok($res, 'Got a response from adding a list');
is($res->code, 200, 'Status is 200');

my $list = $user->lists->first;

my $url = "/users/$test_user_data->{username}/list/test_list/item";
$res = $test->request(POST $url,
  Content_type => 'application/json',
  Content => encode_json({
    seq_no      => 1,
    title       => 'Test List Item',
    description => 'A test list item',
  }),
);

ok($res, 'Got a response from adding a list item');
is($res->code, 200, 'Status is 200');

$res = $test->request(GET "/users/$test_user_data->{username}/list/test_list");

ok($res, 'Got a response from getting a list');
is($res->code, 200, 'Status is 200');

# Clean up after ourselves
$_->list_items->delete for $user->lists;
$user->lists->delete;
$user->delete;

done_testing;
