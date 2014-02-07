package WebService::Microsoft::Translator;
use strict;
use warnings;
use Carp;
use LWP::UserAgent;
use URI;
use URI::QueryParam;
use XML::Simple;

use WebService::Microsoft::Translator::AccessToken;

use base qw(Class::Accessor::Fast);

our $VERSION = '0.01';

__PACKAGE__->mk_accessors(qw(
    access_token
    ua
    xml
));
__PACKAGE__->mk_ro_accessors(qw(
    client_id
    client_secret
    base_url
    response
));

sub new {
    my ($class, %args) = @_;

    $args{base_url} = 'http://api.microsofttranslator.com/v2/Http.svc/';
    $args{ua} ||= LWP::UserAgent->new(
        env_proxy => 1,
        timeout   => 30,
    );
    $args{xml} = XML::Simple->new;
    return $class->SUPER::new(\%args);
}

sub request_access_token {
    my $self = shift;

    my $token = WebService::Microsoft::Translator::AccessToken->new(
        client_id     => $self->client_id,
        client_secret => $self->client_secret,
        ua            => $self->ua,
    )->request;
    $self->access_token($token->access_token);
    return $token;
}

sub get_languages_for_translate {
    my $self = shift;
    my $api_url = $self->_api_url('GetLanguagesForTranslate');
    $self->_get($api_url, ForceArray => ['string']);
}

sub translate {
    my ($self, %args) = @_;
    my $text = $args{text};
    my $from = $args{from};
    my $to   = $args{to};
    my $content_type = $args{contentType} || 'text/plain';
    my $category     = $args{category};

    if (!defined $text || !$to) {
        Carp::croak('text and to are required');
    }

    my $api_url = $self->_api_url('Translate');
    $api_url->query_param(text => $text);
    $api_url->query_param(from => $from) if $from;
    $api_url->query_param(to   => $to);
    $api_url->query_param(contentType => $content_type);
    $api_url->query_param(category    => $category) if $category;

    $self->_get($api_url);
}

sub translate_array {
    my ($self, %args) = @_;

    if (!$args{Texts} || !$args{To}) {
        Carp::croak('Texts and To are required');
    }
    if (ref $args{Texts} ne 'ARRAY') {
        Carp::croak('Texts parameter is expecting a ARRAYREF');
    }
    if ($args{Options} && ref $args{Options} ne 'HASH') {
        Carp::croak('Options parameter is expecting a HASHREF');
    }

    my $api_url = $self->_api_url('TranslateArray');
    my $body = $self->_translate_array_body(%args);

    $self->_post($api_url, $body, ForceArray => ['TranslateArrayResponse']);
}

sub _translate_array_body {
    my ($self, %args) = @_;

    my $body = +{
        AppId   => [ +{ '-' => '', } ],
        To      => [ +{ content => $args{To}, } ],
        Texts   => $self->_translate_array_body_texts($args{Texts}),
        From    => $self->_translate_array_body_from($args{From}),
        Options => $self->_translate_array_body_options($args{Options}),
    };
    return XMLout($body, RootName => 'TranslateArrayRequest');
}

sub _translate_array_body_from {
    my ($self, $from) = @_;

    return [ +{ content => $from, } ] if defined $from;
    return [ +{ '-' => '', } ];
}

sub _translate_array_body_texts {
    my ($self, $texts) = @_;
    my $xmlns = 'http://schemas.microsoft.com/2003/10/Serialization/Arrays';

    my @list = map { +{ xmlns => $xmlns, content => $_, } } @$texts;
    return +{ string => \@list };
}

sub _translate_array_body_options {
    my ($self, $options) = @_;
    my $xmlns = 'http://schemas.datacontract.org/2004/07/Microsoft.MT.Web.Service.V2';

    my %op = (ReservedFlags => [ +{ xmlns => $xmlns, } ]);
    for my $key (qw(Category ContentType Uri User State)) {
        if (exists $options->{$key}) {
            $op{$key} = [ +{ xmlns => $xmlns, content => $options->{$key}, } ];
        } else {
            $op{$key} = [ +{ xmlns => $xmlns, } ];
        }
    }
    return \%op;
}

sub _authorization {
    return 'Bearer ' . shift->access_token;
}

sub _api_url {
    my ($self, $api_name) = @_;
    return URI->new($self->base_url . $api_name);
}

sub _get {
    my ($self, $url, %opt) = @_;

    my $response = $self->{response} = $self->ua->get($url, Authorization => $self->_authorization);
    if (!$response->is_success) {
        Carp::croak("request to $url failed.");
    }

    return $self->xml->XMLin($response->content, %opt);
}

sub _post {
    my ($self, $url, $body, %opt) = @_;

    my $response = $self->{response} = $self->ua->post(
        $url,
        content_type  => 'text/xml',
        Authorization => $self->_authorization,
        Content       => $body
    );
    if (!$response->is_success) {
        Carp::croak("request to $url failed.");
    }

    return $self->xml->XMLin($response->content, %opt);
}

1;
__END__

=head1 NAME

WebService::Microsoft::Translator - Microsoft Translator API with Perl

=head1 SYNOPSIS

  use WebService::Microsoft::Translator;

=head1 DESCRIPTION

WebService::Microsoft::Translator is

=head1 AUTHOR

Ryoji Tanida E<lt>ryo2.amari3@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
