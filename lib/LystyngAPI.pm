=head1 NAME

Lystyng API - Code for listing things

=cut

package LystyngAPI;

use Dancer2;
our $VERSION = '0.0.1';
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Plugin::Passphrase;
use Lystyng::Model;

my $model = Lystyng::Model->new;

set serializer => 'JSON';

prefix '/users' => sub {
  get '' => sub {
    my @users = map { $_->json_data } $model->get_all_users;

    return \@users;
  };

  post '' => sub {
    my ($user_data, @errors);

    foreach (qw[username name email password password2]) {
      if (defined (my $val = body_parameters->get($_))) {
        $user_data->{$_} = $val;
      } else {
        push @errors, qq[Field "$_" is missing];
      }
    }

    if (@errors) {
      send_error 'Cannot create user (' . join(', ', @errors) . ')', 401;
    }

    # It's only worth checking this stuff if we have a valid set of data
    if (!@errors) {
      if ($user_data->{password} ne $user_data->{password2}) {
        push @errors, 'Your passwords do not match.';
      }

      my ($old_user) = $model->get_user_by_username($user_data->{username});
      if ($old_user) {
        push @errors, "Username '$user_data->{username}' is already in use.";
      };

      ($old_user) = $model->get_user_by_email($user_data->{email});
      if ($old_user) {
        push @errors, "Email address '$user_data->{email}' is already registered.";
      }
    }

    if (@errors) {
      send_error 'Cannot create user (' . join(', ', @errors) . ')', 403;
    }

    delete $user_data->{password2};
    $user_data->{verify} = passphrase->generate_random({
      length  => 32,
      charset => [ 'a' .. 'z', 'A' .. 'Z', 0 .. 9],
    });

    my $user = $model->add_user( $user_data );

    $user->send_verify(uri_for('/verify'));

    session user => $user;

    return {
      status => 201,
      user   => $user_data->{username},
    };
  };

  get '/:username' => sub {
    my $user = $model->get_user_by_username(
      route_parameters->get('username')
    );

    send_error 'User not found', 404 unless $user;

    my $data = $user->json_data;
    $data->{lists} = [ map { $_->json_data } $model->get_users_lists($user) ];

    return $data;
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
      list    => "/users/$username/lists/$list_data->{slug}",
    };
  };

  get '/:username/lists/:list' => sub {
    my $username = route_parameters->get('username');
    my $listslug = route_parameters->get('list');

    my $user = $model->get_user_by_username($username);

    send_error 'User not found', 404 unless $user;

    my $list = $model->get_user_list_by_slug($user, $listslug);

    send_error 'List not found', 404 unless $list;

    return {
      status => 200,
      list => $list->json_data({ items => 1 }),
    };
  };

  post '/:username/lists/:list/items' => sub {
    my $username = route_parameters->get('username');
    my $listslug = route_parameters->get('list');

    my $user = $model->get_user_by_username($username);

    send_error 'User not found', 404 unless $user;

    my $list = $model->get_user_list_by_slug($user, $listslug);

    send_error 'List not found', 404 unless $list;

    my $item = { map {
      $_ => body_parameters->get($_);
    } (qw[ seq_no title description ]) };

    if (!$item->{seq_no}) {
      if ($list->list_items->count) {
        my $max = $list->list_items->get_column('seq_no')->max;
        $item->{seq_no} = ++$max;
      } else {
        $item->{seq_no} = 1;
      }
    }

    $model->add_item_to_user_list($username, $listslug, $item);

    return {
      status => 201,
      message => 'List item created successfully',
    };
  };

  del '/:username/lists/:list/items/:seq_no' => sub {
    my $username = route_parameters->get('username');
    my $listslug = route_parameters->get('list');
    my $seq      = route_parameters->get('seq_no');

    my $user = $model->get_user_by_username($username);

    send_error 'User not found', 404 unless $user;

    my $list = $model->get_user_list_by_slug($user, $listslug);

    send_error 'List not found', 404 unless $list;

    my $item = $list->list_items->find({ seq_no => $seq });

    send_error 'List item not found', 404 unless $item;

    $item->delete;

    return {
      status => 200,
      message => 'List item deleted successfully',
    };
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

post '/login' => sub {
  my ($user) = $model->get_user_by_username(body_parameters->get('username'));
  if ($user && $user->check_password(body_parameters->get('password'))) {
    session user => $user;
    return {
      code => 200,
      user => $user->username,
    };
  } else {
    warn "Login unsuccessful";
    send_error 'Login unsuccessful', 403;
  }
};

get '/logout' => sub {
  session user => undef;
  return { status => 200, message => 'User logged out' };
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
