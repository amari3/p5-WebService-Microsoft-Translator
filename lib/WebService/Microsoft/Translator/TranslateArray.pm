package WebService::Microsoft::Translator::TranslateArray;
use strict;
use warnings;
use Carp;
use XML::Simple;

sub new {
    my ($class, $result) = @_;

    if (!defined $result) {
        Carp::croak('result is required');
    }

    my $data = XMLin($result);
    my @texts = map { $_->{TranslatedText} } @{$data->{TranslateArrayResponse}};
    return bless +{ texts => \@texts, }, $class;
}

sub texts {
    my $texts = shift->{texts};
    return wantarray ? @$texts: $texts;
}

1;
