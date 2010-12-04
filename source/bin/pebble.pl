#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use IO::Pipeline;

use lib "lib";
use aliased "App::Pebble::Object" => "P";


#TODO: plugin system
use aliased "App::Pebble::Command::df" => "df";
use aliased "App::Pebble::Command::du" => "du";

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
    if( $cmd && $cmd =~ /^(\S+)/ ) {
        my $command = $1; # First word of command
        $parser ||= $command;
        $input_source_fh = eval "$command->run( \$cmd );"; @$ and die; # eval bc of some strangeness with 'aliased'
        
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
