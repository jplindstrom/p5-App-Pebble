
=head1 NAME

App::Pebble::Render::Graph - Collection of Graph plugins

=cut

package App::Pebble::Render::Graph;
use Moose;
use Method::Signatures;

use App::Pebble::Render::Graph::Basic;

#TODO: plugin system, not hard coded
sub Basic {
    my $class = shift;
    App::Pebble::Render::Graph::Basic->render( @_ );
}

1;
