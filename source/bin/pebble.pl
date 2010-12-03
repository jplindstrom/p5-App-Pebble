#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use IO::Pipeline;

use lib "lib";
use aliased "App::Pebble::Object" => "P";


#TODO: plugin system
use aliased "App::Pebble::Command::df" => "df";

no warnings "once";
*p = *pmap;

main();

sub main {
    GetOptions(
        "default_pre:s"  => \( my $default_pre = 'pmap { chomp; $_ }' ),
        "default_post:s" => \( my $default_post = 'pmap { "$_\n" }' ),
        "parser:s"       => \( my $parser ),
    );

    my $parser_perl;
    $parser and $parser_perl = "$parser->parser";

    my ($perl) = @ARGV;
    $perl ||= 'pmap { $_ }';
    my @pipes = grep { $_ } ( q{\*STDIN}, $default_pre, $parser_perl, $perl, $default_post, q{\*STDOUT} );

    eval join( " | ", @pipes );
    $@ and die;
}


# Dec 02 02:48:35  [68] kCGErrorIllegalArgument: CGXSetWindowFilter: Invalid filter 2
