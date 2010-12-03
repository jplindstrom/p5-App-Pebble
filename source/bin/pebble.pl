#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use IO::Pipeline;

use lib "lib";
use App::Pebble::Object;

no warnings "once";
*P = *App::Pebble::Object;
*p = *pmap;

main();

sub main {
    GetOptions(
        "default_pre:s"  => \( my $default_pre = 'pmap { chomp; $_ }' ),
        "default_post:s" => \( my $default_post = 'pmap { "$_\n" }' ),
    );

    my ($perl) = @ARGV;
    $perl ||= 'pmap { $_ }';
    my @pipes = grep { $_ } ( q{\*STDIN}, $default_pre, $perl, $default_post, q{\*STDOUT} );

    eval join( " | ", @pipes );
    $@ and die;
}


# Dec 02 02:48:35  [68] kCGErrorIllegalArgument: CGXSetWindowFilter: Invalid filter 2
