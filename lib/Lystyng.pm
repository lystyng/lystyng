=head1 NAME

Lystyng - Code for listing things

=cut

package Lystyng;

use Dancer2;
our $VERSION = '0.0.1';
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Plugin::Passphrase;
use Lystyng::Model;

my $model = Lystyng::Model->new;

get '/' => sub {
  template 'index';
};

prefix '/user' => sub {
  get '' => sub {
    my @users = map { $_->json_data } $model->get_all_users;
    
    return \@users; 
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

  get '/:username/list/:list' => sub {
    my $user = $model->get_user_by_username(
      route_parameters->get('username'),
    );

    send_error 'User not found', 404 unless $user;

    my $list = $model->get_user_list_by_slug(
      $user, route_parameters->get('list'),
    );

    send_error 'List not found', 404 unless $list;

    return $list->json_data;
  };
};

prefix '/list' => sub {
  get '/add' => needs login => sub {
    template 'addlist';
  };

  post '/add' => needs login => sub {
    my $user = session('user');
    my $list_data;
    $list_data->{$_} = body_parameters->get("list_$_")
      for (qw[title slug description]);

    $model->add_user_list($user, $list_data);

    redirect uri_for('/user/' . $user->username .
                     '/list/' . $list_data->{slug});
  };
};

get '/register' => sub {
  template 'register';
};

post '/register' => sub {
  my ($user_data, @errors);

  my $input = body_parameters->mixed;

  foreach (qw[username name email password password2]) {
    if (defined (my $val = $input->{$_})) {
      $user_data->{$_} = $val;
    } else {
      push @errors, qq[Field "$_" is missing];
    }
  }

  if (@errors) {
    return {
      status => 401,
      message => 'Cannot create user',
      errors => \@errors,
    };
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
    return {
      status => 403,
      errors => \@errors,
    };
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
    message => "User '$user_data->{username}' created successfully",
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

get '/login' => sub {
  template 'login';
};

post '/login' => sub {
  my ($user) = $model->get_user_by_username(body_parameters->get('username'));
  if ($user && $user->check_password(body_parameters->get('password'))) {
    session user => $user;
    return {
      status => '200',
      message => 'User ' . $user->username . ' logged in successfully',
    };
  } else {
    send_error 'Login unsuccessful', 403;
  }
};

get '/logout' => sub {
  session user => undef;
  return { status => 200, message => 'User logged out' };
};

get '/password' => sub {
  template 'forgotpass';
};

post '/password' => sub {
  unless (body_parameters->{email}) {
    return {
      status => 400,
      message => 'email address missing',
    };
  }

  my $email = lc params->{email};
  my $user = $model->get_user_by_email($email);
  unless ($user) {
    return {
      status => 400,
      message => "$email is not a registered email address",
    }
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
    return {
      status => 400,
      message => 'Reset code missing',
    }
  }

  my $ps = $model->get_passreset_from_code($code);
  unless ($ps) {
    return {
      status => 400,
      message => "Code $code is no longer valid",
    };
  }

  my ($pass1, $pass2) = (
    body_parameters->get('password'), body_parameters->get('password2')
  );

  unless ($pass1 and $pass2) {
    return {
      status => 400,
      message => 'Must fill in both password fields',
    }
  }
  unless ($pass1 eq $pass2) {
    return {
      status => 400,
      message => 'Password values are not the same',
    };
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
