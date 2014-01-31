=head1 NAME

Lystyng - Code for listing things

=cut

package Lystyng;

use Dancer ':syntax';
our $VERSION = '0.0.1';
use Dancer::Plugin::DBIC qw[schema resultset];

defined $ENV{LYSTYNG_DB_USER} && defined $ENV{LYSTYNG_DB_PASS}
  or die 'Must set LYSTYNG_DB_USER and LYSTYNG_DB_PASS';

my $cfg = setting('plugins');
$cfg->{DBIC}{default}{user} = $ENV{LYSTYNG_DB_USER};
$cfg->{DBIC}{default}{pass} = $ENV{LYSTYNG_DB_PASS};


get '/' => sub {
  template 'index';
};

get '/register' => sub {
  template 'register';
};

post '/register' => sub {
  my $user_rs = resultset('User');
  my @errors;
  if (param('password') ne param('password2')) {
    push @errors, 'Your passwords do not match.';
  }
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

    redirect '/';
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
    redirect '/';
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

