
=head1 NAME

App::Pebble::Render::table - Render output as pretty table.

=cut

package App::Pebble::Render::table;
use Moose;
extends "App::Pebble::Render";

use Data::Format::Pretty::Console qw(format_pretty);
use App::Pebble::IO::ObjectArray;

sub needs_pool { 1 }

sub stage {
    'R->table({ objects => $pool })';
}

sub render {
    my $class = shift;
    my ($args) = @_;
    my $objects = $args->{objects} || [];

    my @rows = split(
        /\n/,
        format_pretty([ map { $_->as_hashref } @$objects ])
    );

    return App::Pebble::IO::ObjectArray->new( \@rows );
}

1;
