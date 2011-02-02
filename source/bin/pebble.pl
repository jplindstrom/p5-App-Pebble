#!/usr/bin/env perl
# -*- mode: cperl; cperl-indent-level: 4; -*-

use strict;
use warnings;

use Getopt::Long;
use Data::Dumper;
use File::HomeDir;
use Path::Class;
use Cache::FileCache;
use Cache::NullCache;
use File::Slurp qw/ read_file /;

use lib ("lib", "../../p5-Pebble-Object/source/lib");
use App::Pebble;
use App::Pebble::Log qw/ $log /;

#TODO: plugin system
use App::Pebble::Command::df;
use App::Pebble::Command::du;

eval {
    main();
};
if( my $err = $@ ) {
    chomp( $err );
    $log->error( $err );
}

sub main {
    GetOptions(
        "default_pre:s"      => \( my $default_pre = 'pmap { chomp; $_ }' ),
        "default_post:s"     => \( my $default_post ),  # 'pmap { "$_\n" }' ),
        "parser:s"           => \( my $parser ),
        "out:s"              => \( my $output_renderer ),
        "cmd:s"              => \( my $cmd ),
        "web_cache:s"        => \( my $web_cache = Cache::NullCache->new() ),
        "script"             => \( my $script ),
        "verbose:i"          => \( my $verbose = 2 ), # warning and higher
        "log_file:s"         => \( my $log_file ),
        "info"               => \( my $info ),
    );
    $info and info(), exit(0);

    ###TODO: move into init
    $log_file ||= do {
        my $log_dir = File::HomeDir->my_dist_data(
            'App-Pebble/log',
            { create => 1 }
        );        
        file( $log_dir, "pebble.log" ) . "";
    };
    my $file_log_level = $ENV{PEBBLE_LOG_LEVEL};
    defined $file_log_level or $file_log_level = 1; # info and higher
    my $screen_log_level = 5 - $verbose;
    App::Pebble::Log->init(
        file         => $log_file,
        file_level   => $file_log_level,
        screen_level => $screen_log_level,
    );
    $verbose < 0 || $verbose > 5 and die( "--verbose must be 0..4\n" );
    
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
        $output_renderer = "R::$output_renderer->render";
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
                $user_stage =~ /[{(]|(->)/ or die( "This ($user_stage) isn't a file, and doesn't look like Pebble code.\n" );
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
        my $cache_dir = File::HomeDir->my_dist_data( 'App-Pebble/web', { create => 1 } );
        $log->info( "Cache dir ($cache_dir)" );
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

sub info {
    print "Pebble\n\n";

    my $dir = File::HomeDir->my_dist_data( "App-Pebble", { create => 1 } );
    print "App directory: $dir\n"
}

__END__

=head1 NAME

pebble

=head1 SYNOPSIS

  pebble
    [--nostdin]
    [--cmd=COMMAND_WITH_ARGS]
    [--out=RENDERER]
    [--verbose=1]
    [ PEBBLE_SOURCE_CODE PEBBLE_SOURCE_CODE ... ]
    [--web_cache [=flush] ]
    [--script [=NEW_SCRIPT_FILE] ]

=over 4

=item --nostdin

=item --cmd

=item --out

=item --verbose=2

  0 => nothing
  1 => error
  2 => warning (default)
  3 => notice
  4 => info
  5 => debug

=item PEBBLE_SOURCE_CODE

=item --web_cache

Use a file based cache for all web requests. If it's in the cache, don't touch the Net.

=item --web_cache=flush

Before using the cache, clear it.

=item --script

Don't run any Pebble source code, instead print all of it.

This is so that you can easily transfer ad-hoc scripting on the command line to a more reusable script.

Recommended file extension for Pebble scripts: .pbl
Make sure your editor syntax highlights this as Perl.

=back

=head1 DESCRIPTION
