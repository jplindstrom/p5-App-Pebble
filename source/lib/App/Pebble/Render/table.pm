
=head1 NAME

App::Pebble::Render::table - Render output as pretty table.

=cut

package App::Pebble::Render::table;
use Moose;
extends "App::Pebble::Render";

use Data::Format::Pretty::Console qw(format_pretty);
use IO::Pipeline;

sub needs_pool { 1 }

sub render {
    my $class = shift;
    my ($args) = @_;

    my @items;
    return ppool(
      sub { push( @items, $_ ); () },
      sub {
        format_pretty([ map { $_->as_hashref } @items ]);
      },
    );
}

1;
