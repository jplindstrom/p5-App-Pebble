
=head1 NAME

App::Pebble::Command::df - Command to run "df"

=cut

package App::Pebble::Command::df;
use Moose;
extends "App::Pebble::Command";

use Method::Signatures;

use App::Pebble::Parse;

sub name    { "df" }
sub command { "df" }

method parser($class: $args?) {
    return App::Pebble::Parse->match(
        regex =>  qr/ (.+?) \s+  (\d+) \s+ (\d+) \s+ (\d+) \s+ (\d+)% \s+ (.+)      $/x,
        has   => [qw/ filesystem blocks    used      available capacity   mounted_on /]
    );
}

1;
