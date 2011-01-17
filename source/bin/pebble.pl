#!/usr/bin/env perl
# -*- mode: cperl; cperl-indent-level: 4; -*-

use strict;
use warnings;

use Getopt::Long;
use Data::Dumper;
use File::HomeDir;
use Cache::FileCache;
use Cache::NullCache;
use File::Slurp qw/ read_file /;

use lib ("lib", "../../p5-Pebble-Object/source/lib");
use App::Pebble;

#TODO: plugin system
use App::Pebble::Command::df;
use App::Pebble::Command::du;

main();
sub main {
    GetOptions(
        "default_pre:s"  => \( my $default_pre = 'pmap { chomp; $_ }' ),
        "default_post:s" => \( my $default_post ),  # 'pmap { "$_\n" }' ),
        "parser:s"       => \( my $parser ),
        "out:s"          => \( my $output_renderer ),
        "cmd:s"          => \( my $cmd ),
        "web_cache:s"    => \( my $web_cache = Cache::NullCache->new() ),
        "script"         => \( my $script ),
    );

    my $input_source = q{\*STDIN};
    my $input_source_fh;
    if( $cmd && $cmd =~ /^(\S+)/ ) {
        my $command = $1; # First word of command
        $parser ||= "App::Pebble::Command::$command";
        my $command_class = "App::Pebble::Command::$command";
        $input_source_fh = $command_class->run( $cmd );

        $input_source = '$input_source_fh';
    };

    my $output_sink = q{\*STDOUT};
    if( $output_renderer ) {
        $output_renderer = "R::$output_renderer";
    }

    my $parser_stage;
    $parser and $parser_stage ||= "$parser->parser";

    my (@user_stages) = @ARGV;
    my $user_stage = join(
        "\n| ",
        map {
            my $user_stage = $_;

            # If file exists, load it
            if( -r $user_stage ) {
                $user_stage = read_file( $user_stage );
            }
            else {
                $user_stage =~ /[{(]/ or die( "This ($user_stage) isn't a file, and doesn't look like Pebble code.\n" );
            }

            # Remove comments
            $user_stage and $user_stage = join(
                "\n",
                grep { ! /^\s*#/  } split( /\n/, $user_stage )
            );
        }
        @user_stages
    );
    $user_stage ||= 'pmap { $_ }';

    if( $script ) {
        my $script_source = $user_stage;
        $script_source =~ s/ ([}\)]) [ ]* \| [ ]* (\w+) /$1\n| $2/smgx;
        print "$script_source\n";
        exit(0);
    }

    my $pebble = App::Pebble->new;

    if( defined $web_cache ) {
        my $cache_dir = File::HomeDir->my_dist_data( 'App-Pebble-web', { create => 1 } );
warn "Cache dir: ($cache_dir)\n";
        my $cache = App::Pebble->cache( Cache::FileCache->new({ cache_root => $cache_dir }) );
        $web_cache eq "flush" and $cache->clear();
    }

    $pebble->pipeline(
        [
            $input_source,
            $default_pre,
            $parser_stage,
            $user_stage,
            $output_renderer,
            $default_post,
            $output_sink,
        ],
        $input_source => $input_source_fh,
      );
}


# Dec 02 02:48:35  [68] kCGErrorIllegalArgument: CGXSetWindowFilter: Invalid filter 2
