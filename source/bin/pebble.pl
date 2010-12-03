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
        "cmd:s"          => \( my $cmd ),
    );

    my $input_source = q{\*STDIN};
    my $input_source_fh;
    if( $cmd ) {
        my $cmd_name = $cmd; #TODO: first segment of the full command
        $parser ||= $cmd_name;

        open( $input_source_fh, "-|", $cmd ) or die( "Could not read from command ($cmd)\n" );
        $input_source = '$input_source_fh';
    };

    my $parser_stage;
    $parser and $parser_stage ||= "$parser->parser";

    my ($user_stage) = @ARGV;
    $user_stage ||= 'pmap { $_ }';
    my @pipes = grep { $_ } (
        $input_source,
        $default_pre,
        $parser_stage,
        $user_stage,
        $default_post,
        q{\*STDOUT}
    );

    eval join( " |\n", @pipes );
    $@ and die;
}


# Dec 02 02:48:35  [68] kCGErrorIllegalArgument: CGXSetWindowFilter: Invalid filter 2
