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

    $args{base_url} = 'http://api.microsofttranslator.com/V2/Http.svc/';
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

sub add_translation {
    my ($self, %args) = @_;
    my $original_text = $args{originalText};
    my $translated_text = $args{translatedText};
    my $from = $args{from};
    my $to = $args{to};
    my $rating = $args{rating};
    my $content_type = $args{contentType};
    my $category = $args{category};
    my $user = $args{user};
    my $uri = $args{uri};

    if (!defined $original_text || !defined $translated_text || !$from || !$to || !defined $user) {
        Carp::croak('originalText, translatedText, from, to and user are required');
    }

    my $api_url = $self->_api_url('AddTranslation');
    $api_url->query_param(originalText => $original_text);
    $api_url->query_param(translatedText => $translated_text);
    $api_url->query_param(from => $from);
    $api_url->query_param(to => $to);
    $api_url->query_param(rating => $rating) if defined $rating;
    $api_url->query_param(contentType => $content_type) if $content_type;
    $api_url->query_param(category => $category) if $category;
    $api_url->query_param(user => $user);
    $api_url->query_param(uri => $uri) if $uri;
    $self->_get($api_url);
    return 1;
}

sub add_translation_array {
    my ($self, %args) = @_;
    my $translations = $args{translations};
    my $from = $args{from};
    my $to = $args{to};
    my $options = $args{options};

    if (!$args{translations} || !$args{from} || !$args{to} || !$args{options}) {
        Carp::croak('translations, from, to and options are required');
    }
    if (ref $args{translations} ne 'ARRAY') {
        Carp::croak('translations parameter is expecting a ARRAYREF');
    }
    if (ref $args{options} ne 'HASH') {
        Carp::croak('options parameter is expecting a HASHREF');
    }

    my $api_url = $self->_api_url('AddTranslationArray');
    my $body = $self->_add_translation_array_body(%args);
    $self->_post($api_url, $body);
    return 1;
}

sub _add_translation_array_body {
    my ($self, %args) = @_;

    my $body = +{
        AppId        => [ +{ '-' => '', } ],
        To           => [ +{ content => $args{to}, } ],
        From         => $self->_array_body_from($args{from}),
        Translations => $self->_add_translation_array_body_translations($args{translations}),
        Options      => $self->_add_translation_array_body_options($args{options}),
    };
    return $self->xml->XMLout($body, RootName => 'AddtranslationsRequest');
}

sub _add_translation_array_body_translations {
    my ($self, $translations) = @_;
    my $xmlns = 'http://schemas.datacontract.org/2004/07/Microsoft.MT.Web.Service.V2';

    my @list = ();
    for my $translation (@$translations) {
        if (!exists $translation->{OriginalText} ||
            !exists $translation->{TranslatedText} ||
            !exists $translation->{Rating}) {
            Carp::croak('OriginalText, TranslatedText and Rating are required');
        }
        push @list, +{
            OriginalText   => [ +{ content => $translation->{OriginalText} } ],
            TranslatedText => [ +{ content => $translation->{TranlatedText} } ],
            Rating         => [ +{ content => $translation->{Rating} } ],
            Sequence       => [ +{ content => $translation->{Sequence} || 0 } ],
        };
    }
    return +{ Translation => \@list };
}

sub _add_translation_array_body_options {
    my ($self, $options) = @_;
    my $xmlns = 'http://schemas.datacontract.org/2004/07/Microsoft.MT.Web.Service.V2';

    if (!exists $options->{User}) {
        Carp::croak('options.User is required');
    }
    my %op = ();
    for my $key (qw(Category ContentType User Uri)) {
        if (exists $options->{$key}) {
            $op{$key} = [ +{ xmlns => $xmlns, content => $options->{$key}, } ];
        } else {
            $op{$key} = [ +{ xmlns => $xmlns, } ];
        }
    }
    return \%op;
}

sub break_sentences {
    my ($self, %args) = @_;
    my $text = $args{text};
    my $language = $args{language};

    if (!defined $text || !$language) {
        Carp::croak('text and language are required');
    }

    my $api_url = $self->_api_url('BreakSentences');
    $api_url->query_param(text => $text);
    $api_url->query_param(language => $language);
    $self->_get_and_parse($api_url, ForceArray => ['int']);
}

sub detect {
    my ($self, %args) = @_;
    my $text = $args{text};

    if (!defined $text) {
        Carp::croak('text is required');
    }

    my $api_url = $self->_api_url('Detect');
    $api_url->query_param(text => $text);
    $self->_get_and_parse($api_url);
}

sub detect_array {
    my ($self, %args) = @_;
    my $texts = $args{texts};

    if (!$texts) {
        Carp::croak('texts is required');
    }
    if (ref $texts ne 'ARRAY') {
        Carp::croak('texts parameter is expecting a ARRAYREF');
    }

    my $api_url = $self->_api_url('DetectArray');
    my $body = $self->_array_of_string_body($texts);
    $self->_post_and_parse($api_url, $body, ForceArray => 'string');
}

sub _array_of_string_body {
    my ($self, $strings) = @_;
    my $body = +{
        ArrayOfstring => [+{
            xmlns     => 'http://schemas.microsoft.com/2003/10/Serialization/Arrays',
            'xmlns:i' => 'http://www.w3.org/2001/XMLSchema-instance',
            string    => [ map { +{ content => $_, } } @$strings ],
        }],
    };
    return $self->xml->XMLout($body, RootName => undef);
}

sub get_language_names {
    my ($self, %args) = @_;
    my $locale = $args{locale};
    my $language_codes = $args{languageCodes};

    if (!$locale || !$language_codes) {
        Carp::croak('locale and languageCodes are required');
    }
    if (ref $language_codes ne 'ARRAY') {
        Carp::croak('languageCodes parameter is expecting a ARRAYREF');
    }

    my $api_url = $self->_api_url('GetLanguageNames');
    $api_url->query_param(locale => $locale);

    my $body = $self->_array_of_string_body($language_codes);
    $self->_post_and_parse($api_url, $body, ForceArray => 'string');
}

sub get_languages_for_translate {
    my $self = shift;
    my $api_url = $self->_api_url('GetLanguagesForTranslate');
    $self->_get_and_parse($api_url, ForceArray => ['string']);
}

sub get_translations {
    my ($self, %args) = @_;
    my $text = $args{text};
    my $from = $args{from};
    my $to = $args{to};
    my $max_translations = $args{maxTranslations};
    my $options = $args{options};

    if (!defined $text || !$from || !$to || !defined $max_translations) {
        Carp::croak('text, from, to and maxTranslations are required');
    }
    if ($options && ref $options ne 'HASH') {
        Carp::croak('options parameter is expecting a HASHREF');
    }

    my $api_url = $self->_api_url('GetTranslations');
    $api_url->query_param(text => $text);
    $api_url->query_param(from => $from);
    $api_url->query_param(to => $to);
    $api_url->query_param(maxTranslations => $max_translations);

    my $body = $options ? $self->_get_translations_body_options($options) : '';
    $self->_post_and_parse($api_url, $body);
}

sub _get_translations_body_options {
    my ($self, $options) = @_;

    my %op = (ReservedFlags => [ +{ '-' => '', } ]);
    for my $key (qw(Category ContentType Url User State)) {
        if (exists $options->{$key}) {
            $op{$key} = [ +{ content => $options->{$key}} ];
        } else {
            $op{$key} = [ +{ '-' => '', } ];
        }
    }
    my $body = +{
        TranslateOptions => [+{
            xmlns => 'http://schemas.datacontract.org/2004/07/Microsoft.MT.Web.Service.V2',
            %op,
        }],
    };
    return $self->xml->XMLout($body, RootName => undef);
}

sub get_translations_array {
    my ($self, %args) = @_;

    if (!$args{texts} || !$args{from} || !$args{to} || !exists $args{maxTranslations}) {
        Carp::croak('texts, from, to and maxTranslations are required');
    }
    if (ref $args{texts} ne 'ARRAY') {
        Carp::croak('texts parameter is expecting a ARRAYREF');
    }
    if ($args{options} && ref $args{options} ne 'HASH') {
        Carp::croak('options parameter is expecting a HASHREF');
    }

    my $api_url = $self->_api_url('GetTranslationsArray');
    my $body = $self->_get_translations_array_body(%args);
    $self->_post_and_parse($api_url, $body, ForceArray => ['Translations']);
}

sub _get_translations_array_body {
    my ($self, %args) = @_;

    my $body = +{
        AppId           => [ +{ '-' => '', } ],
        To              => [ +{ content => $args{to}, } ],
        maxTranslations => [ +{ content => $args{maxTranslations}, } ],
        Texts           => $self->_array_body_texts($args{texts}),
        From            => $self->_array_body_from($args{from}),
        Options         => $self->_array_body_options($args{options}),
    };
    my $xml = $self->xml->XMLout($body, RootName => 'GetTranslationsArrayRequest');
    $xml =~ s!<maxTranslations>([0-9]+)</maxTranslations>!<MaxTranslations>$1</MaxTranslations>!;
    return $xml;
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
    $self->_get_and_parse($api_url);
}

sub translate_array {
    my ($self, %args) = @_;

    if (!$args{texts} || !$args{to}) {
        Carp::croak('texts and to are required');
    }
    if (ref $args{texts} ne 'ARRAY') {
        Carp::croak('texts parameter is expecting a ARRAYREF');
    }
    if ($args{options} && ref $args{options} ne 'HASH') {
        Carp::croak('options parameter is expecting a HASHREF');
    }

    my $api_url = $self->_api_url('TranslateArray');
    my $body = $self->_translate_array_body(%args);
    $self->_post_and_parse($api_url, $body, ForceArray => ['TranslateArrayResponse']);
}

sub _translate_array_body {
    my ($self, %args) = @_;

    my $body = +{
        AppId   => [ +{ '-' => '', } ],
        To      => [ +{ content => $args{to}, } ],
        Texts   => $self->_array_body_texts($args{texts}),
        From    => $self->_array_body_from($args{from}),
        Options => $self->_array_body_options($args{options}),
    };
    return $self->xml->XMLout($body, RootName => 'TranslateArrayRequest');
}

sub _array_body_from {
    my ($self, $from) = @_;

    return [ +{ content => $from, } ] if defined $from;
    return [ +{ '-' => '', } ];
}

sub _array_body_texts {
    my ($self, $texts) = @_;
    my $xmlns = 'http://schemas.microsoft.com/2003/10/Serialization/Arrays';

    my @list = map { +{ xmlns => $xmlns, content => $_, } } @$texts;
    return +{ string => \@list };
}

sub _array_body_options {
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
    my ($self, $url) = @_;

    my $response = $self->{response} = $self->ua->get($url, Authorization => $self->_authorization);
    if (!$response->is_success) {
        Carp::croak("request to $url failed.");
    }
    return $response;
}

sub _get_and_parse {
    my ($self, $url, %opt) = @_;
    my $response = $self->_get($url, %opt);
    return $self->xml->XMLin($response->content, %opt);
}

sub _post {
    my ($self, $url, $body) = @_;

    my $response = $self->{response} = $self->ua->post(
        $url,
        content_type  => 'text/xml',
        Authorization => $self->_authorization,
        Content       => $body
    );
    if (!$response->is_success) {
        print $response->status_line, "\n";
        Carp::croak("request to $url failed.");
    }
    return $response;
}

sub _post_and_parse {
    my ($self, $url, $body, %opt) = @_;
    my $response = $self->_post($url, $body);
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
