#!/usr/bin/env perl
# -*- mode: cperl; cperl-indent-level: 4; -*-

use strict;
use warnings;

use Getopt::Long;
use IO::Pipeline;

use Data::Dumper;

use lib "lib";
use App::Pebble::IO::ObjectArray;
use aliased "App::Pebble::Object" => "P";
use aliased "App::Pebble::Render" => "R";

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
        "out:s"          => \( my $output_renderer ),
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

    my $output_sink = q{\*STDOUT};
    if( $output_renderer ) {
        $output_sink = $output_renderer;
    }
    else {
        $default_post ||= 'pmap { "$_\n" }';
    }

    my $parser_stage;
    $parser and $parser_stage ||= "$parser->parser";

    my ($user_stage) = @ARGV;
    $user_stage ||= 'pmap { $_ }';
    my @pipes = grep { $_ } (
        $input_source,
        $default_pre,
        $parser_stage,
        $user_stage,
        'p { $_ }',  # in case the $user_stage ends with a file handle
        $default_post,
        $output_sink,
    );

    my $pipeline_perl = join( " |\n", @pipes );
    print "((($pipeline_perl)))\n";
    eval $pipeline_perl;
    $@ and die;
}


# Dec 02 02:48:35  [68] kCGErrorIllegalArgument: CGXSetWindowFilter: Invalid filter 2
