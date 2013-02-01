package WebService::Microsoft::Translator::Translate;
use strict;
use warnings;
use Carp;
use XML::Simple;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors(qw(
    text
));

sub new {
    my ($class, $result) = @_;

    if (!defined $result) {
        Carp::croak('result is required');
    }

    my $data = XMLin($result);
    return $class->SUPER::new(+{
        text => $data->{content},
    });
}

1;
