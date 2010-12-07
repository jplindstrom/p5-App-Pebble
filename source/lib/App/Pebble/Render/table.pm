
=head1 NAME

App::Pebble::Render::table - Render output as pretty table.

=cut

package App::Pebble::Render::table;
use Moose;
extends "App::Pebble::Render";

use MooseX::Method::Signatures;

use Data::Format::Pretty::Console qw(format_pretty);
use IO::Pipeline;

method needs_pool { 1 }

method render($class: $args?) {
    my @items;
    return ppool(
      sub { push( @items, $_ ); () },
      sub {
        @items or return "";
        format_pretty([ map { $_->as_hashref } @items ]);
      },
    );
}

1;
