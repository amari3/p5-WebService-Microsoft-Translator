use inc::Module::Install;
name 'WebService-Microsoft-Translator';
all_from 'lib/WebService/Microsoft/Translator.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
