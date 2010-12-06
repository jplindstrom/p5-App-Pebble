
=head1 NAME

App::Pebble::Render - Base class for Pebble renderers

=cut

package App::Pebble::Render;
use Moose;
use App::Pebble::Render::CSV;
use App::Pebble::Render::table;

sub needs_pool { 0 }

#TODO: plugin system, not hard coded
sub CSV {
    my $class = shift;
    App::Pebble::Render::CSV->render( @_ );
}

sub table {
    my $class = shift;
    App::Pebble::Render::table->render( @_ );
}


1;
