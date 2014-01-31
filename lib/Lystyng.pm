=head1 NAME

Lystyng - Code for listing things

=cut

package Lystyng;

use Dancer ':syntax';
our $VERSION = '0.0.1';

get '/' => sub {
    template 'index';
};

true;

