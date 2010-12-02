#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::Pebble' ) || print "Bail out!
";
}

diag( "Testing App::Pebble $App::Pebble::VERSION, Perl $], $^X" );
