
=head1 NAME

App::Pebble::Plugin::Render::table - Render output as pretty table.

=cut

package App::Pebble::Plugin::Render::table;
use Moose;
extends "App::Pebble::Render";

use Method::Signatures;

use Data::Format::Pretty::Console qw(format_pretty);
use IO::Pipeline;

method needs_pool { 1 }

method render($class: $args?) {
    my @items;
    return ppool(
      sub { push( @items, $_ ); () },
      sub {
        @items or return "";
        format_pretty([
            map { $_->as_hashref }
            map {
                blessed $_ && $_->can( "as_hashref" )
                        or die( "Stream value ($_) isn't an object, so it can't be rendered with 'table'\n" );
                $_
            }
            @items
        ]);
      },
    );
}

1;
