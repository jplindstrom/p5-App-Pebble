
=head1 NAME

App::Pebble::Command::df - Command to run "du -sk" something

=cut

package App::Pebble::Command::du;
use Moose;
extends "App::Pebble::Command";

use App::Pebble::Object;

sub name    { "du" }
sub command { "du -sk" }

sub parser {
    my $class = shift;
    my ($args) = @_;

    return App::Pebble::Object->match({
        regex => qr/(\S+) \s+ (\S+)/x,
        has   => [  "size",   "file" ],
    });
}

1;
