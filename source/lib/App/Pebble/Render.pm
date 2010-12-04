
=head1 NAME

App::Pebble::Render - Base class for Pebble renderers

=cut

package App::Pebble::Render;
use Moose;
use App::Pebble::Render::CSV;

#TODO: plugin system, not hard coded
sub CSV {
    App::Pebble::Render::CSV->render( @_ );
}

1;
