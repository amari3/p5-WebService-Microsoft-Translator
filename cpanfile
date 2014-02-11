requires 'Carp';
requires 'LWP::UserAgent';
requires 'URI';
requires 'URI::QueryParam';
requires 'XML::Simple';
requires 'JSON';

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.36';
    requires 'Test::More';
};
