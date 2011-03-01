# -*- mode: cperl; cperl-indent-level: 4; -*-

=head1 NAME

App::Pebble::Config - App::Pebble config

=cut

package App::Pebble::Config;
use Moose;
use MooseX::ClassAttribute;
use Method::Signatures;

use Config::Tiny;
use File::HomeDir;
use Path::Class qw//;

class_has file => ( is => "rw" );

my $instance;
method instance($class:) {
    $instance ||= Config::Tiny->read( $class->file ),
}

method user_config_file($class: $file?) {
    $file and return $file;
    Path::Class::file( File::HomeDir->my_home, ".pebble" );
}

1;
