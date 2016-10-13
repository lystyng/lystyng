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

prefix '/user' => sub {
  get '' => sub {
    my @users = resultset('User')->all;
    template 'users', {
      users => \@users,
    };
  };

  get '/:username' => sub {
    my $user = resultset('User')->find({
      username => route_parameters->get('username'),
    }, {
      prefetch => 'lists'
    });

    send_error 'User not found', 404 unless $user;

    template 'user', {
      user => $user,
    };
  };

  get '/:username/list/:list' => sub {
    my $user = resultset('User')->find({
      username => route_parameters->get('username'),
    });

    send_error 'User not found', 404 unless $user;

    my $list = $user->lists->find({
      slug => route_parameters->get('list'),
    });

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

    $user->add_to_lists($list_data);

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
  my $user_rs = resultset('User');
  my ($user) = $user_rs->find({ username => $user_data->{username} });
  if ($user) {
    push @errors, "Username '$user_data->{username}' is already in use.";
  };

  if (@errors) {
    return template 'register', {
      errors => \@errors,
    };
  }

  delete $user_data->{password2};
  $user = $user_rs->create( $user_data );

  session user => $user;

  redirect uri_for('/user/' . $user->username);
};

get '/login' => sub {
  template 'login';
};

post '/login' => sub {
  my $user_rs = resultset('User');
  my ($user) = $user_rs->find({ username => body_parameters->get('username') });
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

1;
