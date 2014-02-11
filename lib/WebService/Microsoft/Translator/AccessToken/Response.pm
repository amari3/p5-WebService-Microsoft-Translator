package WebService::Microsoft::Translator::AccessToken::Response;
use strict;
use warnings;
use Carp;

use Class::Accessor::Lite (
    new => 0,
    ro => [ qw(access_token token_type expires_in scope) ],
);

sub new {
    my ($class, $token) = @_;

    if (!defined $token) {
        Carp::croak('token is required');
    }
    return bless $token, $class;
}

1;
