
=head1 NAME

App::Pebble::Source - Accessor class for Pebble Sources.

=cut

package App::Pebble::Source;
use Moose;
use Method::Signatures;

###TODO: plugin system
use App::Pebble::Source::Web;
use App::Pebble::Source::XPath;
use App::Pebble::Source::DateTime;
use App::Pebble::Source::Duration;

sub Web { "App::Pebble::Source::Web" }
sub XPath { "App::Pebble::Source::XPath" }
sub DateTime { "App::Pebble::Source::DateTime" }
sub Duration { "App::Pebble::Source::Duration" }

1;
