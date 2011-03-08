# -*- mode: cperl; cperl-indent-level: 4; -*-

=head1 NAME

App::Pebble::Plugin::Source::File - File contents source

=cut

package App::Pebble::Plugin::Source::File;
use Moose;
use Method::Signatures;

use File::Slurp;

method slurp($class: $file) {
    # todo: only slurp from file if $file is a File::Class
    return read_file( $file );
}

1;
