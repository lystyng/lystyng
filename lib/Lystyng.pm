=head1 NAME

Lystyng - Code for listing things

=cut

package Lystyng;

use Dancer2;
our $VERSION = '0.0.1';
use Dancer2::Plugin::DBIC qw[schema resultset];
use Dancer2::Plugin::Auth::Tiny;
use Lystyng::Schema;

Lystyng::Schema->check_env();

hook before => sub {
  my $cfg = dancer_app->config;
  $cfg->{plugins}{DBIC}{default}{user}     = $ENV{LYSTYNG_DB_USER};
  $cfg->{plugins}{DBIC}{default}{password} = $ENV{LYSTYNG_DB_PASS};
  $cfg->{plugins}{DBIC}{default}{dsn}      =
    "dbi:mysql:dbname=$ENV{LYSTYNG_DB_NAME};hostname=$ENV{LYSTYNG_DB_SERVER}";
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
  my $user = resultset('User')->find({
    username => params->{username},
  }, {
    prefetch => 'lists'
  });

  send_error 'User not found', 404 unless $user;

  template 'user', {
    user => $user,
  };
};

get '/list/add' => needs login => sub {
  template 'addlist';
};

post '/list/add' => needs login => sub {
  my $user = session('user');
  my $list_data;
  $list_data->{$_} = params->{"list_$_"}
    for (qw[title slug description]);

  $user->add_to_lists($list_data);

  redirect '/user/' . $user->username .
           '/list/' . $list_data->{slug};
};

get '/user/:username/list/:list' => sub {
  my $user = resultset('User')->find({
    username => params->{username},
  });

  send_error 'User not found', 404 unless $user;

  my $list = $user->lists->find({
    slug => params->{list},
  });

  send_error 'List not found', 404 unless $list;

  template 'list', {
    list => $list,
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
    return template 'register', {
      errors => \@errors,
    };
  }

  $user = $user_rs->create({
    username => param('username'),
    name     => param('name'),
    email    => param('email'),
    password => param('password'),
  });

  session user => $user;

  redirect '/user/' . $user->username;
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

1;
