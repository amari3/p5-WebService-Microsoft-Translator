package WebService::Microsoft::Translator::GetLanguagesForTranslate;
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
    return bless +{ codes => $data->{string}, }, $class;
}

sub codes {
    my $codes = shift->{codes};
    return wantarray ? @$codes : $codes;
}

1;
