use inc::Module::Install;

name     'App-Pebble';
all_from 'lib/App/Pebble.pm';
author   q{Johan Lindstrom <johanl@cpan.org>};
license  'perl';

build_requires 'Test::More';

requires 'File::HomeDir' => 0.93;

auto_install;

WriteAll;

