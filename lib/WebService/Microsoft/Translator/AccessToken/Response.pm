package WebService::Microsoft::Translator::AccessToken::Response;
use strict;
use warnings;
use Carp;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors(qw(
    access_token
    token_type
    expires_in
    scope
));

sub new {
    my ($class, $token) = @_;

    if (!defined $token) {
        Carp::croak('token is required');
    }

    return $class->SUPER::new($token);
}

1;
