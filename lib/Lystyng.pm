=head1 NAME

Lystyng - Code for listing things

=cut

package Lystyng;

use Dancer2;
our $VERSION = '0.0.1';
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Plugin::Passphrase;
use Lystyng::Model;
use LystyngAPI::Client;
use URI;

my $model = Lystyng::Model->new;
my $api = LystyngAPI::Client->new;

hook before => sub {
  if (my $username = session('user')) {
    var user => $api->get("/users/$username");
  }
};

get '/' => sub {
  template 'index';
};

get '/register' => sub {
  template 'register';
};

post '/register' => sub {
  my ($user_data, @errors);

  foreach (qw[username name email password password2]) {
    if (defined (my $val = body_parameters->get($_))) {
      $user_data->{$_} = $val;
    } else {
      push @errors, qq[Field "$_" is missing];
    }
  }

  my $resp = $api->post('/users', $user_data);

  if ($resp->{status} == 403) {
    return template 'register', { errors => $resp->{message} };
  }

  session user => $resp->{user};

  redirect uri_for('/users/' . $resp->{user});
};

get '/login' => sub {
  template 'login';
};

post '/login' => sub {
  my $resp = $api->post(
    '/login', {
      username => body_parameters->get('username'),
      password => body_parameters->get('password'),
    },
  );

  if ($resp->{code} == 200) {
    session user => $resp->{user};
    redirect uri_for('/users/' . $resp->{user});
  } else {
    template 'login', {
      error    => 1,
    };
  }
};

prefix '/users' => sub {
  get '' => sub {
    my @users = map { $_->json_data } $model->get_all_users;

    return \@users;
  };

  get '/:username' => sub {
    my $resp = $api->get('/users/' . route_parameters->get('username'));

    template 'user', { user => $resp };
  };

  post '/:username/lists' => sub {
    my $username = route_parameters->get('username');

    my $user = $model->get_user_by_username($username);

    send_error 'User not found', 404 unless $user;

    my $list_data;
    $list_data->{$_} = body_parameters->get($_)
      for (qw[title slug description]);

    # Check for existing list with that slug
    my $old_list =  $model->get_user_list_by_slug($user, $list_data->{slug});

    send_error 'List already exists' if $old_list;

    $model->add_user_list($user, $list_data);

    return {
      status => '201',
      message => 'List created successfully',
    };
  };

  get '/:username/lists/:list' => sub {
    my $username = route_parameters->get('username');
    my $listslug = route_parameters->get('list');

    my $resp = $api->get("/users/$username/lists/$listslug");

    if ($resp->{status} == 200) {
      $resp->{username} = $username;
      template 'list', $resp;
    } else {
      die $resp->{message};
    }
  };

  post '/:username/lists/:list/items' => sub {
    my $username = route_parameters->get('username');
    my $listslug = route_parameters->get('list');

    my $user = $model->get_user_by_username($username);

    send_error 'User not found', 404 unless $user;

    my $list = $model->get_user_list_by_slug($user, $listslug);

    send_error 'List not found', 404 unless $list;

    my %data = (
      seq => 'seq_no',
      title => 'title',
      url => 'url',
      desc => 'description',
    );

    my @params;
    for (body_parameters->keys) {
      for my $item (keys %data) {
        /^${item}_(\d+)/ and $params[$1]{$data{$item}} = body_parameters->get($_);
      }
    }

    for (@params) {
      next unless defined;
      next unless length $_->{title};

      my $resp = $api->post(request->path, $_);
    }

    redirect "/users/$username/lists/$listslug";
  };

  get '/:username/lists/:list/items/:seq_no/delete' => sub {
    my $username = route_parameters->get('username');
    my $listslug = route_parameters->get('list');
    my $seq      = route_parameters->get('seq_no');

    my $user = $model->get_user_by_username($username);

    send_error 'User not found', 404 unless $user;

    my $list = $model->get_user_list_by_slug($user, $listslug);

    send_error 'List not found', 404 unless $list;

    my $item = $list->list_items->find({ seq_no => $seq });

    send_error 'List item not found', 404 unless $item;

    $api->delete("/users/$username/lists/$listslug/items/$seq");

    redirect "/users/$username/lists/$listslug";
  };

  patch '/:username/lists/:list' => sub {
    my $username = route_parameters->get('username');
    my $listslug = route_parameters->get('list');

    my $user = $model->get_user_by_username($username);

    send_error 'User not found', 404 unless $user;

    my $list = $model->get_user_list_by_slug($user, $listslug);

    send_error 'List not found', 404 unless $list;

    my $new_list_values;
    for (qw[ title description slug ]) {
      my $value = body_parameters->get($_);
      $new_list_values->{$_} = $value if defined $value;
    }

    if (keys %$new_list_values) {
use Data::Dumper;
warn Dumper $new_list_values;
      $list->update($new_list_values);
      return {
        status => 200,
        message => 'List updated successfully',
      };
    }
  };

  patch '/:username/lists/:list/items/:seq_no' => sub {
    my $username = route_parameters->get('username');
    my $listslug = route_parameters->get('list');
    my $seq      = route_parameters->get('seq_no');

    my $user = $model->get_user_by_username($username);

    send_error 'User not found', 404 unless $user;

    my $list = $model->get_user_list_by_slug($user, $listslug);

    send_error 'List not found', 404 unless $list;

    my $item = $list->list_items->find({ seq_no => $seq });

    send_error 'List item not found', 404 unless $item;

    my $new_item_values;
    for (qw[ title description seq_no ]) {
      my $value = body_parameters->get($_);
      $new_item_values->{$_} = $value if defined $value;
    }

    if (keys %$new_item_values) {
      $item->update($new_item_values);
      return {
        status => 200,
        message => 'List item updated successfully',
      };
    }
  };

  del '/:username/lists/:list' => sub {
    my $username = route_parameters->get('username');
    my $listslug = route_parameters->get('list');

    my $user = $model->get_user_by_username($username);

    send_error 'User not found', 404 unless $user;

    my $list = $model->get_user_list_by_slug($user, $listslug);

    send_error 'List not found', 404 unless $list;

    $list->list_items->delete;
    $list->delete;

    return {
      status => 200,
      message => 'List deleted successfully',
    };
  };
};

prefix '/list' => sub {
  get '/add' => needs login => sub {
    template 'addlist';
  };

  post '/add' => sub {
    my $resp = $api->post(
      '/users/' . session('user') . '/lists', {
        title => body_parameters->get('list_title'),
        slug  => body_parameters->get('list_slug'),
        description => body_parameters->get('list_description'),
      },
    );

    if ($resp->{status} == 403) {
      template 'addlist', { error => $resp->{message}};
    } else {
      redirect uri_for($resp->{list});
    }
  };
};

get '/verify/:code' => sub {
  my $code = route_parameters->get('code');
  my $user = $model->get_user_by_attribute(
    verify => $code,
  );

  send_error 'That verification code is invalid', 404
    unless $user;

  $model->verify_user($user);

  return {
    status => 200,
    message => 'User verified successfully',
  };
};

get '/logout' => sub {
  session user => undef;
  redirect request->referer;
};

get '/password' => sub {
  template 'forgotpass';
};

post '/password' => sub {
  unless (body_parameters->{email}) {
    send_error 'Email address missing', 400;
  }

  my $email = lc params->{email};
  my $user = $model->get_user_by_email($email);
  unless ($user) {
    send_error "$email is not a registered email address", 400;
  }

  my $pass_code = passphrase->generate_random({
    length  => 32,
    charset => [ 'a' .. 'z', '0' .. '9' ],
  });

  $model->add_password_reset($user, $pass_code);
  $user->send_forgot_password(uri_for('/passreset'), $pass_code);

  return {
    status => 200,
    message => 'Password reset code sent to user',
  };
};

get '/passreset/:code' => sub {
  my $code = route_parameters->get('code');
  my $ps = $model->get_passreset_from_code($code);

  warn "In GET /passreset/:code";

  unless ($ps) {
    warn "Can't find a code";
    send_error "Code '$code' is not recognised. Please try again", 404;
  }

  warn "Got a code";

  return {
    status => 200,
    code => $code,
  }
};

post '/passreset' => sub {
  my $code = body_parameters->{'code'};

  unless ($code) {
    send_error 'Reset code missing', 400;
  }

  my $ps = $model->get_passreset_from_code($code);
  unless ($ps) {
    send_error "Code $code is no longer valid", 400;
  }

  my ($pass1, $pass2) = (
    body_parameters->get('password'), body_parameters->get('password2')
  );

  unless ($pass1 and $pass2) {
    send_error 'Must fill in both password fields', 400;
  }
  unless ($pass1 eq $pass2) {
    send_error 'Password values are not the same', 400;
  }

  $model->update_user_password(
    $ps->user, $pass1,
  );

  $model->clear_passreset($ps);

  return {
    status => 200,
    message => 'Password reset successfully',
  };
};

1;
