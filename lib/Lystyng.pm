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
    template 'users', {
      users => [ $model->get_all_users ],
    };
  };

  get '/:username' => sub {
    my $user = $model->get_user_by_username(
      route_parameters->get('username')
    );

    send_error 'User not found', 404 unless $user;

    template 'user', {
      user => $user,
    };
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

    template 'list', {
      list => $list,
    };
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

  foreach (qw[username name email password password2]) {
    if (defined (my $val = body_parameters->get($_))) {
      $user_data->{$_} = $val;
    } else {
      push @errors, qq[Field "$_" is missing];
    }
  }

  if (@errors) {
    return template 'register', {
      errors => \@errors,
    };
  }

  if ($user_data->{password} ne $user_data->{password2}) {
    push @errors, 'Your passwords do not match.';
  }

  my ($user) = $model->get_user_by_username($user_data->{username});
  if ($user) {
    push @errors, "Username '$user_data->{username}' is already in use.";
  };

  ($user) = $model->get_user_by_email($user_data->{email});
  if ($user) {
    push @errors, "Email address '$user_data->{email}' is already registered.";
  }

  if (@errors) {
    return template 'register', {
      errors => \@errors,
    };
  }

  delete $user_data->{password2};
  $user_data->{verify} = passphrase->generate_random({
    length  => 32,
    charset => [ 'a' .. 'z', 'A' .. 'Z', 0 .. 9],
  });

  $user = $model->add_user( $user_data );

  $user->send_verify(uri_for('/verify'));

  session user => $user;

  redirect uri_for('/user/' . $user->username);
};

get '/verify/:code' => sub {
  my $code = route_parameters->get('code');
  my $user = $model->get_user_by_attribute(
    verify => $code,
  );

  unless ($user) {
    return 'That verification code is invalid';
  }

  $user->update({ verify => undef });

  redirect uri_for('/user/' . $user->username);
};

get '/login' => sub {
  template 'login';
};

post '/login' => sub {
  my ($user) = $model->get_user_by_username(body_parameters->get('username'));
  if ($user && $user->check_password(body_parameters->get('password'))) {
    session user => $user;
    redirect uri_for('/user/' . $user->username);
  } else {
    template 'login', {
      error    => 1,
    };
  }
};

get '/logout' => sub {
  session user => undef;
  redirect uri_for('/');
};

get '/password' => sub {
  template 'forgotpass';
};

post '/password' => sub {
  unless (params->{email}) {
    session 'error' => 'You must give an email address';
    return redirect '/password';
  }

  my $email = lc params->{email};
  my $user = $model->get_user_by_email($email);
  unless ($user) {
    session 'error' => "$email is not a registered email address";
    return redirect '/forgotpass';
  }

  my $pass_code = passphrase->generate_random({
    length  => 32,
    charset => [ 'a' .. 'z', '0' .. '9' ],
  });

  $user->add_to_password_resets({
    code => $pass_code,
  });

  $user->send_forgot_password(uri_for('/passreset'), $pass_code);

  template 'pass_sent', { user => $user };
};

get '/passreset/:code' => sub {
  my $code = route_parameters->get('code');
  my $ps = $model->get_passreset_from_code($code);

  warn "In GET /passreset/:code";

  unless ($ps) {
    warn "Can't find a code";
    session error => "Code '$code' is not recognised. Please try again";
    return redirect '/password';
  }

  warn "Got a code";

  session error => '';
  session code => $code;
  template 'passreset';
};

post '/passreset' => sub {
  my $code = session('code');

  unless ($code) {
    session error => 'Something went wrong';
    redirect '/password';
  }

  my $ps = $model->get_passreset_from_code($code);
  unless ($ps) {
    session error => "Code '$code' is not recognised. Please try again";
    redirect '/password';
  }

  session error => '';

  my ($pass1, $pass2) = (
    body_parameters->get('password'), body_parameters->get('password2')
  );

  unless ($pass1 and $pass2) {
    session error => 'You must fill in both passwords';
  }
  unless ($pass1 eq $pass2) {
    session error => 'Password values are not the same';
  }

  if (session('error')) {
    return template 'passreset';
  }

  $model->update_user_password(
    $ps->user, $pass1,
  );

  $model->clear_passreset($ps);

  template 'passdone';
};

1;
