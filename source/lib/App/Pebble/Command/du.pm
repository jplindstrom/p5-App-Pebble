
=head1 NAME

App::Pebble::Command::df - Command to run "du -sk" something

=cut

package App::Pebble::Command::du;
use Moose;
extends "App::Pebble::Command";

use Method::Signatures;

use App::Pebble::Parse;

sub name    { "du" }
sub command { "du -sk" }

method parser($class: $args?) {
    return App::Pebble::Parse->match(
        regex => qr/(\S+) \s+ (\S+)/x,
        has   => [  "size",   "file" ],
    );
}

1;
