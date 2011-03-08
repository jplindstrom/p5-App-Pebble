# -*- mode: cperl; cperl-indent-level: 4; -*-

=head1 NAME

App::Pebble::Plugin::Render::table - Render output as pretty table.

=cut

package App::Pebble::Plugin::Renderer::table;
use Moose;

use Method::Signatures;

use Data::Format::Pretty::Console 0.06 qw(format_pretty);
use IO::Pipeline;
use Data::Dumper;

method needs_pool { 1 }

method render($class: :$interactive = 1) {
    my @items;
    return ppool(
      sub { push( @items, $_ ); () },
      sub {
        @items or return "";
        format_pretty(
            [
                map { $_->as_hashref }
                map {
                    blessed $_ && $_->can( "as_hashref" )
                            or die( "Stream value ($_) isn't a Pebble object, so it can't be rendered with 'table'. Value:\n" . Dumper( $_ ) );
                    $_
                }
                @items
            ],
            { interactive => $interactive },
        );
      },
    );
}

1;
