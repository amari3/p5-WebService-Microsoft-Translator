# NAME

WebService::Microsoft::Translator - A Perl interface to the Microsoft Translator API

# SYNOPSIS

    use WebService::Microsoft::Translator;

    my $w = WebService::Microsoft::Translator->new(
        client_id     => 'Your client ID',
        client_secret => 'Your client secret',
    );
    my $token = $w->request_access_token;
    my $translate = $w->translate(
        text => 'I like chocolate.',
        from => 'en',
        to   => 'ja',
    );

# DESCRIPTION

WebService::Microsoft::Translator is provides an interface to the Microsoft Translator API.

# REPOSITORY

https://github.com/amari3/p5-WebService-Microsoft-Translator

# AUTHOR

Ryoji Tanida <ryo2.amari3 at gmail.com>

# SEE ALSO

- Register windows live

    http://www.bing.com/developers/createapp.aspx

- Microsoft Translator Developer site

    http://www.microsofttranslator.com/dev/

- Bing Developer site

    http://www.bing.com/developers/

# LICENSE

Copyright (C) Ryoji Tanida

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
