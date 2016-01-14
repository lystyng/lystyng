=head1 NAME

Lystyng - Code for listing things

=cut

package Lystyng;

use Dancer2;
our $VERSION = '0.0.1';
use Dancer2::Plugin::DBIC qw[schema resultset];

defined $ENV{LYSTYNG_DB_USER} && defined $ENV{LYSTYNG_DB_PASS}
  or die 'Must set LYSTYNG_DB_USER and LYSTYNG_DB_PASS';

hook before => sub {
  my $cfg = dancer_app->config;
  $cfg->{plugins}{DBIC}{default}{user}     = $ENV{LYSTYNG_DB_USER};
  $cfg->{plugins}{DBIC}{default}{password} = $ENV{LYSTYNG_DB_PASS};
};

get '/' => sub {
  template 'index';
};

get '/user' => sub {
  my @users = resultset('User')->all;
  template 'users', {
    users => \@users,
  };
};

get '/user/:username' => sub {
  if (my $user = resultset('User')->find({
    username => params->{username},
  }, {
    prefetch => 'lists'
  })) {
    template 'user', {
      user => $user,
    };
  } else {
    send_error 'User not found', 404;
  }
};

get '/user/:username/list/add' => sub {
  redirect '/login' unless session->{user};

  template 'addlist';
};

post '/user/:username/list/add' => sub {
  redirect '/login' unless session->{user};

  session->{user}->add_to_lists({
    title       => params->{list_title},
    slug        => params->{list_slug},
    description => params->{list_description},
  });

  redirect '/user/' . session->{user}->username;
};

get '/user/:username/list/:list' => sub {
  my $user;
  unless ($user = resultset('User')->find({
    username => params->{username},
  })) {
    send_error 'User not found', 404;
  };

  if (my $list = $user->lists->find({
    slug => params->{list},
  })) {
    template 'list', {
      list => $list,
    };
  } else {
    send_error 'List not found', 404;
  };
};

get '/register' => sub {
  template 'register';
};

post '/register' => sub {
  my @errors;

  foreach (qw[username name email password password2]) {
    push @errors, qq[Field "$_" is missing] unless defined param($_);
  }

  if (@errors) {
    return template 'register', {
      errors => \@errors,
    };
  }

  if (param('password') ne param('password2')) {
    push @errors, 'Your passwords do not match.';
  }
  my $user_rs = resultset('User');
  my ($user) = $user_rs->find({ username => param('username') });
  if ($user) {
    push @errors, 'Username ' . $user->username . ' is already in use.';
  };

  if (@errors) {
    template 'register', {
      errors => \@errors,
    };
  } else {
    $user = $user_rs->create({
      username => param('username'),
      name     => param('name'),
      email    => param('email'),
      password => param('password'),
    });

    session user => $user;

    redirect '/user/' . $user->username;
  }
};

get '/login' => sub {
  template 'login';
};

post '/login' => sub {
  my $user_rs = resultset('User');
  my ($user) = $user_rs->find({ username => param('username') });
  if ($user && $user->check_password(param('password'))) {
    session user => $user;
    redirect '/user/' . $user->username;
  } else {
    template 'login', {
      error    => 1,
    };
  }
};

get '/logout' => sub {
  session user => undef;
  redirect '/';
};

true;
