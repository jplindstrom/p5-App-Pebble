
=head1 NAME

App::Pebble::Command::df - Command to run "df"

=cut

package App::Pebble::Command::df;
use Moose;
extends "App::Pebble::Command";

use Method::Signatures;

use App::Pebble::Plugin::Parser::Regex;

sub name    { "df" }
sub command { "df" }

method parse($class: $args?) {
    return App::Pebble::Plugin::Parser::Regex->match(
        regex =>  qr/ (.+?) \s+  (\d+) \s+ (\d+) \s+ (\d+) \s+ (\d+)% \s+ (.+)      $/x,
        has   => [qw/ filesystem blocks    used      available capacity   mounted_on /]
    );
}

1;
