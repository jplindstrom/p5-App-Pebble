
=head1 NAME

App::Pebble::Source - Accessor class for Pebble Sources.

=cut

package App::Pebble::Source;
use Moose;
use MooseX::Method::Signatures;

###TODO: plugin system
use App::Pebble::Source::Web;

sub Web { "App::Pebble::Source::Web" }

1;

  #  <a href="/title/(\w+)/"
