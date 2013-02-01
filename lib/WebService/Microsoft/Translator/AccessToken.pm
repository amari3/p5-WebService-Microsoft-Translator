package WebService::Microsoft::Translator::AccessToken;
use strict;
use warnings;
use Carp;
use JSON;

use WebService::Microsoft::Translator::AccessToken::Response;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
    ua
));
__PACKAGE__->mk_ro_accessors(qw(
    client_id
    client_secret
    scope
    grant_type
    authorize_url
));

sub new {
    my ($class, %args) = @_;

    if (!$args{client_id} || !$args{client_secret}) {
        Carp::croak('client_id and client_secret are required');
    }

    $args{scope}         = 'http://api.microsofttranslator.com';
    $args{grant_type}    = 'client_credentials';
    $args{authorize_url} = 'https://datamarket.accesscontrol.windows.net/v2/OAuth2-13';
    $args{ua} ||= LWP::UserAgent->new(
        env_proxy => 1,
        timeout   => 30,
    );

    return $class->SUPER::new(\%args);
}

sub request {
    my $self = shift;

    my $response = $self->ua->post($self->authorize_url, content => +{
        client_id     => $self->client_id,
        client_secret => $self->client_secret,
        scope         => $self->scope,
        grant_type    => $self->grant_type,
    });

    if (!$response->is_success) {
        Carp::croak('Could not fetch access token: ' . $response->status_line);
    }

    my $token = decode_json($response->content);
    return WebService::Microsoft::Translator::AccessToken::Response->new($token);
}

1;
